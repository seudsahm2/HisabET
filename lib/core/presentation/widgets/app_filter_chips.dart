import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// A horizontal scrollable row of filter chips.
/// Used in Orders, Expenses, Purchases, Sales History for status filtering.
///
/// [T] — the enum or any comparable type for filter state.
///
/// Usage:
/// ```dart
/// AppFilterChips<OrderStatus>(
///   options: OrderStatus.values,
///   selected: _filter,
///   labelBuilder: (s) => s.name,
///   onSelected: (next) => setState(() => _filter = next),
/// )
/// ```
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

  /// Optional — show a count badge next to the label.
  final int Function(T)? countBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.xs,
            ),
        itemCount: options.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, i) {
          final option = options[i];
          final isSelected = option == selected;
          final count = countBuilder?.call(option);

          return FilterChip(
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            backgroundColor: AppColors.surfaceVariant,
            selectedColor: AppColors.primaryContainer,
            checkmarkColor: AppColors.primary,
            side: BorderSide.none,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labelBuilder(option),
                  style: AppTextStyles.badgeLabel.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.neutral400,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
          );
        },
      ),
    );
  }
}
