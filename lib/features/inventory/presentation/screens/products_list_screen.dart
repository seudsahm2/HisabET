import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/inventory/presentation/screens/product_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  bool _isBundle(ProductModel product) {
    return product.unit.toLowerCase() == 'carton' || product.itemsPerCarton != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Inventory Library'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          final singleItems = products.where((product) => !_isBundle(product)).toList();
          final bundleItems = products.where(_isBundle).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Single Items'),
                    Tab(text: 'Bundle Items'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InventoryTypeList(
                        products: singleItems,
                        emptyMessage: 'No single products in your inventory.',
                        onCreateProduct: () => _handleCreateProduct(context, ref),
                        onRefresh: () async {
                          ref.invalidate(allProductsProvider);
                          ref.invalidate(lowStockProductsProvider);
                        },
                      ),
                      _InventoryTypeList(
                        products: bundleItems,
                        emptyMessage: 'No bundles or complex units yet.',
                        onCreateProduct: () => _handleCreateProduct(context, ref),
                        onRefresh: () async {
                          ref.invalidate(allProductsProvider);
                          ref.invalidate(lowStockProductsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _handleCreateProduct(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _handleCreateProduct(BuildContext context, WidgetRef ref) async {
    final allowed = await _ensureManageInventoryPermission(
      context,
      ref,
      attemptedAction: 'open_create_product',
    );
    if (!allowed) return;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProductUpsertScreen(),
      ),
    );
  }
}

class _InventoryTypeList extends ConsumerWidget {
  final List<ProductModel> products;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreateProduct;

  const _InventoryTypeList({
    required this.products,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onCreateProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Empty Inventory',
        subtitle: emptyMessage,
        actionLabel: 'Create Product',
        onAction: () => onCreateProduct(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
        itemCount: products.length + 1, // +1 for the summary header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _InventorySummary(products: products);
          }
          final product = products[index - 1];
          return _ProductTile(
            product: product,
            onTap: () async {
              final allowed = await _ensureManageInventoryPermission(
                context,
                ref,
                attemptedAction: 'open_edit_product',
                entityId: product.id,
              );
              if (!allowed) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductUpsertScreen(productToEdit: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.isLowStock;
    final isBundle = product.unit.toLowerCase() == 'carton' || product.itemsPerCarton != null;
    final itemsPerCarton = product.itemsPerCarton ?? 0;
    
    // Format subtitle appropriately based on bundle type
    final String subtitleContent;
    if (isBundle) {
      subtitleContent = 'Cartons: ${product.stockQuantity} • Qty/Carton: ${itemsPerCarton > 0 ? itemsPerCarton : '-'}';
    } else {
      final parts = <String>[];
      if (product.category != null && product.category!.isNotEmpty) {
        parts.add(product.category!);
      }
      parts.add('Stock: ${product.stockQuantity} ${product.unit}');
      subtitleContent = parts.join(' • ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: AppListTile(
        leadingIcon: Icons.inventory_2_rounded,
        leadingColor: isLowStock ? AppColors.negative : AppColors.primary,
        title: product.name,
        subtitle: subtitleContent,
        onTap: onTap,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppAmountText(
              amount: product.sellingPrice.toString(),
              isPositive: true,
              showSign: false,
            ),
            const SizedBox(height: 4),
            isLowStock
                ? AppStatusBadge.danger(label: 'Low Stock', small: true)
                : AppStatusBadge.success(label: 'In Stock', small: true)
          ],
        ),
      ),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  final List<ProductModel> products;

  const _InventorySummary({required this.products});

  @override
  Widget build(BuildContext context) {
    final lowStockCount = products.where((product) => product.isLowStock).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.xl),
      child: AppStatRow(
        children: [
          AppStatTile(
            icon: Icons.inventory_2,
            label: 'Total Products',
            value: products.length.toString(),
            color: AppColors.primary,
          ),
          AppStatTile(
            icon: Icons.warning_amber_rounded,
            label: 'Low Stock Alerts',
            value: lowStockCount.toString(),
            color: lowStockCount > 0 ? AppColors.negative : AppColors.positive,
          ),
        ],
      ),
    );
  }
}

Future<bool> _ensureManageInventoryPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  String? entityId,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.manageInventory));
  if (allowed) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref.read(auditRepositoryProvider).logAction(
    actorRole: actorRole,
    action: 'permission_denied',
    entityType: 'product',
    entityId: entityId,
    message: 'Denied $attemptedAction for role ${actorRole.name}.',
  );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to manage inventory.'),
        backgroundColor: AppColors.negative,
      ),
    );
  }
  return false;
}
