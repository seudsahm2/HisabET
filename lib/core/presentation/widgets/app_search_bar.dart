import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';

/// Reusable search bar.
/// Use in POS, Inventory, Contacts, Customers, Suppliers.
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   hintText: 'Search product by name or SKU',
///   onChanged: (value) => setState(() => _query = value),
///   controller: _searchController,
/// )
/// ```
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.margin,
    this.autofocus = false,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final EdgeInsetsGeometry? margin;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.sm,
          ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: controller != null
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller!,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                    );
                  },
                )
              : null,
        ),
      ),
    );
  }
}
