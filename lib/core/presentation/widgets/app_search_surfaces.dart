import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

enum AppSearchSurfaceVariant { monochrome, glass, enterpriseDense }

class AppLocalSearchSurface extends StatelessWidget {
  const AppLocalSearchSurface({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.title = 'Search Your Contacts',
    this.subtitle = 'Local ledger only',
    this.variant = AppSearchSurfaceVariant.glass,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final String title;
  final String subtitle;
  final AppSearchSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isGlass = variant == AppSearchSurfaceVariant.glass;
    final isDense = variant == AppSearchSurfaceVariant.enterpriseDense;
    final containerPadding = isDense
        ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
        : const EdgeInsets.fromLTRB(
            AppDimensions.sm,
            AppDimensions.sm,
            AppDimensions.sm,
            AppDimensions.xs,
          );

    final decoration = switch (variant) {
      AppSearchSurfaceVariant.monochrome => BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
      AppSearchSurfaceVariant.glass => BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withOpacity(0.90),
              colorScheme.primaryContainer.withOpacity(0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      AppSearchSurfaceVariant.enterpriseDense => BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.38),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
    };

    return Container(
      padding: containerPadding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: isDense ? 4 : 6, bottom: isDense ? 4 : 6),
            child: Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isDense ? 10 : 11,
              ),
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: isDense ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: '$title...',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: isDense ? 18 : 20,
                color: isGlass ? colorScheme.primary : null,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppGlobalSearchSurface extends StatelessWidget {
  const AppGlobalSearchSurface({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.icon = Icons.travel_explore_rounded,
    this.variant = AppSearchSurfaceVariant.glass,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final IconData icon;
  final AppSearchSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isMonochrome = variant == AppSearchSurfaceVariant.monochrome;
    final isDense = variant == AppSearchSurfaceVariant.enterpriseDense;

    final decoration = switch (variant) {
      AppSearchSurfaceVariant.monochrome => BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
      AppSearchSurfaceVariant.glass => BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withOpacity(0.88),
              colorScheme.primaryContainer.withOpacity(0.24),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
      AppSearchSurfaceVariant.enterpriseDense => BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? AppDimensions.xs : AppDimensions.sm,
        vertical: isDense ? 4 : AppDimensions.xs,
      ),
      decoration: decoration,
      child: Row(
        children: [
          Icon(icon, size: isDense ? 16 : 18, color: colorScheme.primary),
          SizedBox(width: isDense ? AppDimensions.xs : AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.badgeLabel.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: isDense ? 11 : 12,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isDense ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
          if (isMonochrome)
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.north_east_rounded, size: 16),
              label: Text(actionLabel),
            )
          else
            FilledButton.tonalIcon(
              onPressed: onTap,
              icon: const Icon(Icons.north_east_rounded, size: 16),
              label: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}