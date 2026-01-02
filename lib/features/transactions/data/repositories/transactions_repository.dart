import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<void> deleteTransaction(String id);
  Future<Decimal> calculateNetBalance(String contactId);
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
      amount: amount,
      date: date,
      description: description,
      metadata: metadata,
      referenceId: referenceId,
    );

    await _db.into(_db.transactions).insert(model.toDbCompanion());

    // Recalculate and update the contact's net balance
    await _updateContactBalance(contactId);

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
      print('Background Sync Failed: $e');
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    // 1. Update local DB
    await (_db.update(_db.transactions)
          ..where((t) => t.id.equals(transaction.id)))
        .write(transaction.toDbCompanion());

    // 2. Recalculate Contact Balance
    await _updateContactBalance(transaction.contactId);

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
      print('Update Sync Failed: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Get the transaction first to know the contactId
    final tx = await (_db.select(
      _db.transactions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (tx != null) {
      await (_db.delete(
        _db.transactions,
      )..where((tbl) => tbl.id.equals(id))).go();
      // Recalculate balance after deletion
      await _updateContactBalance(tx.contactId);
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
}
