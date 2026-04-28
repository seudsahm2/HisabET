import 'package:flutter/material.dart';

import 'package:hisabet/core/presentation/widgets/app_glass.dart';
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
        decoration: AppGlass.surface(
          context,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          tintColor: colorScheme.primaryContainer,
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