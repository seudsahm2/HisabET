import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// A horizontally scrolling row of filters.
/// Used in Contacts, Orders, Expenses, Cashbook, Team, Sales History.
///
/// [T] — the enum or any comparable type for filter state.
///
/// ## Why this is not a Material `FilterChip` any more
///
/// `FilterChip` carries its own density, tap-target padding and a checkmark
/// slot, which made every rail 44pt tall with chips that were mostly padding.
/// A filter is secondary navigation — it should cost as little vertical space
/// as it can while staying tappable, because the list underneath is the thing
/// the user came for.
///
/// So: 30pt pills in a 36pt rail. The unselected state is a bare hairline
/// outline with no fill — five chips no longer read as five buttons — and the
/// selected one is a solid brand fill, the strongest contrast available, so the
/// active filter is obvious at a glance instead of being a slightly different
/// grey. Counts are plain numerals beside the label rather than a second badge
/// inside the chip, which is what made the old rail look crowded.
///
/// The pill keeps a fixed height in both states; only colour changes, so the
/// rail never re-lays-out under the user's finger.
class AppFilterChips<T> extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.padding,
    this.countBuilder,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry? padding;

  /// Optional — show a count beside the label.
  final int Function(T)? countBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: 3,
            ),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final option = options[i];
          return AppFilterChip(
            label: labelBuilder(option),
            count: countBuilder?.call(option),
            selected: option == selected,
            onTap: () => onSelected(option),
          );
        },
      ),
    );
  }
}

/// A single pill from [AppFilterChips]. Exposed for rails that are built by
/// hand rather than from a list of options.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = isDark ? AppColors.primaryBright : AppColors.primary;
    final onFill = isDark ? AppColors.neutral900 : AppColors.textOnPrimary;
    final labelColor = selected ? onFill : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? fill : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? fill
                : (isDark ? AppColors.hairlineDark : AppColors.border),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12.5,
                    height: 1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12.5,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      fontFeatures: AppTextStyles.tabularFeatures,
                      color: labelColor.withValues(alpha: selected ? 0.72 : 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
