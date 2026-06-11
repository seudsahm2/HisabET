import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/presentation/widgets/app_card.dart';

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
    return AppCard(
      style: AppCardStyle.glass,
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.sm,
          ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
