import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

void main() {
  group('TransactionModel Balance Effect Tests', () {
    test('goodsGiven should add to balance (they owe me)', () {
      final tx = TransactionModel(
        id: '1',
        contactId: 'c1',
        type: TransactionType.goodsGiven,
        amount: Decimal.parse('1000'),
        date: DateTime.now(),
      );

      expect(tx.balanceEffect, Decimal.parse('1000'));
    });

    test('goodsTaken should subtract from balance (I owe them)', () {
      final tx = TransactionModel(
        id: '2',
        contactId: 'c1',
        type: TransactionType.goodsTaken,
        amount: Decimal.parse('500'),
        date: DateTime.now(),
      );

      expect(tx.balanceEffect, Decimal.parse('-500'));
    });

    test('paymentReceived should subtract from balance (they paid me)', () {
      final tx = TransactionModel(
        id: '3',
        contactId: 'c1',
        type: TransactionType.paymentReceived,
        amount: Decimal.parse('300'),
        date: DateTime.now(),
      );

      expect(tx.balanceEffect, Decimal.parse('-300'));
    });

    test('paymentGiven should add to balance (I paid them)', () {
      final tx = TransactionModel(
        id: '4',
        contactId: 'c1',
        type: TransactionType.paymentGiven,
        amount: Decimal.parse('200'),
        date: DateTime.now(),
      );

      expect(tx.balanceEffect, Decimal.parse('200'));
    });
  });

  group('Net Balance Calculation Tests', () {
    test('Complex scenario: Multiple transactions should net correctly', () {
      // Scenario from the user's notebook example:
      // - Gave goods worth 348,900
      // - Took goods worth 354,840
      // - Received payment 141,500
      // Expected net: 348,900 - 354,840 - (-141,500) = 348,900 - 354,840 + 141,500 = 135,560
      // Wait, let me recalculate based on balanceEffect:
      // goodsGiven 348900 -> +348900
      // goodsTaken 354840 -> -354840
      // paymentReceived 141500 -> -141500
      // Net = 348900 - 354840 - 141500 = -147440 (they owe me -147440, meaning I owe them 147440)

      final transactions = [
        TransactionModel(
          id: '1',
          contactId: 'c1',
          type: TransactionType.goodsGiven,
          amount: Decimal.parse('348900'),
          date: DateTime.now(),
        ),
        TransactionModel(
          id: '2',
          contactId: 'c1',
          type: TransactionType.goodsTaken,
          amount: Decimal.parse('354840'),
          date: DateTime.now(),
        ),
        TransactionModel(
          id: '3',
          contactId: 'c1',
          type: TransactionType.paymentReceived,
          amount: Decimal.parse('141500'),
          date: DateTime.now(),
        ),
      ];

      Decimal netBalance = Decimal.zero;
      for (final tx in transactions) {
        netBalance += tx.balanceEffect;
      }

      // 348900 + (-354840) + (-141500) = 348900 - 354840 - 141500 = -147440
      expect(netBalance, Decimal.parse('-147440'));
    });

    test('Zero error: Decimal precision maintained', () {
      // Using values that would cause floating point errors
      final transactions = [
        TransactionModel(
          id: '1',
          contactId: 'c1',
          type: TransactionType.goodsGiven,
          amount: Decimal.parse('0.1'),
          date: DateTime.now(),
        ),
        TransactionModel(
          id: '2',
          contactId: 'c1',
          type: TransactionType.goodsGiven,
          amount: Decimal.parse('0.2'),
          date: DateTime.now(),
        ),
      ];

      Decimal netBalance = Decimal.zero;
      for (final tx in transactions) {
        netBalance += tx.balanceEffect;
      }

      // Must be exactly 0.3, not 0.30000000000000004
      expect(netBalance, Decimal.parse('0.3'));
    });
  });
}
