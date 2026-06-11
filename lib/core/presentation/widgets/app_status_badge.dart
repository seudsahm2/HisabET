import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Semantic status badge / pill.
/// Replaces manual colored Container + Text patterns everywhere.
///
/// Usage:
/// ```dart
/// AppStatusBadge.success(label: 'In Stock')
/// AppStatusBadge.danger(label: 'Low Stock')
/// AppStatusBadge(label: 'Pending', color: AppColors.warning)
/// ```
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  // ── Named constructors ────────────────────────────────────────────────────
  factory AppStatusBadge.success({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.positive, icon: icon, small: small);

  factory AppStatusBadge.danger({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.negative, icon: icon, small: small);

  factory AppStatusBadge.warning({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.warning, icon: icon, small: small);

  factory AppStatusBadge.info({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.info, icon: icon, small: small);

  factory AppStatusBadge.neutral({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.neutral500, icon: icon, small: small);

  factory AppStatusBadge.primary({required String label, IconData? icon, bool small = false}) =>
      AppStatusBadge(label: label, color: AppColors.primary, icon: icon, small: small);

  /// Resolves a status string to the appropriate badge variant.
  /// Supports: 'active', 'inactive', 'pending', 'processing', 'delivered',
  ///           'completed', 'cancelled', 'low stock', 'in stock', 'paid', 'unpaid'
  factory AppStatusBadge.fromStatus(String status) {
    final s = status.toLowerCase().trim();
    return switch (s) {
      'active' || 'in stock' || 'delivered' || 'completed' || 'paid' =>
        AppStatusBadge.success(label: status),
      'inactive' || 'cancelled' || 'unpaid' || 'low stock' =>
        AppStatusBadge.danger(label: status),
      'pending' || 'partial' =>
        AppStatusBadge.warning(label: status),
      'processing' || 'scheduled' =>
        AppStatusBadge.info(label: status),
      _ => AppStatusBadge.neutral(label: status),
    };
  }

  @override
  Widget build(BuildContext context) {
    Color effectiveColor = color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (color == AppColors.positive) {
      effectiveColor = Theme.of(context).colorScheme.secondary;
    } else if (color == AppColors.negative) {
      effectiveColor = Theme.of(context).colorScheme.error;
    } else if (color == AppColors.info && isDark) {
      effectiveColor = AppColors.infoMid; // Brighten info color in dark mode
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppDimensions.sm : AppDimensions.md,
        vertical: small ? 2 : AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.badgeLabel.copyWith(
              color: effectiveColor,
              fontSize: small ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
