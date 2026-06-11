import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Displays a currency amount with correct sign, color and style.
/// Removes the need for inline amount formatting logic everywhere.
///
/// Sign behavior:
/// - Positive amounts → green (positive semantic)
/// - Negative amounts → red  (negative semantic)
/// - Neutral (null sign) → primary text color
///
/// Usage:
/// ```dart
/// AppAmountText(amount: 'ETB 4,200', isPositive: true)
/// AppAmountText.raw(amount: Decimal.parse('4200'), currency: 'ETB')
/// AppAmountText.neutral(amount: 'ETB 4,200')
/// ```
class AppAmountText extends StatelessWidget {
  const AppAmountText({
    super.key,
    required this.amount,
    this.isPositive,
    this.currency = 'ETB',
    this.fontSize,
    this.showSign = false,
  });

  final String amount;

  /// null = neutral color, true = green, false = red
  final bool? isPositive;
  final String currency;
  final double? fontSize;
  final bool showSign;

  factory AppAmountText.neutral({required String amount, double? fontSize}) =>
      AppAmountText(amount: amount, isPositive: null, fontSize: fontSize);

  @override
  Widget build(BuildContext context) {
    final Color color;
    String display = amount;

    if (isPositive == null) {
      color = AppColors.textPrimary;
    } else if (isPositive == true) {
      color = Theme.of(context).colorScheme.secondary;
      if (showSign && !amount.startsWith('+')) display = '+ $amount';
    } else {
      color = Theme.of(context).colorScheme.error;
      if (showSign && !amount.startsWith('-')) display = '- $amount';
    }

    return Text(
      display,
      style: AppTextStyles.amountNeutral.copyWith(
        color: color,
        fontSize: fontSize,
      ),
    );
  }
}
