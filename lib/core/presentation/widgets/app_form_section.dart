import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/presentation/widgets/app_card.dart';
/// Groups form fields under a titled card section.
/// Replaces long flat columns of TextFields in all upsert screens.
///
/// Usage:
/// ```dart
/// AppFormSection(
///   title: 'Basic Info',
///   icon: Icons.info_outline,
///   children: [
///     TextField(decoration: InputDecoration(labelText: 'Name')),
///     SizedBox(height: 12),
///     TextField(decoration: InputDecoration(labelText: 'SKU')),
///   ],
/// )
/// ```
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.margin,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: margin ??
          const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.lg,
              AppDimensions.lg,
              AppDimensions.sm,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.primary.withOpacity(0.16)
                          : AppColors.primaryContainer.withOpacity(0.6),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXs),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          // Fields
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
