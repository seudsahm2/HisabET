import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:hisabet/core/presentation/widgets/app_money.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Surface treatment for [AppBalancePanel].
enum AppBalanceVariant {
  /// Solid deep-brand panel. The single dark element on the screen.
  anchor,

  /// Light surface with a hairline, matching ordinary cards. For secondary
  /// balances that must not compete with the screen's primary figure.
  plain,
}

/// The primary balance statement.
///
/// ## Why this is one dark panel
///
/// It replaced a gradient hero card with a watermark icon — the most
/// recognisable "generated dashboard" component there is, and one that also
/// hurt legibility, since a gradient behind a number destroys contrast and this
/// app is used outdoors in Merkato.
///
/// The first replacement went too far the other way: a pure white panel, which
/// gave the most important number on the screen exactly the same visual weight
/// as the action strip and the transaction list. Three identical white boxes,
/// no hierarchy.
///
/// So: **one flat, solid, deep-brand anchor at the top, everything below it
/// light.** This is the Mercury / Ramp / Apple Wallet pattern. The colour is
/// structural — it marks the screen's centre of gravity — rather than
/// decorative. The distinction from what we removed is that this is a *flat
/// fill*: no gradient, no blur, no watermark, no shadow.
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
    this.variant = AppBalanceVariant.anchor,
  });

  final String label;
  final Decimal netBalance;
  final Decimal receivable;
  final Decimal payable;
  final String receivableLabel;
  final String payableLabel;
  final String? footnote;
  final VoidCallback? onTap;
  final AppBalanceVariant variant;

  bool get _isAnchor => variant == AppBalanceVariant.anchor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNegative = netBalance < Decimal.zero;

    // In dark mode the deep teal sits too close to the near-black ground, so
    // the panel lifts to the lighter brand step to stay distinct.
    final anchorFill = isDark ? AppColors.primaryLight : AppColors.primary;

    final background = _isAnchor ? anchorFill : colorScheme.surface;
    final rule = _isAnchor
        ? Colors.white.withValues(alpha: 0.16)
        : (isDark ? AppColors.hairlineDark : AppColors.hairline);

    final labelColor = _isAnchor
        ? Colors.white.withValues(alpha: 0.72)
        : colorScheme.onSurfaceVariant;

    // Headline stays white on the anchor so it never fights the surface; it
    // turns to the light red only when the book is actually in the red, which
    // is information rather than decoration.
    final headlineColor = _isAnchor
        ? (isNegative ? AppColors.negativeOnDark : Colors.white)
        : (isNegative ? AppColors.negative : colorScheme.onSurface);

    final positiveTone =
        _isAnchor ? AppColors.positiveOnDark : AppColors.positive;
    final negativeTone =
        _isAnchor ? AppColors.negativeOnDark : AppColors.negative;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: _isAnchor ? null : Border.all(color: rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: _isAnchor ? Colors.white.withValues(alpha: 0.06) : null,
          highlightColor:
              _isAnchor ? Colors.white.withValues(alpha: 0.04) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style:
                          AppTextStyles.sectionLabel.copyWith(color: labelColor),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    AppMoney(
                      amount: netBalance,
                      size: AppMoneySize.hero,
                      color: headlineColor,
                    ),
                    if (footnote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        footnote!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _isAnchor
                              ? Colors.white.withValues(alpha: 0.64)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: rule),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _SplitCell(
                        label: receivableLabel,
                        amount: receivable,
                        tone: positiveTone,
                        labelColor: labelColor,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: rule),
                    Expanded(
                      child: _SplitCell(
                        label: payableLabel,
                        amount: payable < Decimal.zero ? -payable : payable,
                        tone: negativeTone,
                        labelColor: labelColor,
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
    required this.labelColor,
    required this.icon,
  });

  final String label;
  final Decimal amount;
  final Color tone;
  final Color labelColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(color: labelColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AppMoney(
            amount: amount,
            size: AppMoneySize.large,
            showCurrency: false,
            color: tone,
          ),
        ],
      ),
    );
  }
}
