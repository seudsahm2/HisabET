import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon, this.count});

  final T value;
  final String label;
  final IconData? icon;

  /// Optional figure shown after the label, e.g. number of results.
  final int? count;
}

/// Two or three mutually exclusive views of the same thing ("Your contacts" /
/// "Find on HisabET"), always visible — unlike a menu, the current scope can
/// never be mistaken.
///
/// A hairline track with a solid brand thumb on the selected segment. The
/// thumb slides; segments never resize, so labels don't jump.
class AppSegmentedTabs<T> extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final index = segments.indexWhere((s) => s.value == selected).clamp(0, segments.length - 1);

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm + 2),
        border: Border.all(color: hairline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: segment.value == selected,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          onTap: () => onChanged(segment.value),
                          child: _SegmentLabel(segment: segment, selected: segment.value == selected),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({required this.segment, required this.selected});
  final AppSegment<T> segment;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (segment.icon != null) ...[
          Icon(segment.icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            segment.label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.badgeLabel.copyWith(fontSize: 13, color: color, fontWeight: FontWeight.w700),
          ),
        ),
        if (segment.count != null) ...[
          const SizedBox(width: 6),
          Text(
            '${segment.count}',
            style: AppTextStyles.badgeLabel.copyWith(
              fontSize: 12,
              color: color.withValues(alpha: 0.75),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
