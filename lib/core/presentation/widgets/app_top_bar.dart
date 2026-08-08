import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// The standard page header, used at the top of every screen.
///
/// ## Why it is not a card
///
/// The previous header was a tinted glass card floating on the page. That is
/// wrong twice over: a header is not an object you act on, so boxing it adds a
/// container with no meaning; and once the header is a card sitting above other
/// cards, the page becomes a stack of same-weight boxes with no entry point.
///
/// A header in professional software sits **directly on the page ground**. Its
/// authority comes from typography — a quiet uppercase eyebrow, then a large
/// title — not from a border. That also makes the eye land on the title first,
/// which is the whole job of a header.
///
/// One component covers both shapes so headers cannot drift apart across
/// screens: [AppTopBar] for a page, [AppTopBar.greeting] for the dashboard.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.leading,
    this.actions,
    this.padding,
    this.dense = false,
  });

  /// Dashboard variant: `GOOD MORNING` over the business name, with the
  /// profile avatar as the trailing action.
  ///
  /// It is the same layout as a page header — the greeting is the eyebrow and
  /// the name is the title — so the top of the app stays visually identical as
  /// the user moves between tabs.
  factory AppTopBar.greeting({
    Key? key,
    required String greeting,
    required String name,
    ImageProvider? avatar,
    VoidCallback? onAvatarTap,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
  }) {
    return AppTopBar(
      key: key,
      eyebrow: greeting,
      title: name,
      padding: padding,
      actions: [
        ...?actions,
        AppAvatarButton(
          name: name,
          image: avatar,
          onTap: onAvatarTap,
        ),
      ],
    );
  }

  final String title;
  final String? eyebrow;
  final String? subtitle;

  /// Usually a back button. Omit it when the framework already supplies one.
  final Widget? leading;

  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  /// Tightens vertical padding for screens that follow immediately with a
  /// scrolling list.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            dense ? AppDimensions.md : AppDimensions.lg,
            AppDimensions.pagePaddingH,
            dense ? AppDimensions.md : AppDimensions.lg,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppDimensions.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: AppDimensions.md),
            Row(mainAxisSize: MainAxisSize.min, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// Circular avatar with an initial fallback, sized to a valid touch target.
class AppAvatarButton extends StatelessWidget {
  const AppAvatarButton({
    super.key,
    required this.name,
    this.image,
    this.onTap,
    this.radius = 21,
  });

  final String name;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return Semantics(
      button: onTap != null,
      label: 'Profile',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          // Pads a 42pt avatar out to a 48pt hit area without changing how it
          // looks.
          padding: const EdgeInsets.all(3),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundImage: image,
            // Without a handler a failed download becomes an unhandled
            // exception on every build — Firebase Storage returns 402 when the
            // project has no billing, so the avatar fails on every launch. The
            // initial underneath is a perfectly good fallback; it should just
            // show, quietly.
            onForegroundImageError: image == null ? null : (_, __) {},
            child: Text(
              initial,
              style: AppTextStyles.cardTitle.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon action for [AppTopBar.actions], with a guaranteed 44pt target.
class AppTopBarAction extends StatelessWidget {
  const AppTopBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showBadge = badge != null && badge! > 0;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    size: AppDimensions.iconMd,
                    color: colorScheme.onSurfaceVariant),
                if (showBadge)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 15),
                      decoration: BoxDecoration(
                        color: AppColors.negative,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
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
          ),
        ),
      ),
    );
  }
}
