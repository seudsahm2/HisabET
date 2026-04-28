import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/presentation/widgets/app_glass.dart';

enum AppCardStyle { glass, solid }

/// Standard card widget used across the entire app.
/// Replaces every manual `Container(decoration: BoxDecoration(...))` white card.
///
/// Usage:
/// ```dart
/// AppCard(
///   child: ListTile(title: Text('Hello')),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.border,
    this.elevation = 0,
    this.clip = Clip.antiAlias,
    this.style = AppCardStyle.glass,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final double elevation;
  final Clip clip;
  final AppCardStyle style;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(AppDimensions.cardRadius);
    final colorScheme = Theme.of(context).colorScheme;
    final bg = color ?? colorScheme.surface;
    final cardBorder = border ?? Border.all(color: colorScheme.outlineVariant);
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black54
        : AppColors.shadowLight;

    BoxDecoration cardDecoration() {
      if (style == AppCardStyle.glass && color == null && border == null) {
        return AppGlass.surface(
          context,
          borderRadius: radius,
          withShadow: true,
        );
      }

      return BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: cardBorder,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10 * elevation,
                  offset: Offset(0, 4 * elevation),
                ),
              ]
            : const [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      );
    }

    Widget card = Container(
      margin: margin,
      decoration: cardDecoration(),
      clipBehavior: clip,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null || onLongPress != null) {
      card = Container(
        margin: margin,
        decoration: cardDecoration(),
        clipBehavior: clip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: radius is BorderRadius ? radius : null,
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      );
    }

    return card;
  }
}

/// A card with a colored top accent strip (3px left border).
/// Use in list screens to color-code items by category.
class AppAccentCard extends StatelessWidget {
  const AppAccentCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.padding,
    this.margin,
    this.onTap,
    this.style = AppCardStyle.glass,
  });

  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final AppCardStyle style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppDimensions.cardRadius);

    return Container(
      margin: margin,
      decoration: style == AppCardStyle.glass
          ? AppGlass.surface(
              context,
              borderRadius: borderRadius,
              tintColor: accentColor,
            )
          : BoxDecoration(
              color: colorScheme.surface,
              borderRadius: borderRadius,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: padding != null
                      ? Padding(padding: padding!, child: child)
                      : child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
