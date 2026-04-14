import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/sync/data/services/transaction_sync_service.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

abstract class TransactionsRepository {
  Future<List<TransactionModel>> getTransactionsForContact(String contactId);
  Future<void> addTransaction({
    required String contactId,
    required TransactionType type,
    required Decimal amount,
    required DateTime date,
    String? description,
    Map<String, dynamic>? metadata,
    String? referenceId,
  });
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> updateTransactionStatus(String id, TransactionStatus status);
  Future<void> deleteTransaction(String id);
  Future<Decimal> calculateNetBalance(String contactId);
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10});
  Stream<List<TransactionModel>> watchTransactionsForContact(String contactId);
}

class TransactionsRepositoryImpl implements TransactionsRepository {
  final AppDatabase _db;
  final TransactionSyncService _syncService;

  TransactionsRepositoryImpl(this._db, this._syncService);

  @override
  Future<List<TransactionModel>> getTransactionsForContact(
    String contactId,
  ) async {
    final rows =
        await (_db.select(_db.transactions)
              ..where((tbl) => tbl.contactId.equals(contactId))
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map((e) => TransactionModel.fromDb(e)).toList();
  }

  @override
  Future<void> addTransaction({
    required String contactId,
    required TransactionType type,
    required Decimal amount,
    required DateTime date,
    String? description,
    Map<String, dynamic>? metadata,
    String? referenceId,
  }) async {
    final id = const Uuid().v4();
    final model = TransactionModel(
      id: id,
      contactId: contactId,
      type: type,
      status: TransactionStatus.pending,
      amount: amount,
      date: date,
      description: description,
      cartons: _extractCartonsFromPayload(metadata),
      qtyPerCarton: _extractQtyPerCartonFromPayload(metadata),
      unitPrice: _extractUnitPriceFromPayload(metadata),
      metadata: metadata,
      referenceId: referenceId,
    );

    await _db.transaction(() async {
      await _ensureCanGiveGoods(model);
      await _db.into(_db.transactions).insert(model.toDbCompanion());
      await _updateContactBalance(contactId);
      await _applyInventoryEffect(model);
    });

    // --- Sync Logic ---
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.phoneNumber != null) {
        // Fetch Contact details to get their phone number
        final contact = await (_db.select(
          _db.contacts,
        )..where((t) => t.id.equals(contactId))).getSingleOrNull();

        if (contact != null && contact.phoneNumber != null) {
          await _syncService.saveTransactionToCloud(
            transaction: model,
            creatorUid: user.uid,
            creatorPhone: user.phoneNumber!,
            contactPhone: contact.phoneNumber!,
          );
        }
      }
    } catch (e) {
      // Fail silently (offline or sync error), will retry in background later
      debugPrint('Background Sync Failed: $e');
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final existing = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(transaction.id)))
        .getSingleOrNull();

    if (existing == null) {
      throw Exception('Transaction not found. Please refresh and try again.');
    }
    final existingModel = TransactionModel.fromDb(existing);

    await _db.transaction(() async {
      await _applyInventoryEffect(existingModel, reverse: true);

      await _ensureCanGiveGoods(transaction);

      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(transaction.toDbCompanion());

      await _applyInventoryEffect(transaction);

      await _updateContactBalance(existingModel.contactId);
      if (existingModel.contactId != transaction.contactId) {
        await _updateContactBalance(transaction.contactId);
      }
    });

    // 3. Sync to Cloud
    try {
      final user = FirebaseAuth.instance.currentUser;
      final contact = await (_db.select(
        _db.contacts,
      )..where((t) => t.id.equals(transaction.contactId))).getSingleOrNull();

      if (user != null &&
          user.phoneNumber != null &&
          contact != null &&
          contact.phoneNumber != null) {
        await _syncService.saveTransactionToCloud(
          transaction: transaction,
          creatorUid: user.uid,
          creatorPhone: user.phoneNumber!,
          contactPhone: contact.phoneNumber!,
        );
      }
    } catch (e) {
      debugPrint('Update Sync Failed: $e');
    }
  }

  @override
  Future<void> updateTransactionStatus(String id, TransactionStatus status) async {
    final tx = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (tx == null) {
      throw Exception('Transaction not found.');
    }

    await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(status: Value(status.index)));

    try {
      final updated = await (_db.select(_db.transactions)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (updated == null) return;

      final txModel = TransactionModel.fromDb(updated);
      final user = FirebaseAuth.instance.currentUser;
      final contact = await (_db.select(_db.contacts)
            ..where((t) => t.id.equals(txModel.contactId)))
          .getSingleOrNull();

      if (user != null &&
          user.phoneNumber != null &&
          contact != null &&
          contact.phoneNumber != null) {
        await _syncService.saveTransactionToCloud(
          transaction: txModel,
          creatorUid: user.uid,
          creatorPhone: user.phoneNumber!,
          contactPhone: contact.phoneNumber!,
        );
      }
    } catch (e) {
      debugPrint('Status Sync Failed: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Get the transaction first to know the contactId
    final tx = await (_db.select(
      _db.transactions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (tx != null) {
      final txModel = TransactionModel.fromDb(tx);
      await _db.transaction(() async {
        await (_db.delete(
          _db.transactions,
        )..where((tbl) => tbl.id.equals(id))).go();

        await _applyInventoryEffect(txModel, reverse: true);
        await _updateContactBalance(tx.contactId);
      });
    }
  }

  @override
  Future<Decimal> calculateNetBalance(String contactId) async {
    final transactions = await getTransactionsForContact(contactId);

    Decimal balance = Decimal.zero;
    for (final tx in transactions) {
      balance += tx.balanceEffect;
    }
    return balance;
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final rows =
        await (_db.select(_db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map((e) => TransactionModel.fromDb(e)).toList();
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsForContact(
    String contactId,
  ) {
    return (_db.select(_db.transactions)
          ..where((tbl) => tbl.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map((e) => TransactionModel.fromDb(e)).toList());
  }

  /// Internal: Update the contact's cached netBalance field
  Future<void> _updateContactBalance(String contactId) async {
    final newBalance = await calculateNetBalance(contactId);
    await (_db.update(
      _db.contacts,
    )..where((tbl) => tbl.id.equals(contactId))).write(
      ContactsCompanion(
        netBalance: Value(newBalance.toString()),
        lastTransactionDate: Value(DateTime.now()),
      ),
    );
  }

  bool _isGoodsTransaction(TransactionType type) {
    return type == TransactionType.goodsGiven || type == TransactionType.goodsTaken;
  }

  int _toPositiveInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw < 0 ? 0 : raw;
    final parsed = int.tryParse(raw.toString().trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  int _extractCartons(TransactionModel tx) {
    final cartons = tx.cartons ?? _extractCartonsFromPayload(tx.metadata);
    return cartons > 0 ? cartons : 0;
  }

  int _extractQtyPerCarton(TransactionModel tx) {
    final qtyPerCarton = tx.qtyPerCarton ?? _extractQtyPerCartonFromPayload(tx.metadata);
    return qtyPerCarton > 0 ? qtyPerCarton : 0;
  }

  Decimal? _extractUnitPrice(TransactionModel tx) {
    if (tx.unitPrice != null) return tx.unitPrice;
    return _extractUnitPriceFromPayload(tx.metadata);
  }

  int _extractCartonsFromPayload(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0;
    return _toPositiveInt(metadata['cartons']);
  }

  int _extractQtyPerCartonFromPayload(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0;
    return _toPositiveInt(metadata['qtyPerCarton']);
  }

  Decimal? _extractUnitPriceFromPayload(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final value = metadata['unitPrice'];
    if (value == null) return null;
    return Decimal.tryParse(value.toString());
  }

  int _extractTransactionQuantity(TransactionModel tx) {
    final cartons = _extractCartons(tx);
    if (cartons > 0) {
      return cartons;
    }

    final legacyQuantity = tx.metadata == null ? 0 : _toPositiveInt(tx.metadata!['quantity']);
    return legacyQuantity > 0 ? legacyQuantity : 1;
  }

  int _calculateInventoryDelta(TransactionModel tx) {
    if (!_isGoodsTransaction(tx.type)) return 0;
    final qty = _extractTransactionQuantity(tx);
    if (qty <= 0) return 0;
    return tx.type == TransactionType.goodsTaken ? qty : -qty;
  }

  String? _transactionItemReference(TransactionModel tx) {
    return _normalizeText(tx.referenceId);
  }

  String? _transactionItemName(TransactionModel tx) {
    return _normalizeText(tx.description);
  }

  String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<Product?> _findInventoryProductForTransaction(TransactionModel tx) async {
    final reference = _transactionItemReference(tx);
    if (reference != null) {
      final bySku = await (_db.select(_db.products)
            ..where((tbl) => tbl.sku.equals(reference)))
          .getSingleOrNull();
      if (bySku != null) return bySku;
    }

    final itemName = _transactionItemName(tx);
    if (itemName != null) {
      final candidates = await (_db.select(_db.products)
            ..where((tbl) => tbl.name.equals(itemName)))
          .get();

      if (candidates.isNotEmpty) {
        return candidates.first;
      }
    }

    return null;
  }

  Future<Product> _createInventoryProductForTransaction(TransactionModel tx) async {
    final now = DateTime.now();
    final reference = _transactionItemReference(tx);
    final itemName = _transactionItemName(tx);
    final unitPrice = _extractUnitPrice(tx) ?? Decimal.zero;
    final cartons = _extractCartons(tx);
    final itemsPerCarton = _extractQtyPerCartonFromPayload(tx.metadata);
    final unit = 'carton';
    final name =
        itemName ?? (reference != null ? 'Item $reference' : 'Transaction Item');

    final newProductId = const Uuid().v4();
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: newProductId,
            name: name,
            sku: Value(reference),
            unit: Value(unit),
            itemsPerCarton: Value(itemsPerCarton > 0 ? itemsPerCarton : null),
            costPrice: Value(unitPrice.toString()),
            sellingPrice: Value(unitPrice.toString()),
            stockQuantity: Value(cartons),
            reorderLevel: const Value(0),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final created = await (_db.select(_db.products)
          ..where((tbl) => tbl.id.equals(newProductId)))
        .getSingle();
    return created;
  }

  Future<void> _ensureCanGiveGoods(
    TransactionModel tx,
  ) async {
    if (tx.type != TransactionType.goodsGiven) return;

    final cartons = _extractCartons(tx);
    if (cartons <= 0) {
      throw Exception('Quantity must be greater than zero for goods given.');
    }

    final product = await _findInventoryProductForTransaction(tx);
    if (product == null) {
      throw Exception(
        'This item is not in inventory. Add stock first before giving goods.',
      );
    }

    if (product.stockQuantity < cartons) {
      throw Exception(
        'Insufficient stock for ${product.name}. Available: ${product.stockQuantity}, required: $cartons carton(s).',
      );
    }
  }

  Future<void> _applyInventoryEffect(
    TransactionModel tx, {
    bool reverse = false,
  }) async {
    if (!_isGoodsTransaction(tx.type)) return;

    var delta = _calculateInventoryDelta(tx);
    if (reverse) {
      delta = -delta;
    }
    if (delta == 0) return;

    Product? product = await _findInventoryProductForTransaction(tx);
    if (product == null && delta > 0) {
      product = await _createInventoryProductForTransaction(tx);
    }
    if (product == null) {
      throw Exception(
        'Cannot update inventory because this goods transaction does not match any product.',
      );
    }
    final resolvedProduct = product;
    final unitPrice = _extractUnitPrice(tx);

    final now = DateTime.now();
    final targetStock = resolvedProduct.stockQuantity + delta;
    if (targetStock < 0) {
      if (reverse) {
        return;
      }
      throw Exception(
        'Insufficient stock for ${resolvedProduct.name}. Available: ${resolvedProduct.stockQuantity}, required: ${delta.abs()}.',
      );
    }

    if (delta == 0) {
      return;
    }

    final companion = unitPrice != null && !reverse
        ? ProductsCompanion(
            stockQuantity: Value(targetStock),
            itemsPerCarton: Value(_extractQtyPerCarton(tx) > 0 ? _extractQtyPerCarton(tx) : null),
            costPrice: Value(unitPrice.toString()),
            sellingPrice: Value(unitPrice.toString()),
            updatedAt: Value(now),
          )
        : ProductsCompanion(
            stockQuantity: Value(targetStock),
            itemsPerCarton: Value(_extractQtyPerCarton(tx) > 0 ? _extractQtyPerCarton(tx) : null),
            updatedAt: Value(now),
          );

    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(resolvedProduct.id)))
        .write(companion);

    await _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            id: const Uuid().v4(),
            productId: resolvedProduct.id,
            movementType: delta > 0 ? 'contact_take' : 'contact_give',
            quantityChange: delta,
            note: Value(
              reverse
                  ? 'Reverted contact transaction ${tx.id}'
                  : 'From contact transaction ${tx.id}',
            ),
            createdAt: now,
          ),
        );
  }
}
