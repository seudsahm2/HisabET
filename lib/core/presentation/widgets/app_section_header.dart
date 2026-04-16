import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Section heading with optional action button.
/// Replaces all inline `Row(Text, TextButton)` section headers.
///
/// Usage:
/// ```dart
/// AppSectionHeader(
///   title: 'Recent Activity',
///   actionLabel: 'See All',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.uppercase = true,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.lg,
            AppDimensions.pagePaddingH,
            AppDimensions.sm,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            uppercase ? title.toUpperCase() : title,
            style: AppTextStyles.sectionLabel,
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.badgeLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
