import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/sales/data/models/pos_cart_item.dart';
import 'package:hisabet/features/sales/data/models/sale_line_item_model.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/transactions/data/repositories/contact_balance.dart';
import 'package:uuid/uuid.dart';

abstract class SalesRepository {
  Future<String> checkoutSale({
    required List<PosCartItem> cartItems,
    String? contactId,
    String? customerName,
    Decimal discount,
    Decimal tax,
    Decimal paidAmount,
    required String paymentMethod,
    String? note,
    String? promotionId,
    String? promotionCode,
  });

  Future<List<SaleModel>> getRecentSales({int limit = 30});
  Future<SaleModel?> getSaleById(String saleId);
  Future<List<SaleLineItemModel>> getSaleLineItems(String saleId);
  Future<void> updateSaleStatus(String saleId, String status);
}

class SalesRepositoryImpl implements SalesRepository {
  final AppDatabase _db;

  SalesRepositoryImpl(this._db);

  @override
  Future<String> checkoutSale({
    required List<PosCartItem> cartItems,
    String? contactId,
    String? customerName,
    Decimal? discount,
    Decimal? tax,
    Decimal? paidAmount,
    required String paymentMethod,
    String? note,
    String? promotionId,
    String? promotionCode,
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

    // One atomic unit: a failure anywhere (e.g. insufficient stock on the
    // third item) rolls back the sale row, every stock write, the promotion
    // redemption and the ledger entry together. Without this, a partial
    // checkout left stock deducted for some items and a sale that never
    // completed.
    await _db.transaction(() async {
      // Read each product once, inside the transaction, and use that same
      // row both to validate and to compute the new stock. The cart holds a
      // snapshot taken when the item was added, which can be stale.
      final freshProducts = <String, Product>{};
      for (final item in cartItems) {
        final product = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(item.product.id)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('Product not found: ${item.product.name}');
        }
        if (product.stockQuantity < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.product.name}. '
            'Available: ${product.stockQuantity}',
          );
        }
        freshProducts[product.id] = product;
      }

      await _db.into(_db.sales).insert(
            SalesCompanion.insert(
              id: saleId,
              contactId: Value(contactId),
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

      if (promotionId != null && discountValue > Decimal.zero) {
        await _db.into(_db.promotionRedemptions).insert(
              PromotionRedemptionsCompanion.insert(
                id: const Uuid().v4(),
                promotionId: promotionId,
                saleId: saleId,
                codeSnapshot: promotionCode ?? '',
                discountApplied: discountValue.toString(),
                subtotal: subtotal.toString(),
                createdAt: now,
              ),
            );

        // Increment in SQL rather than read-modify-write.
        await (_db.update(_db.promotions)
              ..where((tbl) => tbl.id.equals(promotionId)))
            .write(
          PromotionsCompanion.custom(
            usedCount: _db.promotions.usedCount + const Constant(1),
            updatedAt: Variable(now),
          ),
        );
      }

      for (final item in cartItems) {
        final product = freshProducts[item.product.id]!;

        await _db.into(_db.saleLineItems).insert(
              SaleLineItemsCompanion.insert(
                id: const Uuid().v4(),
                saleId: saleId,
                productId: item.product.id,
                productName: item.product.name,
                sku: Value(item.product.sku),
                unit: Value(item.product.unit),
                itemsPerCarton: Value(item.product.itemsPerCarton),
                unitPrice: item.product.sellingPrice.toString(),
                quantity: item.quantity,
                lineTotal: item.lineTotal.toString(),
              ),
            );

        await (_db.update(_db.products)
              ..where((tbl) => tbl.id.equals(product.id)))
            .write(
          ProductsCompanion(
            stockQuantity: Value(product.stockQuantity - item.quantity),
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

      // A credit sale to a known contact becomes a ledger entry.
      final amountOwed = total - paidAmountValue;
      if (contactId != null && amountOwed > Decimal.zero) {
        final snapshotMetadata = {
          'source': 'pos_sale',
          'product_snapshots': cartItems
              .map((item) => {
                    'name': item.product.name,
                    'itemNumber': item.product.itemNumber,
                    'photoUrl': item.product.photoUrl,
                    'cartons': item.quantity,
                    'seriesSize': item.product.seriesSize,
                    'colorDistribution': item.product.colorDistribution,
                    'costPrice': item.product.sellingPrice.toString(),
                  })
              .toList(),
        };

        await _db.into(_db.transactions).insert(
              TransactionsCompanion.insert(
                id: const Uuid().v4(),
                contactId: contactId,
                type: 0, // goodsGiven (they owe me)
                status: const Value(1), // confirmed
                amount: amountOwed.toString(),
                date: now,
                description: Value('Unpaid balance from POS Sale #$saleId'),
                saleId: Value(saleId),
                metadata: Value(jsonEncode(snapshotMetadata)),
              ),
            );

        // Same full recalculation the ledger uses, so the two can't drift.
        await recalculateContactBalance(_db, contactId);
      }
    });

    return saleId;
  }

  @override
  Future<List<SaleModel>> getRecentSales({int limit = 30}) async {
    final rows =
        await (_db.select(_db.sales)
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
              ..limit(limit))
            .get();

    return rows.map(SaleModel.fromDb).toList();
  }

  @override
  Future<SaleModel?> getSaleById(String saleId) async {
    final row = await (_db.select(
      _db.sales,
    )..where((tbl) => tbl.id.equals(saleId))).getSingleOrNull();
    return row == null ? null : SaleModel.fromDb(row);
  }

  @override
  Future<List<SaleLineItemModel>> getSaleLineItems(String saleId) async {
    final rows =
        await (_db.select(_db.saleLineItems)
              ..where((tbl) => tbl.saleId.equals(saleId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.productName)]))
            .get();
    return rows.map(SaleLineItemModel.fromDb).toList();
  }

  @override
  Future<void> updateSaleStatus(String saleId, String status) async {
    await (_db.update(_db.sales)..where((tbl) => tbl.id.equals(saleId))).write(
      SalesCompanion(status: Value(status)),
    );
  }
}
