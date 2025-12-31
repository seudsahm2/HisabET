import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/utils/money_util.dart';

void main() {
  group('MoneyUtil Precision Tests', () {
    test('calculateTotal should return correct Decimal value', () {
      final quantity = 36;
      final price = Decimal.parse('1250.50');

      final total = MoneyUtil.calculateTotal(quantity, price);

      // 36 * 1250.5 = 45018.0
      expect(total, Decimal.parse('45018.0'));
    });

    test('calculateBatchTotal should handle multi-carton logic', () {
      final cartons = 2;
      final pairsPerCarton = 36;
      final price = Decimal.parse('1250');

      final total = MoneyUtil.calculateBatchTotal(
        cartons,
        pairsPerCarton,
        price,
      );

      // 2 * 36 * 1250 = 90,000
      expect(total, Decimal.parse('90000'));
    });

    test('Floating point error avoidance check', () {
      // Classic floating point issue: 0.1 + 0.2 != 0.3 in double
      final d1 = Decimal.parse('0.1');
      final d2 = Decimal.parse('0.2');
      final sum = d1 + d2;

      expect(sum, Decimal.parse('0.3'));
      expect(sum.toDouble(), 0.3);
    });
  });
}
