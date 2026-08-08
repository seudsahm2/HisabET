import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hisabet/core/theme/theme.dart';

/// The standard form input.
///
/// ## Why the label sits above the field
///
/// Material's floating label moves into the border when the field has content,
/// which means the *shape* of a form changes as it is filled and the label
/// competes with the value for the same space. In a ledger the value is a name
/// or an amount someone will be held to, so it gets the field to itself and the
/// label stays put above it. A permanently visible label is also the
/// accessibility baseline — a placeholder disappears the moment you type, so it
/// is not a label.
///
/// ## Why it declares its own colours
///
/// Every colour here is explicit rather than inherited. Styles in the shared
/// text scale carry no colour of their own, so a widget that leans on ambient
/// theming can end up rendering text in whatever `DefaultTextStyle` happens to
/// be in scope — which is how form text turned invisible against a white card.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.isRequired = false,
    this.numeric = false,
    this.autofocus = false,
    this.prefixText,
    this.suffix,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;

  /// Persistent guidance under the field. Not a substitute for the label.
  final String? helper;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? minLines;
  final int? maxLength;

  /// Value is shown but cannot be edited — e.g. pulled from a verified
  /// profile. Rendered as a recessed well with a lock, so it reads as
  /// "filled in for you" rather than "broken".
  final bool readOnly;

  final bool enabled;
  final bool isRequired;

  /// Money and counts: tabular figures so digits line up column to column.
  final bool numeric;

  final bool autofocus;
  final String? prefixText;
  final Widget? suffix;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairline = isDark ? AppColors.hairlineDark : AppColors.hairline;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;
    final inert = !enabled || readOnly;

    final valueStyle = AppTextStyles.cardTitle.copyWith(
      fontWeight: FontWeight.w500,
      color: inert ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
      fontFeatures: numeric ? AppTextStyles.tabularFeatures : null,
    );

    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      // Stretch, so the field fills its column whatever alignment the parent
      // form section happens to use.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: AppColors.negative,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          cursorColor: accent,
          style: valueStyle,
          decoration: InputDecoration(
            filled: true,
            fillColor: inert
                ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceSunken)
                : colorScheme.surface,
            isDense: true,
            hintText: hint,
            hintStyle: valueStyle.copyWith(
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
            helperText: helper,
            helperMaxLines: 3,
            helperStyle: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            errorStyle: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              color: AppColors.negative,
            ),
            errorMaxLines: 2,
            counterText: '',
            prefixText: prefixText,
            prefixStyle: valueStyle.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: readOnly && suffix == null
                ? Icon(
                    Icons.lock_outline_rounded,
                    size: AppDimensions.iconSm,
                    color: colorScheme.onSurfaceVariant,
                  )
                : suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            // Declared on the field, not inherited: the shared input theme
            // removes borders, and in Flutter the corner radius lives on the
            // border — drop it and the fill turns into a hard rectangle.
            border: outline(hairline),
            enabledBorder: outline(hairline),
            disabledBorder: outline(hairline),
            focusedBorder: outline(accent, 1.5),
            errorBorder: outline(AppColors.negative),
            focusedErrorBorder: outline(AppColors.negative, 1.5),
          ),
        ),
      ],
    );
  }
}
