import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_line_item_model.dart';
import 'package:uuid/uuid.dart';

abstract class PurchaseOrdersRepository {
  Future<List<PurchaseOrderModel>> getAllPurchaseOrders();
  Future<PurchaseOrderModel?> getPurchaseOrderById(String id);
  Future<List<PurchaseOrderLineItemModel>> getPurchaseOrderLineItems(String purchaseOrderId);
  Future<void> addPurchaseOrder({
    required String supplierId,
    required DateTime orderDate,
    DateTime? dueDate,
    Decimal? subtotal,
    String? notes,
    List<PurchaseOrderLineInput> lineItems = const [],
    PurchaseOrderStatus status = PurchaseOrderStatus.draft,
  });
  Future<void> updatePurchaseOrder(
    PurchaseOrderModel order, {
    List<PurchaseOrderLineInput> lineItems = const [],
  });
  Future<void> deletePurchaseOrder(String id);
  Future<void> updatePurchaseOrderStatus(String id, PurchaseOrderStatus status);
}

class PurchaseOrdersRepositoryImpl implements PurchaseOrdersRepository {
  final AppDatabase _db;

  PurchaseOrdersRepositoryImpl(this._db);

  @override
  Future<List<PurchaseOrderModel>> getAllPurchaseOrders() async {
    final rows = await (_db.select(_db.purchaseOrders)
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)])).get();
    return rows.map(PurchaseOrderModel.fromDb).toList();
  }

  @override
  Future<PurchaseOrderModel?> getPurchaseOrderById(String id) async {
    final row = await (_db.select(_db.purchaseOrders)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : PurchaseOrderModel.fromDb(row);
  }

  @override
  Future<List<PurchaseOrderLineItemModel>> getPurchaseOrderLineItems(String purchaseOrderId) async {
    final rows = await (_db.select(_db.purchaseOrderLineItems)
          ..where((tbl) => tbl.purchaseOrderId.equals(purchaseOrderId))
          ..orderBy([(t) => OrderingTerm.asc(t.productName)]))
        .get();
    return rows.map(PurchaseOrderLineItemModel.fromDb).toList();
  }

  @override
  Future<void> addPurchaseOrder({
    required String supplierId,
    required DateTime orderDate,
    DateTime? dueDate,
    Decimal? subtotal,
    String? notes,
    List<PurchaseOrderLineInput> lineItems = const [],
    PurchaseOrderStatus status = PurchaseOrderStatus.draft,
  }) async {
    final subtotalValue = subtotal ??
        lineItems.fold<Decimal>(Decimal.zero, (sum, item) => sum + item.lineTotal);
    final now = DateTime.now();
    final orderId = const Uuid().v4();
    final order = PurchaseOrderModel(
      id: orderId,
      supplierId: supplierId,
      status: status,
      subtotal: subtotalValue,
      orderDate: orderDate,
      dueDate: dueDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.purchaseOrders).insert(order.toDbCompanion());
      await _replaceLineItems(orderId, lineItems);
      if (status == PurchaseOrderStatus.received) {
        await _postReceivedStock(orderId, lineItems);
      }
    });
  }

  @override
  Future<void> updatePurchaseOrder(
    PurchaseOrderModel order, {
    List<PurchaseOrderLineInput> lineItems = const [],
  }) async {
    final updated = order.copyWith(updatedAt: DateTime.now());
    await _db.transaction(() async {
      await (_db.update(_db.purchaseOrders)..where((tbl) => tbl.id.equals(order.id)))
          .write(updated.toDbCompanion());
      await _replaceLineItems(order.id, lineItems);
    });
  }

  @override
  Future<void> deletePurchaseOrder(String id) async {
    await (_db.delete(_db.purchaseOrders)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updatePurchaseOrderStatus(String id, PurchaseOrderStatus status) async {
    await _db.transaction(() async {
      final current = await (_db.select(_db.purchaseOrders)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (current == null) return;

      await (_db.update(_db.purchaseOrders)..where((tbl) => tbl.id.equals(id))).write(
        PurchaseOrdersCompanion(
          status: Value(status.index),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (status == PurchaseOrderStatus.received &&
          current.status != PurchaseOrderStatus.received.index) {
        final lineItems = await getPurchaseOrderLineItems(id);
        await _postReceivedStock(id, lineItems.map((item) => PurchaseOrderLineInput(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          unit: item.unit,
          itemsPerCarton: item.itemsPerCarton,
          unitCost: item.unitCost,
          quantity: item.quantity,
          lineTotal: item.lineTotal,
        )).toList());
      }
    });
  }

  Future<void> _replaceLineItems(String purchaseOrderId, List<PurchaseOrderLineInput> lineItems) async {
    await (_db.delete(_db.purchaseOrderLineItems)
          ..where((tbl) => tbl.purchaseOrderId.equals(purchaseOrderId)))
        .go();

    for (final item in lineItems) {
      await _db.into(_db.purchaseOrderLineItems).insert(
            item.toModel(purchaseOrderId: purchaseOrderId).toDbCompanion(),
          );
    }
  }

  Future<void> _postReceivedStock(String purchaseOrderId, List<PurchaseOrderLineInput> lineItems) async {
    final now = DateTime.now();

    for (final item in lineItems) {
      final product = await (_db.select(_db.products)
            ..where((tbl) => tbl.id.equals(item.productId)))
          .getSingleOrNull();

      if (product == null) continue;

      final updatedStock = product.stockQuantity + item.quantity;

      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(item.productId))).write(
        ProductsCompanion(
          stockQuantity: Value(updatedStock),
          updatedAt: Value(now),
        ),
      );

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: const Uuid().v4(),
              productId: item.productId,
              movementType: 'purchase_received',
              quantityChange: item.quantity,
              note: Value('Purchase Order #$purchaseOrderId'),
              createdAt: now,
            ),
          );
    }
  }
}