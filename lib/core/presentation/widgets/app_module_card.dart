import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// A module card for the Business Hub.
/// Two variants: [AppModuleCard.priority] (large) and [AppModuleCard.compact] (small).
///
/// Completely decoupled — receives module data and callback only.
///
/// Usage:
/// ```dart
/// AppModuleCard.priority(
///   title: 'Sales',
///   subtitle: 'Today: ETB 4,200',
///   icon: Icons.point_of_sale,
///   color: AppColors.moduleSales,
///   onTap: () => Navigator.push(...),
/// )
/// ```
class AppModuleCard extends StatelessWidget {
  const AppModuleCard._({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.size,
    this.badge,
  });

  /// Large card for Daily Operations section.
  factory AppModuleCard.priority({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    AppStatusBadgeData? badge,
  }) =>
      AppModuleCard._(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: onTap,
        size: _CardSize.priority,
        badge: badge,
      );

  /// Compact card for Finance / Growth sections.
  factory AppModuleCard.compact({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    AppStatusBadgeData? badge,
  }) =>
      AppModuleCard._(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        onTap: onTap,
        size: _CardSize.compact,
        badge: badge,
      );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final _CardSize size;
  final AppStatusBadgeData? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              size == _CardSize.priority
                  ? AppDimensions.lg
                  : AppDimensions.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: size == _CardSize.priority ? 40 : 32,
                      height: size == _CardSize.priority ? 40 : 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: size == _CardSize.priority
                            ? AppDimensions.iconMd
                            : AppDimensions.iconSm,
                      ),
                    ),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badge!.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          badge!.label,
                          style: AppTextStyles.badgeLabel.copyWith(
                            color: badge!.color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ],
                ),
                SizedBox(
                  height: size == _CardSize.priority
                      ? AppDimensions.md
                      : AppDimensions.sm,
                ),
                Text(
                  title,
                  style: AppTextStyles.moduleTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.moduleStat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CardSize { priority, compact }

/// Simple data class for module card badge.
class AppStatusBadgeData {
  const AppStatusBadgeData({required this.label, required this.color});
  final String label;
  final Color color;
}
