import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

class AppMissionHeader extends StatelessWidget {
  const AppMissionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow = 'HISABET',
    this.trailing,
    this.padding,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.lg,
            AppDimensions.pagePaddingH,
            AppDimensions.sm,
          ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: colorScheme.outlineVariant),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withOpacity(isDark ? 0.20 : 0.35),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.18 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppDimensions.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}