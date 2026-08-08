import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// A selectable option with a title, an explanation and a state indicator.
///
/// Replaces `CheckboxListTile` / `RadioListTile` in the places where the choice
/// carries meaning the user has to weigh — business roles, account types — as
/// opposed to a bare on/off toggle.
///
/// Two reasons it is not the Material tile:
///
/// - **It states its own colours.** The list-tile text styles in the shared
///   theme carry no colour, so a tile inherits whatever `DefaultTextStyle` is
///   in scope and can render invisibly on a white card. Every colour here is
///   resolved from the scheme at build time.
/// - **The whole row is the target, and it looks like one.** A checkbox tile
///   gives no boundary, so a column of them reads as loose text with boxes.
///   Here each option is a bounded surface whose border and fill change on
///   selection, which is legible in daylight on a cheap screen.
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.multi = true,
    this.margin,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool selected;

  /// `null` locks the option — shown quietly rather than removed, so the user
  /// can still read what was chosen for them.
  final VoidCallback? onTap;

  /// Square indicator for "any number of these", round for "exactly one".
  final bool multi;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final locked = onTap == null;

    final borderColor = selected ? accent : hairline;
    final fill = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.12 : 0.05),
            colorScheme.surface,
          )
        : colorScheme.surface;

    final titleColor = locked && !selected
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.09),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(color: titleColor),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          _Indicator(
            selected: selected,
            locked: locked,
            multi: multi,
            accent: accent,
            hairline: isDark ? AppColors.borderDark : AppColors.borderStrong,
          ),
        ],
      ),
    );

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: !locked,
        checked: selected,
        enabled: !locked,
        label: title,
        child: locked
            ? Opacity(opacity: 0.75, child: content)
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.selected,
    required this.locked,
    required this.multi,
    required this.accent,
    required this.hairline,
  });

  final bool selected;
  final bool locked;
  final bool multi;
  final Color accent;
  final Color hairline;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(
        selected ? Icons.check_circle_rounded : Icons.remove_rounded,
        size: 20,
        color: selected ? accent : hairline,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(multi ? 6 : 11),
        border: Border.all(
          color: selected ? accent : hairline,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 15,
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }
}
