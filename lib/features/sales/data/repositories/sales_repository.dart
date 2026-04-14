import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/sales/data/models/pos_cart_item.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:uuid/uuid.dart';

abstract class SalesRepository {
  Future<void> checkoutSale({
    required List<PosCartItem> cartItems,
    String? customerName,
    Decimal discount,
    Decimal tax,
    Decimal paidAmount,
    required String paymentMethod,
    String? note,
  });

  Future<List<SaleModel>> getRecentSales({int limit = 30});
}

class SalesRepositoryImpl implements SalesRepository {
  final AppDatabase _db;

  SalesRepositoryImpl(this._db);

  @override
  Future<void> checkoutSale({
    required List<PosCartItem> cartItems,
    String? customerName,
    Decimal? discount,
    Decimal? tax,
    Decimal? paidAmount,
    required String paymentMethod,
    String? note,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final discountValue = discount ?? Decimal.zero;
    final taxValue = tax ?? Decimal.zero;
    final paidAmountValue = paidAmount ?? Decimal.zero;

    final subtotal = cartItems
        .map((item) => item.lineTotal)
        .fold(Decimal.zero, (sum, value) => sum + value);
    final total = subtotal - discountValue + taxValue;

    if (total < Decimal.zero) {
      throw Exception('Total cannot be negative.');
    }

    final now = DateTime.now();
    final saleId = const Uuid().v4();

    await _db.transaction(() async {
      for (final item in cartItems) {
        final product = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(item.product.id)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('Product not found: ${item.product.name}');
        }

        if (product.stockQuantity < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.product.name}. Available: ${product.stockQuantity}',
          );
        }
      }

      await _db.into(_db.sales).insert(
            SalesCompanion.insert(
              id: saleId,
              customerName: Value(customerName),
              subtotal: subtotal.toString(),
              discount: Value(discountValue.toString()),
              tax: Value(taxValue.toString()),
              total: total.toString(),
              paidAmount: Value(paidAmountValue.toString()),
              paymentMethod: Value(paymentMethod),
              note: Value(note),
              createdAt: now,
            ),
          );

      for (final item in cartItems) {
        final lineItemId = const Uuid().v4();

        await _db.into(_db.saleLineItems).insert(
              SaleLineItemsCompanion.insert(
                id: lineItemId,
                saleId: saleId,
                productId: item.product.id,
                productName: item.product.name,
                sku: Value(item.product.sku),
                unitPrice: item.product.sellingPrice.toString(),
                quantity: item.quantity,
                lineTotal: item.lineTotal.toString(),
              ),
            );

        final updatedStock = item.product.stockQuantity - item.quantity;

        await (_db.update(_db.products)
              ..where((tbl) => tbl.id.equals(item.product.id)))
            .write(
          ProductsCompanion(
            stockQuantity: Value(updatedStock),
            updatedAt: Value(now),
          ),
        );

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: const Uuid().v4(),
                productId: item.product.id,
                movementType: 'sale',
                quantityChange: -item.quantity,
                note: Value('Sale #$saleId'),
                createdAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<List<SaleModel>> getRecentSales({int limit = 30}) async {
    final rows = await (_db.select(_db.sales)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit))
        .get();

    return rows.map(SaleModel.fromDb).toList();
  }
}
