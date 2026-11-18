import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/ledger_history.dart';

TransactionModel tx(String id, DateTime date, TransactionType type, String amount,
        {int? cartons, int? perCarton, String? price}) =>
    TransactionModel(
      id: id,
      contactId: 'c',
      type: type,
      amount: Decimal.parse(amount),
      date: date,
      cartons: cartons,
      qtyPerCarton: perCarton,
      unitPrice: price == null ? null : Decimal.parse(price),
    );

void main() {
  group('groupByDay', () {
    test('groups by calendar day, newest first, with each day\'s net', () {
      final days = groupByDay([
        tx('a', DateTime(2026, 11, 17, 9), TransactionType.goodsGiven, '144000'),
        tx('b', DateTime(2026, 11, 18, 8), TransactionType.goodsGiven, '1000'),
        tx('c', DateTime(2026, 11, 17, 17), TransactionType.paymentReceived, '50000'),
        tx('d', DateTime(2026, 11, 18, 20), TransactionType.goodsTaken, '300'),
      ]);
      expect(days.map((d) => d.day), [DateTime(2026, 11, 18), DateTime(2026, 11, 17)]);
      expect(days[0].entries.map((t) => t.id), ['d', 'b']); // newest first within a day
      expect(days[0].net, Decimal.parse('700')); // 1000 - 300
      expect(days[1].net, Decimal.parse('94000')); // 144000 - 50000
    });

    test('is empty for no entries', () {
      expect(groupByDay(const []), isEmpty);
    });
  });

  group('dayLabel', () {
    final now = DateTime(2026, 11, 18, 15);
    test('today and yesterday by name', () {
      expect(dayLabel(DateTime(2026, 11, 18), now), 'Today');
      expect(dayLabel(DateTime(2026, 11, 17), now), 'Yesterday');
    });
    test('weekday and date within the year, full date otherwise', () {
      expect(dayLabel(DateTime(2026, 11, 10), now), 'Tue, 10 Nov');
      expect(dayLabel(DateTime(2025, 12, 31), now), '31 Dec 2025');
    });
  });

  group('notebookFormula', () {
    test('writes the line the way a trader writes it in the notebook', () {
      final t = tx('a', DateTime(2026), TransactionType.goodsGiven, '144000', cartons: 5, perCarton: 24, price: '1200');
      expect(notebookFormula(t), '5 × 24 × 1,200');
    });
    test('is null when parts are missing', () {
      expect(notebookFormula(tx('a', DateTime(2026), TransactionType.paymentReceived, '5000')), isNull);
    });
  });
}
