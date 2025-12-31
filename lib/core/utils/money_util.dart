import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class MoneyUtil {
  /// Converts a double or int to Decimal to avoid floating point errors.
  /// Standardizes usage across the app.
  static Decimal toDecimal(num value) {
    return Decimal.parse(value.toString());
  }

  /// Formats a Decimal amount to a currency string (e.g., "1,250.00").
  /// Defaults to 2 decimal places.
  static String format(Decimal amount, {String symbol = 'ETB '}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    // double.parse is safe here only for display purposes, not calculation
    return formatter.format(double.parse(amount.toString()));
  }

  /// Calculates the total cost for a quantity of items at a unit price.
  /// (quantity * unitPrice)
  static Decimal calculateTotal(int quantity, Decimal unitPrice) {
    return toDecimal(quantity) * unitPrice;
  }

  /// Calculates the total cost for cartons (batch size * quantity * unitPrice)
  /// e.g. 2 cartons of 36 pairs at 1250 each.
  static Decimal calculateBatchTotal(
    int batchCount,
    int quantityPerBatch,
    Decimal unitPrice,
  ) {
    return toDecimal(batchCount) * toDecimal(quantityPerBatch) * unitPrice;
  }
}
