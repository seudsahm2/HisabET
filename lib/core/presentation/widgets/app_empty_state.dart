import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Standardized empty state.
/// Replaces 10+ duplicate "No items yet" widgets across the app.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.inventory_2_outlined,
///   title: 'No products yet',
///   subtitle: 'Add your first product to get started.',
///   actionLabel: 'Add Product',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  /// When true, renders a smaller inline version (for inside a card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact(context);
    return _full(context);
  }

  Widget _full(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xxxl,
          vertical: AppDimensions.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textHint).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor ?? AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(title, style: AppTextStyles.emptyTitle, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                subtitle!,
                style: AppTextStyles.emptySubtitle,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.xxl),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconLg, color: iconColor ?? AppColors.textHint),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.emptyTitle),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.emptySubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
