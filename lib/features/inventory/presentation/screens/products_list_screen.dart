import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

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
  String _selectedRole = 'all'; // 'all' | 'importer' | 'broker' | 'wholesaler' | 'retailer'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  
  bool? _filterIsLowStock;
  bool? _filterIsActive;
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (products) {
            var filteredProducts = products
                .where((p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (p.itemNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                    (p.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                .toList();
                
            if (_filterIsLowStock != null) {
              filteredProducts = filteredProducts.where((p) => p.isLowStock == _filterIsLowStock).toList();
            }
            if (_filterIsActive != null) {
              filteredProducts = filteredProducts.where((p) => p.isActive == _filterIsActive).toList();
            }
            if (_filterCategory != null && _filterCategory!.isNotEmpty) {
              filteredProducts = filteredProducts.where((p) => p.category == _filterCategory).toList();
            }

            final counts = {
              'all': filteredProducts.length,
              'importer': filteredProducts.where((p) => p.businessRole == 'importer').length,
              'broker': filteredProducts.where((p) => p.businessRole == 'broker').length,
              'wholesaler': filteredProducts.where((p) => p.businessRole == 'wholesaler').length,
              'retailer': filteredProducts.where((p) => p.businessRole == 'retailer').length,
            };

            final currentList = _selectedRole == 'all'
                ? filteredProducts
                : filteredProducts.where((p) => p.businessRole == _selectedRole).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: AppMissionHeader(
                    eyebrow: 'STOCK SYSTEM',
                    title: 'Stock Intelligence',
                  ),
                ),
                
                // Search Bar (Full Width)
                SliverToBoxAdapter(
                  child: AppSearchBar(
                    hintText: 'Search products, SKU, categories...',
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Filter & View Switcher
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    0,
                    AppDimensions.pagePaddingH,
                    AppDimensions.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                AppCard(
                                  style: AppCardStyle.glass,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  onTap: () => _showFilterModal(context, products, counts),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                                      if (_getActiveFilterCount() > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                          child: Text('${_getActiveFilterCount()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_selectedRole != 'all') ...[
                                  const SizedBox(width: 8),
                                  _buildActiveFilterChip('Role: ${_selectedRole.toUpperCase()}', () => setState(() => _selectedRole = 'all')),
                                ],
                                if (_filterIsActive != null) ...[
                                  const SizedBox(width: 8),
                                  _buildActiveFilterChip(_filterIsActive! ? 'Status: Active' : 'Status: Inactive', () => setState(() => _filterIsActive = null)),
                                ],
                                if (_filterIsLowStock != null && _filterIsLowStock!) ...[
                                  const SizedBox(width: 8),
                                  _buildActiveFilterChip('Low Stock Only', () => setState(() => _filterIsLowStock = null)),
                                ],
                                if (_filterCategory != null) ...[
                                  const SizedBox(width: 8),
                                  _buildActiveFilterChip('Cat: $_filterCategory', () => setState(() => _filterCategory = null)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        // View Switcher
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isGridView = false),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppDimensions.radiusMd)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Icon(Icons.view_list_rounded, size: 20, color: !_isGridView ? AppColors.primary : AppColors.textHint),
                                ),
                              ),
                              Container(width: 1, height: 20, color: Theme.of(context).dividerColor),
                              InkWell(
                                onTap: () => setState(() => _isGridView = true),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppDimensions.radiusMd)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Icon(Icons.grid_view_rounded, size: 20, color: _isGridView ? AppColors.primary : AppColors.textHint),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary Stats Row
                if (products.isNotEmpty && _searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: _InventorySummary(products: products),
                  ),

                // Product List
                if (currentList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.xxxl),
                      child: AppEmptyState(
                        icon: Icons.production_quantity_limits_rounded,
                        title: _searchQuery.isEmpty ? 'No products in this category' : 'No matching products',
                        subtitle: _searchQuery.isEmpty
                            ? 'Tap the + button to add stock for this role.'
                            : 'Try adjusting your search or filters.',
                      ),
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppDimensions.md,
                        crossAxisSpacing: AppDimensions.md,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = currentList[index];
                          return _PremiumProductGridCard(
                            product: product,
                            onTap: () async {
                              final allowed = await _ensureManageInventoryPermission(context, ref, attemptedAction: 'open_edit_product', entityId: product.id);
                              if (!allowed || !context.mounted) return;
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductUpsertScreen(productToEdit: product)));
                            },
                          );
                        },
                        childCount: currentList.length,
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

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedRole != 'all') count++;
    if (_filterIsActive != null) count++;
    if (_filterIsLowStock != null && _filterIsLowStock!) count++;
    if (_filterCategory != null) count++;
    return count;
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
    );
  }

  void _showFilterModal(BuildContext context, List<ProductModel> allProducts, Map<String, int> counts) {
    final categories = allProducts.map((p) => p.category).whereType<String>().toSet().toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filters', style: AppTextStyles.headlineSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedRole = 'all';
                              _filterIsActive = null;
                              _filterIsLowStock = null;
                              _filterCategory = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: AppColors.negative)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    
                    const Text('Role / Business Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildModalChip('all', 'All (${counts['all']})', _selectedRole, (v) => setModalState(() => _selectedRole = v)),
                        _buildModalChip('importer', 'Importer (${counts['importer']})', _selectedRole, (v) => setModalState(() => _selectedRole = v)),
                        _buildModalChip('broker', 'Broker (${counts['broker']})', _selectedRole, (v) => setModalState(() => _selectedRole = v)),
                        _buildModalChip('wholesaler', 'Wholesaler (${counts['wholesaler']})', _selectedRole, (v) => setModalState(() => _selectedRole = v)),
                        _buildModalChip('retailer', 'Retailer (${counts['retailer']})', _selectedRole, (v) => setModalState(() => _selectedRole = v)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildModalFilterChip('All', _filterIsActive == null, () => setModalState(() => _filterIsActive = null)),
                        _buildModalFilterChip('Active', _filterIsActive == true, () => setModalState(() => _filterIsActive = true)),
                        _buildModalFilterChip('Inactive', _filterIsActive == false, () => setModalState(() => _filterIsActive = false)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    
                    const Text('Stock Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildModalFilterChip('All', _filterIsLowStock == null, () => setModalState(() => _filterIsLowStock = null)),
                        _buildModalFilterChip('Low Stock', _filterIsLowStock == true, () => setModalState(() => _filterIsLowStock = true), selectedColor: AppColors.warning.withOpacity(0.3)),
                      ],
                    ),
                    
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.lg),
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _buildModalFilterChip('All', _filterCategory == null, () => setModalState(() => _filterCategory = null)),
                          ...categories.map((c) => _buildModalFilterChip(c, _filterCategory == c, () => setModalState(() => _filterCategory = c))).toList(),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: AppDimensions.xxxl),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalChip(String value, String label, String groupValue, Function(String) onSelect) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildModalFilterChip(String label, bool isSelected, VoidCallback onSelect, {Color? selectedColor}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(),
      selectedColor: selectedColor ?? AppColors.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? (selectedColor != null ? Colors.black87 : AppColors.primary) : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
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
    final roleColor = product.businessRole == 'importer'
        ? AppColors.info
        : product.businessRole == 'broker'
            ? const Color(0xFF8B5CF6)
            : product.businessRole == 'wholesaler'
                ? const Color(0xFFF59E0B)
                : AppColors.primary;

    return AppListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          image: product.photoUrl != null ? DecorationImage(image: NetworkImage(product.photoUrl!), fit: BoxFit.cover) : null,
          gradient: product.photoUrl == null ? LinearGradient(colors: [roleColor, roleColor.withOpacity(0.7)]) : null,
        ),
        child: product.photoUrl == null
            ? Center(child: Text(product.name.isNotEmpty ? product.name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)))
            : null,
      ),
      title: product.itemNumber?.isNotEmpty == true ? 'Item: ${product.itemNumber}' : product.name,
      subtitle: product.category ?? 'Uncategorized',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ETB ${product.sellingPrice}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 4),
          if (product.isLowStock)
            AppStatusBadge.danger(label: 'Low Stock: ${product.stockQuantity}', small: true)
          else
            Text('Stock: ${product.stockQuantity} ${product.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _PremiumProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _PremiumProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.isLowStock;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      style: AppCardStyle.glass,
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: Clip.antiAlias,
      border: isLowStock ? Border.all(color: AppColors.negative.withOpacity(0.5), width: 1.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (product.photoUrl != null)
                  Image.network(product.photoUrl!, fit: BoxFit.cover)
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        product.name.isNotEmpty ? product.name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                
                // Badges overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!product.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                          child: const Text('INACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.negative, borderRadius: BorderRadius.circular(4)),
                          child: const Text('LOW STOCK', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category ?? 'General',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w500),
                        maxLines: 1,
                      ),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ETB ${product.sellingPrice}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      Text(
                        '${product.stockQuantity} ${product.unit}',
                        style: TextStyle(
                          color: isLowStock ? AppColors.negative : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
    
    // Fix: Multiply by itemsPerCarton for bundles if present.
    // User enters price per individual quantity, but tracks stock in cartons.
    final totalValue = products.fold<Decimal>(
      Decimal.zero, 
      (sum, p) => sum + (p.costPrice * Decimal.fromInt(p.totalPiecesInStock)),
    );

    final totalPotentialProfit = products.fold<Decimal>(
      Decimal.zero,
      (sum, p) {
        final profitPerPiece = p.sellingPrice - p.costPrice;
        return sum + (profitPerPiece * Decimal.fromInt(p.totalPiecesInStock));
      },
    );

    return AppGradientCard(
      label: 'TOTAL INVENTORY VALUE',
      value: 'ETB ${NumberFormat('#,###.##').format(double.parse(totalValue.toString()))}',
      backgroundIcon: Icons.account_balance_wallet_rounded,
      children: [
        AppGradientCardStatRow(
          leftLabel: 'Low Stock',
          leftValue: '$lowStockCount Items',
          leftValueColor: lowStockCount > 0 ? AppColors.warning : Colors.white70,
          rightLabel: 'Est. Profit',
          rightValue: 'ETB ${NumberFormat('#,###').format(double.parse(totalPotentialProfit.toString()))}',
          rightValueColor: Colors.white,
        ),
      ],
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
