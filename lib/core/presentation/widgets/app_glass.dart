import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/app_colors.dart';

/// Shared surface recipes.
///
/// ## History — why this no longer produces glass
///
/// This used to return a tinted gradient with a shadow, and nearly every
/// surface in the app called it: cards, the nav bar, headers, list rows. The
/// result was that *everything* floated and everything carried a colour wash,
/// so nothing had priority and the whole product read as generic.
///
/// Professional financial interfaces do the opposite. There is one flat ground,
/// content sits directly on it, and separation is carried by a **hairline**.
/// Elevation is spent only where something genuinely floats above the page —
/// a bottom sheet, a dialog, the navigation bar.
///
/// The API is unchanged so existing call sites keep working; only the recipe
/// changed. `tintColor` is now used at very low strength for identity accents
/// (a module colour) rather than as a decorative gradient.
class AppGlass {
  const AppGlass._();

  /// A flat content surface with a hairline edge.
  ///
  /// [tintColor] applies a barely-there wash (≈3%) so a surface can carry an
  /// identity colour without becoming decorative. Pass `null` for the default
  /// neutral card, which is what most surfaces should use.
  ///
  /// [withShadow] should stay `false` for anything sitting in the page flow.
  static BoxDecoration surface(
    BuildContext context, {
    BorderRadiusGeometry? borderRadius,
    Color? tintColor,
    double tintStrength = 1,
    bool withShadow = false,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(14);

    final base = colorScheme.surface;
    // A wash this quiet reads as "this belongs to that module", not as styling.
    final fill = tintColor == null
        ? base
        : Color.alphaBlend(
            tintColor.withValues(alpha: (isDark ? 0.10 : 0.035) * tintStrength),
            base,
          );

    return BoxDecoration(
      color: fill,
      borderRadius: radius,
      border: Border.all(
        color: borderColor ??
            (isDark ? AppColors.hairlineDark : AppColors.hairline),
        width: 1,
      ),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.32)
                    : AppColors.shadowMedium,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// For things that genuinely float above the page: bottom sheets, dialogs,
  /// the floating navigation bar. This is the *only* place a visible shadow
  /// belongs.
  static BoxDecoration floating(
    BuildContext context, {
    BorderRadiusGeometry? borderRadius,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? AppColors.hairlineDark : AppColors.hairline,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.44)
              : AppColors.shadowStrong,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// A recessed well — segmented controls, quiet grouping, empty slots.
  static BoxDecoration sunken(
    BuildContext context, {
    BorderRadiusGeometry? borderRadius,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceSunken,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
    );
  }
}
