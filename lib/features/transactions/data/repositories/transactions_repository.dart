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
  /// Watches the most recent transactions
  Stream<List<TransactionModel>> watchRecentTransactions({int limit = 10});
  Stream<List<TransactionModel>> watchTransactionsForContact(String contactId);
  /// Re-uploads ALL local transactions for ALL linked contacts to Firestore.
  Future<int> syncAllTransactionsToCloud();
  /// Re-uploads only UNSYNCED local transactions to Firestore.
  Future<int> syncAllUnsyncedTransactionsToCloud();
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
    // ── 1. Smart Daily Aggregation ──
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    TransactionModel? existingParent;
    if (referenceId != null && referenceId.trim().isNotEmpty) {
      final rows = await (_db.select(_db.transactions)
            ..where((t) =>
                t.contactId.equals(contactId) &
                t.type.equals(type.index) &
                t.referenceId.equals(referenceId) &
                t.date.isBetweenValues(startOfDay, endOfDay)))
          .get();
      if (rows.isNotEmpty) {
        existingParent = TransactionModel.fromDb(rows.first);
      }
    } else if (description != null && description.trim().isNotEmpty) {
      final rows = await (_db.select(_db.transactions)
            ..where((t) =>
                t.contactId.equals(contactId) &
                t.type.equals(type.index) &
                t.description.equals(description) &
                t.date.isBetweenValues(startOfDay, endOfDay)))
          .get();
      if (rows.isNotEmpty) {
        existingParent = TransactionModel.fromDb(rows.first);
      }
    }

    TransactionModel modelToSync;

    if (existingParent != null) {
      // ── Aggregate into Parent ──
      debugPrint('[TransactionsRepo] Smart Daily Aggregation: Merging with ${existingParent.id}');
      final newTotalAmount = existingParent.amount + amount;
      
      final currentCartons = _extractCartonsFromPayload(metadata);
      final newCartons = (existingParent.cartons ?? 0) + currentCartons;
      final hasCartons = newCartons > 0;

      final existingMeta = existingParent.metadata ?? {};
      final List<dynamic> history = List<dynamic>.from(existingMeta['history'] ?? []);
      
      // If this is the first merge, we need to log the original parent into the history too
      if (history.isEmpty) {
         history.add({
           'amount': existingParent.amount.toString(),
           'date': existingParent.date.toIso8601String(),
           'cartons': existingParent.cartons,
           'metadata': {...existingMeta}..remove('history'),
         });
      }

      // Add the new split to history
      history.add({
        'amount': amount.toString(),
        'date': date.toIso8601String(),
        'cartons': currentCartons,
        'metadata': metadata,
      });

      final mergedMetadata = {
        ...existingMeta,
        ...metadata ?? {},
        'history': history,
        if (hasCartons) 'quantity': newCartons,
      };

      modelToSync = TransactionModel(
        id: existingParent.id,
        contactId: existingParent.contactId,
        type: existingParent.type,
        status: existingParent.status,
        amount: newTotalAmount,
        date: existingParent.date, // keep original date
        description: existingParent.description,
        cartons: hasCartons ? newCartons : null,
        qtyPerCarton: existingParent.qtyPerCarton,
        unitPrice: existingParent.unitPrice,
        metadata: mergedMetadata,
        referenceId: existingParent.referenceId,
      );

      await _db.transaction(() async {
        await _applyInventoryEffect(existingParent!, reverse: true); // Reverse old
        await _ensureCanGiveGoods(modelToSync);
        await (_db.update(_db.transactions)..where((t) => t.id.equals(existingParent!.id)))
            .write(modelToSync.toDbCompanion());
        await _applyInventoryEffect(modelToSync); // Apply new aggregated
        await _updateContactBalance(contactId);
      });

    } else {
      // ── Normal Insert ──
      final id = const Uuid().v4();
      modelToSync = TransactionModel(
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
        await _ensureCanGiveGoods(modelToSync);
        await _db.into(_db.transactions).insert(modelToSync.toDbCompanion());
        await _updateContactBalance(contactId);
        await _applyInventoryEffect(modelToSync);
      });
    }

    // --- Sync Logic ---
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch Contact details to get their phone number
        final contact = await (_db.select(
          _db.contacts,
        )..where((t) => t.id.equals(contactId))).getSingleOrNull();

        // Sync as long as the contact is a verified user (has UID or phone)
        if (contact != null && (contact.phoneNumber != null || contact.linkedUserUid != null)) {
          final isSynced = await _syncService.saveTransactionToCloud(
            transaction: modelToSync,
            creatorUid: user.uid,
            creatorPhone: user.phoneNumber ?? user.email ?? '',
            contactPhone: contact.phoneNumber,
            contactUid: contact.linkedUserUid,
          );
          if (isSynced) {
            await (_db.update(_db.transactions)..where((t) => t.id.equals(modelToSync.id)))
                .write(const TransactionsCompanion(isSynced: Value(true)));
          }
        } else {
          debugPrint('[SYNC] Skipping cloud sync: contact has no phone or linked UID.');
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
          contact != null &&
          (contact.phoneNumber != null || contact.linkedUserUid != null)) {
        final isSynced = await _syncService.saveTransactionToCloud(
          transaction: transaction,
          creatorUid: user.uid,
          creatorPhone: user.phoneNumber ?? user.email ?? '',
          contactPhone: contact.phoneNumber,
          contactUid: contact.linkedUserUid,
        );
        if (isSynced) {
          await (_db.update(_db.transactions)..where((t) => t.id.equals(transaction.id)))
              .write(const TransactionsCompanion(isSynced: Value(true)));
        }
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
          contact != null &&
          (contact.phoneNumber != null || contact.linkedUserUid != null)) {
        final isSynced = await _syncService.saveTransactionToCloud(
          transaction: txModel,
          creatorUid: user.uid,
          creatorPhone: user.phoneNumber ?? user.email ?? '',
          contactPhone: contact.phoneNumber,
          contactUid: contact.linkedUserUid,
        );
        if (isSynced) {
          await (_db.update(_db.transactions)..where((t) => t.id.equals(txModel.id)))
              .write(const TransactionsCompanion(isSynced: Value(true)));
        }
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
  @override
  Stream<List<TransactionModel>> watchRecentTransactions({int limit = 10}) {
    return (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map((e) => TransactionModel.fromDb(e)).toList());
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
          .get();
      if (bySku.isNotEmpty) return bySku.first;
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
    final itemsPerCarton = _extractQtyPerCartonFromPayload(tx.metadata);
    final name = itemName ?? (reference != null ? 'Item $reference' : 'Transaction Item');

    // Optional product detail fields captured from the transaction form
    final barcode = tx.metadata?['barcode']?.toString().trim();
    final category = tx.metadata?['category']?.toString().trim();
    final brand = tx.metadata?['brand']?.toString().trim();

    final newProductId = const Uuid().v4();
    // stockQuantity is intentionally 0 here — _applyInventoryEffect will
    // apply the delta immediately after, preventing a double-count.
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: newProductId,
            name: name,
            sku: Value(reference),
            barcode: Value(barcode?.isEmpty == true ? null : barcode),
            category: Value(category?.isEmpty == true ? null : category),
            brand: Value(brand?.isEmpty == true ? null : brand),
            unit: const Value('carton'),
            itemsPerCarton: Value(itemsPerCarton > 0 ? itemsPerCarton : null),
            costPrice: Value(unitPrice.toString()),
            sellingPrice: Value(unitPrice.toString()),
            stockQuantity: const Value(0),
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

  @override
  Future<int> syncAllTransactionsToCloud() async {
    int uploadCount = 0;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[BULK SYNC] No logged-in user. Aborting.');
        return 0;
      }

      final creatorPhone = user.phoneNumber ?? user.email ?? '';

      // Fetch all local transactions
      final allTxRows = await _db.select(_db.transactions).get();
      debugPrint('[BULK SYNC] Found ${allTxRows.length} local transactions to sync.');

      // Cache contacts to avoid repeated DB hits
      final contactCache = <String, Contact?>{};

      for (final row in allTxRows) {
        try {
          final contactId = row.contactId;
          if (!contactCache.containsKey(contactId)) {
            contactCache[contactId] = await (_db.select(_db.contacts)
              ..where((t) => t.id.equals(contactId))).getSingleOrNull();
          }
          final contact = contactCache[contactId];

          if (contact != null && (contact.phoneNumber != null || contact.linkedUserUid != null)) {
            final model = TransactionModel.fromDb(row);
            await _syncService.saveTransactionToCloud(
              transaction: model,
              creatorUid: user.uid,
              creatorPhone: creatorPhone,
              contactPhone: contact.phoneNumber,
              contactUid: contact.linkedUserUid,
            );
            uploadCount++;
          }
        } catch (e) {
          debugPrint('[BULK SYNC] Failed to sync tx ${row.id}: $e');
        }
      }
      debugPrint('[BULK SYNC] ✅ Done! Uploaded $uploadCount transactions.');
    } catch (e) {
      debugPrint('[BULK SYNC] ❌ Fatal error: $e');
    }
    return uploadCount;
  }

  @override
  Future<int> syncAllUnsyncedTransactionsToCloud() async {
    int uploadCount = 0;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final creatorPhone = user.phoneNumber ?? user.email ?? '';

      // Fetch only unsynced transactions
      final unsyncedRows = await (_db.select(_db.transactions)
            ..where((t) => t.isSynced.equals(false)))
          .get();

      if (unsyncedRows.isEmpty) return 0;
      debugPrint('📡 [AUTO SYNC] Found ${unsyncedRows.length} unsynced transactions.');

      final contactCache = <String, Contact?>{};

      for (final row in unsyncedRows) {
        try {
          final contactId = row.contactId;
          if (!contactCache.containsKey(contactId)) {
            contactCache[contactId] = await (_db.select(_db.contacts)
              ..where((t) => t.id.equals(contactId))).getSingleOrNull();
          }
          final contact = contactCache[contactId];

          if (contact != null && (contact.phoneNumber != null || contact.linkedUserUid != null)) {
            final model = TransactionModel.fromDb(row);
            final isSynced = await _syncService.saveTransactionToCloud(
              transaction: model,
              creatorUid: user.uid,
              creatorPhone: creatorPhone,
              contactPhone: contact.phoneNumber,
              contactUid: contact.linkedUserUid,
            );
            if (isSynced) {
              await (_db.update(_db.transactions)..where((t) => t.id.equals(row.id)))
                  .write(const TransactionsCompanion(isSynced: Value(true)));
              uploadCount++;
            }
          }
        } catch (e) {
          debugPrint('📡 [AUTO SYNC] Failed to sync tx ${row.id}: $e');
        }
      }
      debugPrint('📡 [AUTO SYNC] ✅ Uploaded $uploadCount unsynced transactions.');
    } catch (e) {
      debugPrint('📡 [AUTO SYNC] ❌ Fatal error: $e');
    }
    return uploadCount;
}
}
