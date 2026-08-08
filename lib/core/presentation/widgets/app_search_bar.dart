import 'package:flutter/material.dart';

import 'package:hisabet/core/theme/theme.dart';

/// The app's search input. Used in Contacts, POS, Inventory, Sales History.
///
/// ## What was wrong before
///
/// The old version wrapped a `TextField` in an `AppCard` and left the global
/// `inputDecorationTheme` alone — which sets `filled: true`. So a filled
/// rectangle was painted *inside* a rounded card: two backgrounds, two shapes.
/// Worse, the field set every border to `InputBorder.none`, and in Flutter the
/// radius lives on the border — remove the border and the fill turns into a
/// hard square. That is the square-inside-a-curve mismatch, and it appeared
/// everywhere this widget was used.
///
/// A search field is **one control**, so it gets one surface, one radius, one
/// edge. Focus is carried by the border colour and nothing else, so the control
/// never changes size or shifts the page when you tap into it.
///
/// [trailing] hangs an extra control off the right edge, separated by a
/// vertical hairline — a scope selector, a filter button. It stays part of the
/// same field instead of floating on top of it.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.margin,
    this.autofocus = false,
    this.trailing,
    this.textInputAction,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  /// Defaults to standard page insets. Pass `EdgeInsets.zero` when the parent
  /// already pads.
  final EdgeInsetsGeometry? margin;

  final bool autofocus;

  /// Optional control docked inside the right edge of the field.
  final Widget? trailing;

  final TextInputAction? textInputAction;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_syncFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_syncFocus);
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _syncFocus() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;

    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.sm,
          ),
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        border: Border.all(
          // The only thing that changes on focus. Width stays at 1 so the
          // field cannot grow and nudge its neighbours.
          color: _focused ? accent : hairline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDimensions.md),
          Icon(
            Icons.search_rounded,
            size: AppDimensions.iconSm + 2,
            color: _focused ? accent : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: widget.textInputAction,
              cursorColor: accent,
              style: AppTextStyles.cardTitle.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                // Explicitly off: the global theme fills every input, which is
                // right for a form and wrong inside an already-drawn surface.
                filled: false,
                isDense: true,
                hintText: widget.hintText,
                hintStyle: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox(width: AppDimensions.sm);
              }
              return Semantics(
                button: true,
                label: 'Clear search',
                child: InkWell(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    // Narrow, but full field height — the target stays large
                    // enough while leaving room for the query itself.
                    width: 40,
                    height: 46,
                    child: Icon(
                      Icons.close_rounded,
                      size: AppDimensions.iconSm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.trailing != null) ...[
            Container(width: 1, height: 22, color: hairline),
            widget.trailing!,
          ] else
            const SizedBox(width: AppDimensions.xs),
        ],
      ),
    );
  }
}
