import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// One destination in [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
}

/// Primary navigation.
///
/// ## What was wrong with the previous bar
///
/// It was a floating rounded pill inset 24pt from every edge, and the selected
/// item *grew* to reveal its label while the others showed a bare icon. Four
/// separate problems:
///
/// - **Labels appeared and disappeared.** Every tap re-laid-out the whole bar,
///   so destinations physically moved under the user's finger. Navigation is
///   the one surface that must never shift.
/// - **Icon-only inactive items.** An unlabelled icon is a guess. Material's
///   guidance is explicit that bottom-nav items carry icon *and* label.
/// - **A floating island wastes the edge.** Anchoring to the bottom edge gives
///   wider targets and matches the platform, on Android and iOS alike.
/// - **`GestureDetector` gave no press feedback**, so taps felt dead.
///
/// This version is anchored full-width, separated from content by a hairline,
/// with permanent labels and a fixed layout. Selection is expressed by a pill
/// behind the icon — Material 3's own indicator — which animates colour only,
/// so nothing moves.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.hairlineDark : AppColors.hairline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavCell(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final active = isDark ? AppColors.primaryBright : AppColors.primary;
    final inactive = colorScheme.onSurfaceVariant;
    final tone = selected ? active : inactive;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        // Ripple confined to the cell rather than bleeding across the bar.
        splashColor: active.withValues(alpha: 0.10),
        highlightColor: active.withValues(alpha: 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Only the colour animates — the box never changes size, so
                // neighbouring destinations cannot move.
                color: selected
                    ? active.withValues(alpha: isDark ? 0.20 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: _IconWithBadge(
                icon: selected ? item.activeIcon : item.icon,
                color: tone,
                badge: item.badge,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: tone,
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final showBadge = badge != null && badge! > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 23, color: color),
        if (showBadge)
          Positioned(
            right: -7,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 15),
              decoration: BoxDecoration(
                color: AppColors.negative,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: AppTextStyles.badgeLabel.copyWith(
                  color: Colors.white,
                  fontSize: 9.5,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
