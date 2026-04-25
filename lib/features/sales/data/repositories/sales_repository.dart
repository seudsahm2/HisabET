import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/sales/data/models/pos_cart_item.dart';
import 'package:hisabet/features/sales/data/models/sale_line_item_model.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
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
    debugPrint('CHECKOUT TRACE [Repo]: Inside checkoutSale. Generating IDs...');
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

    debugPrint('CHECKOUT TRACE [Repo]: Starting database transaction...');
    try {
      debugPrint('CHECKOUT TRACE [Repo]: Transaction started. Inserting Sale record...');
      for (final item in cartItems) {
        final product = await (_db.select(
          _db.products,
        )..where((tbl) => tbl.id.equals(item.product.id))).getSingleOrNull();

        if (product == null) {
          throw Exception('Product not found: ${item.product.name}');
        }

        if (product.stockQuantity < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.product.name}. Available: ${product.stockQuantity}',
          );
        }
      }

      await _db
          .into(_db.sales)
          .insert(
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
        await _db
            .into(_db.promotionRedemptions)
            .insert(
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

        final promoRow = await (_db.select(
          _db.promotions,
        )..where((tbl) => tbl.id.equals(promotionId))).getSingleOrNull();
        if (promoRow != null) {
          await (_db.update(
            _db.promotions,
          )..where((tbl) => tbl.id.equals(promotionId))).write(
            PromotionsCompanion(
              usedCount: Value(promoRow.usedCount + 1),
              updatedAt: Value(now),
            ),
          );
        }
      }

      debugPrint('CHECKOUT TRACE [Repo]: Processing ${cartItems.length} items...');
      for (final item in cartItems) {
        debugPrint('CHECKOUT TRACE [Repo]: Inserting item ${item.product.name}...');
        final lineItemId = const Uuid().v4();

        await _db
            .into(_db.saleLineItems)
            .insert(
              SaleLineItemsCompanion.insert(
                id: lineItemId,
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

        debugPrint('CHECKOUT TRACE [Repo]: Updating stock for ${item.product.name}...');
        final updatedStock = item.product.stockQuantity - item.quantity;

        await (_db.update(
          _db.products,
        )..where((tbl) => tbl.id.equals(item.product.id))).write(
          ProductsCompanion(
            stockQuantity: Value(updatedStock),
            updatedAt: Value(now),
          ),
        );

        debugPrint('CHECKOUT TRACE [Repo]: Inserting stock movement for ${item.product.name}...');
        await _db
            .into(_db.stockMovements)
            .insert(
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

      // If this sale is linked to a contact and is partially paid (credit), record a Transaction
      if (contactId != null) {
        final amountOwed = total - paidAmountValue;

        if (amountOwed > Decimal.zero) {
          final transactionId = const Uuid().v4();

          await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: transactionId,
              contactId: contactId,
              type: 0, // goodsGiven (They owe me)
              status: const Value(1), // confirmed
              amount: amountOwed.toString(),
              date: now,
              description: Value('Unpaid balance from POS Sale #$saleId'),
              saleId: Value(saleId),
            ),
          );

          // Update the contact's netBalance
          final contactRow = await (_db.select(_db.contacts)..where((tbl) => tbl.id.equals(contactId))).getSingleOrNull();
          if (contactRow != null) {
            final currentBalance = Decimal.tryParse(contactRow.netBalance) ?? Decimal.zero;
            final newBalance = currentBalance + amountOwed;

            await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(contactId))).write(
              ContactsCompanion(
                netBalance: Value(newBalance.toString()),
              ),
            );
          }
        }
      }
      debugPrint('CHECKOUT TRACE [Repo]: Transaction block finished.');
    } catch (e) {
      debugPrint('CHECKOUT TRACE [Repo]: Error during checkout execution: $e');
      rethrow;
    }

    debugPrint('CHECKOUT TRACE [Repo]: checkoutSale successfully finished.');
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
