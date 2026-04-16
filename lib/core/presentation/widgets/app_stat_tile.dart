import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// A single stat display: icon, value, and label.
/// Used in summary strips at the top of list screens.
///
/// Usage:
/// ```dart
/// AppStatTile(
///   icon: Icons.inventory_2,
///   label: 'Products',
///   value: '142',
///   color: AppColors.primary,
/// )
/// ```
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.flex = 1,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final int flex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.avatarSm,
                height: AppDimensions.avatarSm,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, size: AppDimensions.iconSm, color: c),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.statValue.copyWith(
                        fontSize: 18,
                        color: c,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(label, style: AppTextStyles.statLabel),
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

/// A horizontal row of [AppStatTile] widgets with consistent gap.
/// Wrap your stat tiles in this for clean, responsive summary strips.
///
/// Usage:
/// ```dart
/// AppStatRow(
///   children: [
///     AppStatTile(icon: Icons.inventory_2, label: 'Products', value: '42', color: AppColors.primary),
///     AppStatTile(icon: Icons.warning_amber, label: 'Low Stock', value: '3', color: AppColors.warning),
///   ],
/// )
/// ```
class AppStatRow extends StatelessWidget {
  const AppStatRow({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.sm,
          ),
      child: Row(
        children: children
            .expand((w) => [w, const SizedBox(width: AppDimensions.md)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}
