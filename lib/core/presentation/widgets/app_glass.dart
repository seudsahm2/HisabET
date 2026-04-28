import 'package:flutter/material.dart';

/// Shared visual recipes for glass-like surfaces.
///
/// Keep all high-level glass tuning here so feature widgets stay decoupled.
class AppGlass {
  const AppGlass._();

  static BoxDecoration surface(
    BuildContext context, {
    BorderRadiusGeometry? borderRadius,
    Color? tintColor,
    double tintStrength = 1,
    bool withShadow = true,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);
    final tint = tintColor ?? colorScheme.primaryContainer;
    final firstStop = colorScheme.surface.withValues(alpha: isDark ? 0.88 : 0.94);
    final secondStop = tint.withValues(
      alpha: (isDark ? 0.18 : 0.30) * tintStrength,
    );

    return BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.85),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [firstStop, secondStop],
      ),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: (tintColor ?? colorScheme.shadow)
                    .withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: isDark ? 20 : 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }
}