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

/// One option in an [AppSearchScopeButton].
class AppSearchScope<T> {
  const AppSearchScope({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;

  /// Kept short — it renders inside the field.
  final String label;

  final IconData icon;
}

/// "Search *what*" — a scope picker docked in an [AppSearchBar]'s trailing
/// slot: local contacts vs the network, email vs phone.
///
/// It belongs to the field, behind the field's own hairline, rather than
/// floating inside it. The current scope is always spelled out, so a search
/// that returns nothing is never ambiguous about where it looked.
class AppSearchScopeButton<T> extends StatelessWidget {
  const AppSearchScopeButton({
    super.key,
    required this.scopes,
    required this.value,
    required this.onChanged,
    this.tooltip = 'Search scope',
  });

  final List<AppSearchScope<T>> scopes;
  final T value;
  final ValueChanged<T> onChanged;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;
    final active = scopes.firstWhere((scope) => scope.value == value);

    return PopupMenuButton<T>(
      initialValue: value,
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      elevation: 3,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.hairlineDark : AppColors.hairline,
        ),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final scope in scopes)
          PopupMenuItem<T>(
            value: scope.value,
            child: _ScopeMenuRow(
              icon: scope.icon,
              label: scope.label,
              active: scope.value == value,
            ),
          ),
      ],
      child: SizedBox(
        height: 46,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active.icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                active.label,
                style: AppTextStyles.badgeLabel.copyWith(
                  fontSize: 12.5,
                  color: accent,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeMenuRow extends StatelessWidget {
  const _ScopeMenuRow({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: active ? accent : colorScheme.onSurfaceVariant),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color:
                  active ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (active) Icon(Icons.check_rounded, size: 16, color: accent),
      ],
    );
  }
}
