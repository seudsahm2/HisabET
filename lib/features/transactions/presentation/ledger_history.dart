import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

/// One day of a contact's ledger — the digital version of the date a trader
/// writes at the top of each day's notebook entries.
class LedgerDay {
  const LedgerDay({required this.day, required this.entries, required this.net});

  /// Midnight, local time.
  final DateTime day;

  /// Newest first.
  final List<TransactionModel> entries;

  /// Sum of the day's balance effects: positive = they owe more.
  final Decimal net;
}

/// Groups entries by calendar day, newest day first.
List<LedgerDay> groupByDay(List<TransactionModel> transactions) {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final days = <LedgerDay>[];
  for (final tx in sorted) {
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (days.isEmpty || days.last.day != day) {
      days.add(LedgerDay(day: day, entries: [tx], net: tx.balanceEffect));
    } else {
      final last = days.removeLast();
      days.add(LedgerDay(day: day, entries: [...last.entries, tx], net: last.net + tx.balanceEffect));
    }
  }
  return days;
}

/// "Today", "Yesterday", "Tue, 12 Nov", or "12 Nov 2025" for other years.
String dayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (d.year == now.year) return DateFormat('EEE, d MMM').format(d);
  return DateFormat('d MMM yyyy').format(d);
}

/// The notebook line — "5 × 24 × 1,200" (cartons × pairs per carton × price)
/// — when the entry has the parts, else null.
String? notebookFormula(TransactionModel tx) {
  final cartons = tx.cartons;
  final perCarton = tx.qtyPerCarton;
  final price = tx.unitPrice;
  if (cartons == null || perCarton == null || price == null) return null;
  if (cartons <= 0 || perCarton <= 0 || price <= Decimal.zero) return null;
  final money = NumberFormat('#,##0.##').format(double.parse(price.toString()));
  return '$cartons × $perCarton × $money';
}

/// Plain-language name for an entry's type.
String transactionTypeLabel(TransactionType type) => switch (type) {
      TransactionType.goodsGiven => 'Goods given',
      TransactionType.goodsTaken => 'Goods taken',
      TransactionType.paymentReceived => 'Payment received',
      TransactionType.paymentGiven => 'Payment made',
    };
