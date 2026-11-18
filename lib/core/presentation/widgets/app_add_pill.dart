import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

enum AppAddPillState { idle, busy, done }

/// The one-tap "Save" / "Add" control in a list row.
///
/// A tonal pill in the brand wash: clearly tappable, clearly secondary to the
/// name beside it. All three states share one box, so the row never resizes
/// while the write is in flight or after it lands. The visible pill is 34pt;
/// padding brings the hit target to 44pt.
class AppAddPill extends StatelessWidget {
  const AppAddPill({
    super.key,
    required this.state,
    required this.onTap,
    this.label = 'Save',
    this.doneLabel = 'Saved',
  });

  final AppAddPillState state;
  final VoidCallback onTap;
  final String label;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = state == AppAddPillState.done;

    final fill = isDone
        ? Colors.transparent
        : (isDark ? AppColors.primaryBright.withValues(alpha: 0.16) : AppColors.primaryContainer);
    final tone = isDone
        ? colorScheme.onSurfaceVariant
        : (isDark ? AppColors.primaryBright : AppColors.primary);

    final pill = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: isDone ? Border.all(color: isDark ? AppColors.hairlineDark : AppColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: switch (state) {
              AppAddPillState.busy => Padding(
                  padding: const EdgeInsets.all(1),
                  child: CircularProgressIndicator(strokeWidth: 2, color: tone),
                ),
              AppAddPillState.done => Icon(Icons.check_rounded, size: 16, color: tone),
              AppAddPillState.idle => Icon(Icons.add_rounded, size: 16, color: tone),
            },
          ),
          const SizedBox(width: 5),
          Text(
            isDone ? doneLabel : label,
            style: AppTextStyles.badgeLabel.copyWith(fontSize: 12.5, color: tone),
          ),
        ],
      ),
    );

    if (state != AppAddPillState.idle) {
      return Semantics(label: isDone ? doneLabel : 'Saving', child: pill);
    }
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: pill),
      ),
    );
  }
}
