import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// The bar that holds a screen's primary action (Save, Checkout, …), pinned
/// to the bottom and **always above the keyboard**.
///
/// Put it in `Scaffold.bottomNavigationBar`. That slot is not moved by the
/// keyboard on its own — `resizeToAvoidBottomInset` only shrinks the body —
/// so a plain bar there sits *under* the keyboard and the Save button
/// disappears exactly when the user finishes typing. This bar lifts itself by
/// the keyboard's height, and the Scaffold keeps the body above it, so the
/// field being edited and the button are both visible.
///
/// Flat surface with a hairline top edge, per the design system.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({super.key, required this.child, this.padding});

  /// Usually one full-width button, or a [Row] of two.
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.hairlineDark : AppColors.hairline),
          ),
        ),
        child: SafeArea(
          top: false,
          // With the keyboard open the system inset is already covered.
          bottom: keyboard == 0,
          child: Padding(
            padding: padding ??
                const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.md,
                  AppDimensions.pagePaddingH,
                  AppDimensions.md,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A full-width primary button sized for [AppBottomActionBar], with a busy
/// state that keeps its size.
class AppPrimaryActionButton extends StatelessWidget {
  const AppPrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
    return SizedBox(
      height: AppDimensions.buttonHeight,
      width: double.infinity,
      child: icon == null
          ? ElevatedButton(onPressed: busy ? null : onPressed, child: busy ? spinner : Text(label))
          : ElevatedButton.icon(
              onPressed: busy ? null : onPressed,
              icon: busy ? spinner : Icon(icon, size: AppDimensions.iconSm),
              label: Text(label),
            ),
    );
  }
}
