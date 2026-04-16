import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Gradient hero card — the premium teal banner pattern.
/// Used for: Home Dashboard balance card, Business Hub header, Cashbook header.
///
/// Usage:
/// ```dart
/// AppGradientCard(
///   label: 'TOTAL NET BALANCE',
///   value: 'ETB 48,200',
///   children: [_MiniStatRow(...)],
/// )
/// ```
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.label,
    required this.value,
    this.sublabel,
    this.children = const [],
    this.beginColor = AppColors.primaryDark,
    this.endColor = AppColors.primary,
    this.trailing,
    this.height,
    this.backgroundIcon,
  });

  final String label;
  final String value;
  final String? sublabel;
  final List<Widget> children;
  final Color beginColor;
  final Color endColor;
  final Widget? trailing;
  final double? height;
  final IconData? backgroundIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        gradient: LinearGradient(
          colors: [beginColor, endColor],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: endColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative icon
          if (backgroundIcon != null)
            Positioned(
              right: -24,
              top: -24,
              child: Icon(
                backgroundIcon,
                size: 180,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppDimensions.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label.toUpperCase(), style: AppTextStyles.onDarkLabel),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(value, style: AppTextStyles.heroAmount),
                if (sublabel != null) ...[
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    sublabel!,
                    style: AppTextStyles.onDarkLabel.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (children.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.lg),
                  ...children,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A mini 2-column stat row for use inside [AppGradientCard].
/// Displays two stats side by side with a divider.
class AppGradientCardStatRow extends StatelessWidget {
  const AppGradientCardStatRow({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.leftValueColor = Colors.greenAccent,
    this.rightValueColor,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Color leftValueColor;
  final Color? rightValueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: leftLabel,
              value: leftValue,
              valueColor: leftValueColor,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _MiniStat(
              label: rightLabel,
              value: rightValue,
              valueColor: rightValueColor ?? Colors.redAccent.shade100,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.onDarkLabel),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.onDarkValue.copyWith(color: valueColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
