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

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  int _selectedTab = 0; // 0 = Single Items, 1 = Bundles
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isBundle(ProductModel product) {
    return product.unit.toLowerCase() == 'carton' || product.itemsPerCarton != null;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (products) {
            final filteredProducts = products.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || (p.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
            final singleItems = filteredProducts.where((product) => !_isBundle(product)).toList();
            final bundleItems = filteredProducts.where(_isBundle).toList();

            final currentList = _selectedTab == 0 ? singleItems : bundleItems;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Sliver App Bar
                SliverAppBar(
                  expandedHeight: 180.0,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: AppDimensions.pagePaddingH, bottom: 16),
                    title: const Text(
                      'Inventory Library',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Icon(Icons.inventory_2_rounded, size: 150, color: AppColors.primary.withOpacity(0.05)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Search Bar and Tabs
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).cardColor : Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search products, SKU, categories...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        
                        // Modern Segmented Control for Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _buildTabPill('Single Items', 0, singleItems.length)),
                              Expanded(child: _buildTabPill('Bundles & Packs', 1, bundleItems.length)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

                // Summary Stats Row
                if (products.isNotEmpty && _searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                      child: _InventorySummary(products: products),
                    ),
                  ),

                // Product List
                if (currentList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.xxxl),
                      child: AppEmptyState(
                        icon: Icons.production_quantity_limits_rounded,
                        title: _searchQuery.isEmpty ? 'No products found' : 'No matching products',
                        subtitle: 'Try adjusting your filters or adding a new product.',
                        actionLabel: 'Create Product',
                        onAction: () => _handleCreateProduct(context, ref),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = currentList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.md),
                            child: _PremiumProductCard(
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
                                  MaterialPageRoute(builder: (_) => ProductUpsertScreen(productToEdit: product)),
                                );
                              },
                            ),
                          );
                        },
                        childCount: currentList.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        onPressed: () => _handleCreateProduct(context, ref),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildTabPill(String title, int index, int count) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            '$title ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
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

class _PremiumProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _PremiumProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = product.isLowStock;
    final isBundle = product.unit.toLowerCase() == 'carton' || product.itemsPerCarton != null;
    final itemsPerCarton = product.itemsPerCarton ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: isLowStock ? AppColors.negative.withOpacity(0.5) : AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Avatar / Initial
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isLowStock ? AppColors.negative : AppColors.primary,
                    isLowStock ? AppColors.negative.withOpacity(0.7) : AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.category != null && product.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category!,
                        style: const TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 6),
                  
                  // Stock Info
                  Row(
                    children: [
                      Icon(isBundle ? Icons.view_in_ar_rounded : Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        isBundle 
                          ? 'Stock: ${product.stockQuantity} CTN (${itemsPerCarton}/CTN)'
                          : 'Stock: ${product.stockQuantity} ${product.unit}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Pricing & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETB ${product.sellingPrice}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? AppColors.negative.withOpacity(0.1) : AppColors.positive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isLowStock ? AppColors.negative : AppColors.positive),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                        size: 12,
                        color: isLowStock ? AppColors.negative : AppColors.positive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLowStock ? 'Low Stock' : 'In Stock',
                        style: TextStyle(
                          color: isLowStock ? AppColors.negative : AppColors.positive,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final totalValue = products.fold<Decimal>(Decimal.zero, (sum, p) => sum + (p.sellingPrice * Decimal.fromInt(p.stockQuantity)));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.xl),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 24),
                  const SizedBox(height: 8),
                  const Text('Inventory Value', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('ETB $totalValue', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: lowStockCount > 0 ? AppColors.negative.withOpacity(0.1) : AppColors.positive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: lowStockCount > 0 ? AppColors.negative.withOpacity(0.3) : AppColors.positive.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(lowStockCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: lowStockCount > 0 ? AppColors.negative : AppColors.positive, size: 24),
                  const SizedBox(height: 8),
                  Text('Low Stock Alerts', style: TextStyle(color: lowStockCount > 0 ? AppColors.negative : AppColors.positive, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$lowStockCount items', style: TextStyle(color: lowStockCount > 0 ? AppColors.negative : AppColors.positive, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
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
