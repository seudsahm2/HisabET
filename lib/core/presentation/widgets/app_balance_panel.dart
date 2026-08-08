import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:hisabet/core/presentation/widgets/app_money.dart';
import 'package:hisabet/core/theme/theme.dart';

/// The primary balance statement.
///
/// ## Why this replaced the gradient hero card
///
/// The old version was a saturated gradient rectangle with a giant watermark
/// icon behind white text — the single most recognisable "generated dashboard"
/// component there is. It also actively harmed the product: a gradient behind
/// a number reduces contrast, and this app is used outdoors in Merkato.
///
/// What a bank actually shows you at the top of an account is quieter and more
/// confident: a small label, one large number in tabular figures, and the
/// split beneath it separated by a rule. The restraint *is* the professionalism
/// — the number is important, so nothing competes with it.
class AppBalancePanel extends StatelessWidget {
  const AppBalancePanel({
    super.key,
    required this.label,
    required this.netBalance,
    required this.receivable,
    required this.payable,
    this.receivableLabel = 'To collect',
    this.payableLabel = 'To pay',
    this.footnote,
    this.onTap,
  });

  final String label;
  final Decimal netBalance;
  final Decimal receivable;
  final Decimal payable;
  final String receivableLabel;
  final String payableLabel;
  final String? footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final isNegative = netBalance < Decimal.zero;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.lg,
                  AppDimensions.lg,
                  AppDimensions.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppTextStyles.sectionLabel.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    AppMoney(
                      amount: netBalance,
                      size: AppMoneySize.hero,
                      // Sign colour only when in the red: a healthy book should
                      // read as calm and neutral, not as a wall of green.
                      tone: isNegative
                          ? AppColors.negative
                          : colorScheme.onSurface,
                    ),
                    if (footnote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        footnote!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: hairline),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _SplitCell(
                        label: receivableLabel,
                        amount: receivable,
                        tone: AppColors.positive,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: hairline),
                    Expanded(
                      child: _SplitCell(
                        label: payableLabel,
                        amount: payable < Decimal.zero ? -payable : payable,
                        tone: AppColors.negative,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitCell extends StatelessWidget {
  const _SplitCell({
    required this.label,
    required this.amount,
    required this.tone,
    required this.icon,
  });

  final String label;
  final Decimal amount;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: tone),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AppMoney(
            amount: amount,
            size: AppMoneySize.large,
            showCurrency: false,
            tone: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
