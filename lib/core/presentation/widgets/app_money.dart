import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/theme/theme.dart';

/// How prominent a money value is on screen.
enum AppMoneySize { hero, large, medium, small }

/// Renders a monetary amount the way financial software does.
///
/// Three things this gets right that ad-hoc `Text('ETB $amount')` does not:
///
/// 1. **Tabular figures.** Digits share a fixed advance width, so a balance
///    does not jitter as it updates and stacked amounts align on the decimal.
///    This is the clearest visual signal that a product handles real money.
/// 2. **Grouped thousands.** `348,900` not `348900`. At the scale these
///    traders work — six-figure carton deals — unseparated digits are
///    genuinely misread.
/// 3. **Direction is never colour alone.** A `+`/`−` glyph always accompanies
///    the green/red, satisfying the `color-not-only` accessibility rule for
///    colour-blind users and for bright-sunlight readability.
///
/// The currency mark is rendered small and muted so the digits stay dominant.
class AppMoney extends StatelessWidget {
  const AppMoney({
    super.key,
    required this.amount,
    this.size = AppMoneySize.medium,
    this.currency = 'ETB',
    this.showCurrency = true,
    this.signed = false,
    this.tone,
    this.color,
  });

  /// Convenience for a value whose colour should follow its sign.
  const AppMoney.directional({
    super.key,
    required this.amount,
    this.size = AppMoneySize.medium,
    this.currency = 'ETB',
    this.showCurrency = true,
    this.color,
  })  : signed = true,
        tone = null;

  final Decimal amount;
  final AppMoneySize size;
  final String currency;
  final bool showCurrency;

  /// When true, prefixes `+` or `−` and colours by sign.
  final bool signed;

  /// Explicit semantic tone; overrides sign-based colouring.
  final Color? tone;

  /// Hard colour override — wins over everything. Use on dark surfaces.
  final Color? color;

  static final NumberFormat _format = NumberFormat('#,##0.##');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNegative = amount < Decimal.zero;
    final magnitude = isNegative ? -amount : amount;

    final resolved = color ??
        tone ??
        (signed
            ? (isNegative ? AppColors.negative : AppColors.positive)
            : colorScheme.onSurface);

    final textStyle = switch (size) {
      AppMoneySize.hero => AppTextStyles.moneyHero,
      AppMoneySize.large => AppTextStyles.moneyLarge,
      AppMoneySize.medium => AppTextStyles.moneyMedium,
      AppMoneySize.small => AppTextStyles.moneySmall,
    }
        .copyWith(color: resolved);

    final markStyle = AppTextStyles.currencyMark.copyWith(
      color: color?.withValues(alpha: 0.7) ??
          (size == AppMoneySize.hero
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurfaceVariant),
      fontSize: switch (size) {
        AppMoneySize.hero => 14,
        AppMoneySize.large => 12,
        _ => 11,
      },
    );

    // Using the true minus sign (U+2212) rather than a hyphen: it is the same
    // width as a digit in tabular figures, so columns stay aligned.
    final prefix = signed ? (isNegative ? '−' : '+') : (isNegative ? '−' : '');
    final digits = _format.format(double.parse(magnitude.toString()));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (showCurrency) ...[
          Text(currency, style: markStyle),
          SizedBox(width: size == AppMoneySize.hero ? 6 : 4),
        ],
        Flexible(
          child: Text(
            '$prefix$digits',
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
