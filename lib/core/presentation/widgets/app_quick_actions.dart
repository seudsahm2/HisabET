import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// One entry in an [AppQuickActions] bar.
class AppQuickAction {
  const AppQuickAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.tone,
    this.badge,
  });

  final IconData icon;
  final String label;

  /// `null` disables the action — it renders muted and is not tappable.
  final VoidCallback? onTap;

  /// Accent for the icon. Defaults to the brand colour.
  final Color? tone;

  /// Small count shown on the icon (e.g. pending items).
  final int? badge;

  bool get isEnabled => onTap != null;
}

/// A row of shortcuts on a single surface, divided by hairlines.
///
/// ## Why one surface instead of four cards
///
/// The previous design gave each shortcut its own elevated, rounded rectangle.
/// Four floating boxes in a row read as four unrelated things, they force
/// gutters that break the page's vertical rhythm, and — because each box had
/// its own shadow and gradient — they competed with the balance above them.
///
/// Grouping them into one bordered surface says what is actually true: these
/// are peers, one control strip. It is also how the action row in a banking
/// app is built.
///
/// Each cell keeps a ≥44pt touch target and disabled entries are visibly
/// muted rather than silently inert.
class AppQuickActions extends StatelessWidget {
  const AppQuickActions({
    super.key,
    required this.actions,
    this.margin,
  });

  final List<AppQuickAction> actions;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;

    final cells = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      cells.add(Expanded(child: _Cell(action: actions[i])));
      if (i != actions.length - 1) {
        cells.add(VerticalDivider(width: 1, thickness: 1, color: hairline));
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.action});

  final AppQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = action.isEnabled;
    final tone = action.tone ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.primaryBright
            : AppColors.primary);

    final iconColor = enabled ? tone : colorScheme.onSurfaceVariant;
    final labelColor =
        enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.md,
                horizontal: AppDimensions.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconWithBadge(
                    icon: action.icon,
                    color: iconColor,
                    badge: action.badge,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 21, color: color),
          if (showBadge)
            Positioned(
              right: -7,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 15),
                decoration: BoxDecoration(
                  color: AppColors.negative,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
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
      ),
    );
  }
}
