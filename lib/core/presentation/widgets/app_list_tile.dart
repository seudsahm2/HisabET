import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/presentation/widgets/app_card.dart';
/// Enhanced list tile inside an [AppCard].
/// Replaces the `ListTile inside Container` pattern used everywhere.
/// Fully decoupled — pass any leading/trailing widgets.
///
/// Usage:
/// ```dart
/// AppListTile(
///   leadingIcon: Icons.inventory_2,
///   leadingColor: AppColors.primary,
///   title: 'Product Name',
///   subtitle: 'SKU: ABC123 · In Stock',
///   trailing: AppStatusBadge.success(label: 'In Stock'),
///   onTap: () {},
/// )
/// ```
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    this.leadingIcon,
    this.leadingColor,
    this.leadingText,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.showDivider = false,
  });

  /// Custom leading widget — takes priority over [leadingIcon].
  final Widget? leading;

  /// Icon to show inside a rounded square container.
  final IconData? leadingIcon;

  /// Color for the leading icon container.
  final Color? leadingColor;

  /// Short text to show in the leading avatar (e.g. initials).
  final String? leadingText;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin ??
          const EdgeInsets.only(bottom: AppDimensions.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLeading(context),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: _buildContent()),
            if (trailing != null) ...[
              const SizedBox(width: AppDimensions.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;

    final color = leadingColor ?? AppColors.primary;

    if (leadingText != null) {
      return Container(
        width: AppDimensions.avatarMd,
        height: AppDimensions.avatarMd,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        alignment: Alignment.center,
        child: Text(
          leadingText!.isNotEmpty
              ? leadingText![0].toUpperCase()
              : '?',
          style: AppTextStyles.cardTitle.copyWith(color: color),
        ),
      );
    }

    if (leadingIcon != null) {
      return Container(
        width: AppDimensions.avatarMd,
        height: AppDimensions.avatarMd,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        alignment: Alignment.center,
        child: Icon(leadingIcon, color: color, size: AppDimensions.iconMd),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.cardSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
