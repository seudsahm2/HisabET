import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// One row of a grouped list: consecutive rows join into a single
/// hairline-bordered surface, rounded only at the group's ends.
///
/// This is the sliver-friendly counterpart of `AppLedgerGroup` — each row
/// draws its own slice of the group, so long lists can be built lazily with
/// `SliverList.builder` instead of laying out every row up front. Per the
/// design system: rows on one surface with hairlines, never a card per item.
class AppGroupedRow extends StatelessWidget {
  const AppGroupedRow({
    super.key,
    required this.child,
    required this.isFirst,
    required this.isLast,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;
    const radius = Radius.circular(AppDimensions.radiusMd);
    final shape = BorderRadius.vertical(
      top: isFirst ? radius : Radius.zero,
      bottom: isLast ? radius : Radius.zero,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: shape,
        border: Border(
          left: BorderSide(color: hairline),
          right: BorderSide(color: hairline),
          top: isFirst ? BorderSide(color: hairline) : BorderSide.none,
          bottom: BorderSide(color: hairline),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Square initial avatar used in grouped rows. [verified] fills it with the
/// brand colour and adds a small check — the visual for "has a HisabET
/// account" everywhere contacts are listed.
class AppInitialAvatar extends StatelessWidget {
  const AppInitialAvatar({super.key, required this.name, this.verified = false, this.size = 40});

  final String name;
  final bool verified;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '#' : trimmed.characters.first.toUpperCase();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: verified ? AppColors.primary : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              initial,
              style: AppTextStyles.cardTitle.copyWith(
                color: verified ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (verified)
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded, size: 14, color: isDark ? AppColors.primaryBright : AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "HisabET" tag: this person has a verified account.
class AppHisabetBadge extends StatelessWidget {
  const AppHisabetBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = isDark ? AppColors.primaryBright : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 11, color: tone),
          const SizedBox(width: 3),
          Text('HisabET', style: AppTextStyles.badgeLabel.copyWith(fontSize: 10.5, color: tone)),
        ],
      ),
    );
  }
}
