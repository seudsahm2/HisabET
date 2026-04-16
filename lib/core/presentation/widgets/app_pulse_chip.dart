import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// A single Live Pulse chip — a mini alert / stat indicator.
/// Used in the Business Hub's "pulse bar" to show real-time business health.
///
/// Usage:
/// ```dart
/// AppPulseChip(
///   icon: Icons.warning_amber_rounded,
///   label: '3 low stock',
///   color: AppColors.warning,
///   onTap: () => Navigator.push(...),
/// )
/// ```
class AppPulseChip extends StatelessWidget {
  const AppPulseChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs + 2,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.badgeLabel.copyWith(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable row of [AppPulseChip]s.
/// Use in the Business Hub header for live business health indicators.
class AppPulseBar extends StatelessWidget {
  const AppPulseBar({
    super.key,
    required this.chips,
    this.padding,
  });

  final List<AppPulseChip> chips;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
        itemCount: chips.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.sm),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}
