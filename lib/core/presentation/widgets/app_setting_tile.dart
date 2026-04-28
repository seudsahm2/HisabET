import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

class AppSettingTile extends StatelessWidget {
  const AppSettingTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? AppColors.primary;
    final resolvedTitleColor = titleColor ?? colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: resolvedIconColor.withOpacity(isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: resolvedIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: resolvedTitleColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: subtitleColor,
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: subtitleColor),
      onTap: onTap,
    );
  }
}