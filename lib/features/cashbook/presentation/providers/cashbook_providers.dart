import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

enum CashbookPeriod {
  today,
  last7Days,
  last30Days,
  all,
}

enum CashbookDirection {
  cashIn,
  cashOut,
}

class CashbookEntry {
  final String id;
  final DateTime date;
  final Decimal amount;
  final CashbookDirection direction;
  final String title;
  final String subtitle;
  final String source;

  const CashbookEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.direction,
    required this.title,
    required this.subtitle,
    required this.source,
  });
}

class CashbookSummary {
  final Decimal totalIn;
  final Decimal totalOut;
  final Decimal net;

  const CashbookSummary({
    required this.totalIn,
    required this.totalOut,
    required this.net,
  });

  factory CashbookSummary.empty() {
    return CashbookSummary(
      totalIn: Decimal.zero,
      totalOut: Decimal.zero,
      net: Decimal.zero,
    );
  }
}

class CashbookData {
  final CashbookSummary summary;
  final List<CashbookEntry> entries;

  const CashbookData({
    required this.summary,
    required this.entries,
  });
}

final cashbookDataProvider = FutureProvider.family<CashbookData, CashbookPeriod>((
  ref,
  period,
) async {
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);
  final expensesRepo = ref.watch(expensesRepositoryProvider);

  final contacts = await ref.watch(allContactsProvider.future);
  final expenses = await expensesRepo.getAllExpenses();
  final transactions = await transactionsRepo.getRecentTransactions(limit: 1000);

  final contactById = {for (final contact in contacts) contact.id: contact};

  final now = DateTime.now();
  DateTime? from;
  switch (period) {
    case CashbookPeriod.today:
      from = DateTime(now.year, now.month, now.day);
      break;
    case CashbookPeriod.last7Days:
      from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      break;
    case CashbookPeriod.last30Days:
      from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      break;
    case CashbookPeriod.all:
      from = null;
      break;
  }

  final entries = <CashbookEntry>[
    ..._fromExpenses(expenses, from),
    ..._fromTransactions(transactions, contacts: contactById, from: from),
  ]..sort((a, b) => b.date.compareTo(a.date));

  Decimal totalIn = Decimal.zero;
  Decimal totalOut = Decimal.zero;
  for (final entry in entries) {
    if (entry.direction == CashbookDirection.cashIn) {
      totalIn += entry.amount;
    } else {
      totalOut += entry.amount;
    }
  }

  return CashbookData(
    summary: CashbookSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      net: totalIn - totalOut,
    ),
    entries: entries,
  );
});

List<CashbookEntry> _fromExpenses(List<ExpenseModel> expenses, DateTime? from) {
  return expenses
      .where((expense) => from == null || !_isBeforeDay(expense.spentAt, from))
      .map(
        (expense) => CashbookEntry(
          id: 'expense_${expense.id}',
          date: expense.spentAt,
          amount: expense.amount,
          direction: CashbookDirection.cashOut,
          title: expense.title,
          subtitle: [
            if (expense.vendor != null && expense.vendor!.trim().isNotEmpty) expense.vendor!,
            expense.paymentMethod.toUpperCase(),
          ].join(' • '),
          source: 'Expense',
        ),
      )
      .toList();
}

List<CashbookEntry> _fromTransactions(
  List<TransactionModel> transactions, {
  required Map<String, ContactModel> contacts,
  required DateTime? from,
}) {
  final items = <CashbookEntry>[];

  for (final transaction in transactions) {
    if (from != null && _isBeforeDay(transaction.date, from)) continue;

    final isPayment = transaction.type == TransactionType.paymentReceived ||
        transaction.type == TransactionType.paymentGiven;
    if (!isPayment) continue;

    final isIn = transaction.type == TransactionType.paymentReceived;
    final counterparty = contacts[transaction.contactId]?.name ?? 'Unknown contact';
    final paymentMethod = transaction.metadata?['paymentMethod']?.toString();
    final subtitleParts = <String>[
      counterparty,
      if (paymentMethod != null && paymentMethod.trim().isNotEmpty) paymentMethod.toUpperCase(),
      transaction.status.name,
    ];

    items.add(
      CashbookEntry(
        id: 'transaction_${transaction.id}',
        date: transaction.date,
        amount: transaction.amount,
        direction: isIn ? CashbookDirection.cashIn : CashbookDirection.cashOut,
        title: isIn ? 'Payment Received' : 'Payment Given',
        subtitle: subtitleParts.join(' • '),
        source: 'Transaction',
      ),
    );
  }

  return items;
}

bool _isBeforeDay(DateTime target, DateTime dayStart) {
  return target.isBefore(dayStart);
}