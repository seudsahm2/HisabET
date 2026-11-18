import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

/// Net balance of a contact: the sum of every live transaction's effect.
///
/// Positive means they owe me, negative means I owe them.
Decimal netBalanceOf(Iterable<TransactionModel> transactions) {
  return transactions.fold(
    Decimal.zero,
    (sum, tx) => sum + tx.balanceEffect,
  );
}

/// The only code path that writes `contacts.net_balance`.
///
/// The cached balance is always recomputed from the full transaction history
/// rather than adjusted incrementally, so it can never drift from the ledger:
/// an interrupted or buggy write is corrected by the next recalculation.
/// Call it inside the same `db.transaction` as the ledger write it follows.
Future<void> recalculateContactBalance(
  AppDatabase db,
  String contactId,
) async {
  final rows = await (db.select(db.transactions)
        ..where(
          (tbl) => tbl.contactId.equals(contactId) & tbl.isDeleted.equals(false),
        ))
      .get();

  final balance = netBalanceOf(rows.map(TransactionModel.fromDb));

  await (db.update(db.contacts)..where((tbl) => tbl.id.equals(contactId)))
      .write(
    ContactsCompanion(
      netBalance: Value(balance.toString()),
      lastTransactionDate: Value(DateTime.now()),
    ),
  );
}
