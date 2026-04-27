import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/inventory/presentation/screens/stock_adjustment_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ProductUpsertScreen extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const ProductUpsertScreen({super.key, this.productToEdit});

  @override
  ConsumerState<ProductUpsertScreen> createState() => _ProductUpsertScreenState();
}

class _ProductUpsertScreenState extends ConsumerState<ProductUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _itemsPerCartonController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '0');
  final _reorderLevelController = TextEditingController(text: '0');

  final List<String> _categories = ['Groceries', 'Electronics', 'Clothing', 'Hardware', 'Services', 'Other'];
  final List<String> _brands = ['Generic', 'Nestle', 'Coca-Cola', 'Unilever', 'Samsung', 'Local', 'Other'];
  final List<String> _units = ['pcs', 'carton', 'kg', 'L', 'box', 'pack'];

  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedUnit;

  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    if (product == null) {
      return;
    }

    _nameController.text = product.name;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    if (product.category != null && product.category!.isNotEmpty) {
      if (!_categories.contains(product.category)) _categories.add(product.category!);
      _selectedCategory = product.category;
    }
    if (product.brand != null && product.brand!.isNotEmpty) {
      if (!_brands.contains(product.brand)) _brands.add(product.brand!);
      _selectedBrand = product.brand;
    }
    if (product.unit.isNotEmpty) {
      if (!_units.contains(product.unit)) _units.add(product.unit);
      _selectedUnit = product.unit;
    }
    _itemsPerCartonController.text = product.itemsPerCarton?.toString() ?? '';
    _costPriceController.text = product.costPrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _stockQuantityController.text = product.stockQuantity.toString();
    _reorderLevelController.text = product.reorderLevel.toString();
    _isActive = product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _itemsPerCartonController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockQuantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final allowed = await _ensureManageInventoryPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_product' : 'create_product',
      entityId: widget.productToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productsRepositoryProvider);
      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();
      final barcode = _barcodeController.text.trim();
      final category = _selectedCategory ?? '';
      final brand = _selectedBrand ?? '';
      final unit = _selectedUnit ?? 'pcs';
      final itemsPerCarton = int.tryParse(_itemsPerCartonController.text.trim());
      final costPrice = Decimal.tryParse(_costPriceController.text.trim()) ??
          Decimal.zero;
      final sellingPrice =
          Decimal.tryParse(_sellingPriceController.text.trim()) ?? Decimal.zero;
      final stockQuantity = int.tryParse(_stockQuantityController.text.trim()) ?? 0;
      // reorderLevel is no longer per-product — a global threshold is set in Settings
      const reorderLevel = 0;
      final actorRole = ref.read(currentRoleProvider);

      if (_isEditing) {
        await repo.updateProduct(
          widget.productToEdit!.copyWith(
            name: name,
            sku: sku.isEmpty ? null : sku,
            barcode: barcode.isEmpty ? null : barcode,
            category: category.isEmpty ? null : category,
            brand: brand.isEmpty ? null : brand,
            unit: unit,
            itemsPerCarton: unit.toLowerCase() == 'carton' ? itemsPerCarton : null,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            stockQuantity: stockQuantity,
            reorderLevel: reorderLevel,
            isActive: _isActive,
          ),
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'product_updated',
          entityType: 'product',
          entityId: widget.productToEdit!.id,
          message: 'Product "$name" was updated.',
        );
      } else {
        await repo.addProduct(
          name: name,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          category: category.isEmpty ? null : category,
          brand: brand.isEmpty ? null : brand,
          unit: unit,
          itemsPerCarton: unit.toLowerCase() == 'carton' ? itemsPerCarton : null,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stockQuantity: stockQuantity,
          reorderLevel: reorderLevel,
          isActive: _isActive,
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'product_created',
          entityType: 'product',
          message: 'Product "$name" was created.',
        );
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final product = widget.productToEdit;
    if (product == null) {
      return;
    }

    final allowed = await _ensureManageInventoryPermission(
      context,
      ref,
      attemptedAction: 'delete_product',
      entityId: product.id,
    );
    if (!allowed) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text('This will permanently delete "${product.name}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productsRepositoryProvider);
      await repo.deleteProduct(product.id);
      final actorRole = ref.read(currentRoleProvider);
      await ref.read(auditRepositoryProvider).logAction(
        actorRole: actorRole,
        action: 'product_deleted',
        entityType: 'product',
        entityId: product.id,
        message: 'Product "${product.name}" was deleted.',
      );
      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(recentAuditLogsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit Product' : 'New Product'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete product',
              onPressed: _isLoading ? null : _deleteProduct,
              icon: const Icon(Icons.delete_outline, color: AppColors.negative),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.xxxl),

                // ─────────────────────────────────────────────────────────
                // Basic Information
                // ─────────────────────────────────────────────────────────
                AppFormSection(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Product Name',
                      hintText: 'e.g. Rice 25kg',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Product name is required'
                          : null,
                    ),
                    const Divider(height: 1),
                    _buildDropdownField(
                      value: _selectedCategory,
                      items: _categories,
                      label: 'Category',
                      hintText: 'Select Category',
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const Divider(height: 1),
                    _buildDropdownField(
                      value: _selectedBrand,
                      items: _brands,
                      label: 'Brand',
                      hintText: 'Select Brand',
                      onChanged: (val) => setState(() => _selectedBrand = val),
                    ),
                    const Divider(height: 1),
                    _buildTextFormField(
                      controller: _skuController,
                      label: 'SKU (Optional)',
                      hintText: 'e.g. SKU-001',
                    ),
                    const Divider(height: 1),
                    _buildTextFormField(
                      controller: _barcodeController,
                      label: 'Barcode (Optional)',
                      hintText: 'e.g. 1234567890123',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // ─────────────────────────────────────────────────────────
                // Inventory Rules
                // ─────────────────────────────────────────────────────────
                AppFormSection(
                  title: 'Inventory & Stock',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    _buildDropdownField(
                      value: _selectedUnit,
                      items: _units,
                      label: 'Unit of Measurement',
                      hintText: 'Select Unit',
                      onChanged: (val) => setState(() => _selectedUnit = val),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Unit is required'
                          : null,
                    ),
                    if (_selectedUnit?.toLowerCase() == 'carton') ...[
                      const Divider(height: 1),
                      _buildTextFormField(
                        controller: _itemsPerCartonController,
                        label: 'Items per Carton',
                        hintText: 'e.g. 12',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (_selectedUnit?.toLowerCase() != 'carton') return null;
                          final count = int.tryParse(value?.trim() ?? '');
                          if (count == null || count <= 0) return 'Required for carton';
                          return null;
                        },
                      ),
                    ],
                    const Divider(height: 1),
                    _buildTextFormField(
                      controller: _stockQuantityController,
                      label: 'Current Stock Quantity',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    // Low stock threshold is now global — set in Profile > Inventory Settings
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // ─────────────────────────────────────────────────────────
                // Pricing
                // ─────────────────────────────────────────────────────────
                AppFormSection(
                  title: 'Pricing',
                  icon: Icons.sell_outlined,
                  children: [
                    _buildTextFormField(
                      controller: _costPriceController,
                      label: 'Cost Price (Optional)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                    const Divider(height: 1),
                    _buildTextFormField(
                      controller: _sellingPriceController,
                      label: 'Selling Price (ETB)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),

                // ─────────────────────────────────────────────────────────
                // Visibility
                // ─────────────────────────────────────────────────────────
                AppFormSection(
                  title: 'Visibility',
                  icon: Icons.visibility_outlined,
                  children: [
                    SwitchListTile.adaptive(
                      activeColor: AppColors.primary,
                      title: const Text('Active Product'),
                      subtitle: const Text('Visible in POS and Inventory lists'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),

                if (_isEditing) ...[
                  const SizedBox(height: AppDimensions.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final allowed = await _ensureManageInventoryPermission(
                                context,
                                ref,
                                attemptedAction: 'open_stock_adjustment',
                                entityId: widget.productToEdit!.id,
                              );
                              if (!allowed) return;
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StockAdjustmentScreen(
                                    product: widget.productToEdit!,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                      label: const Text(
                        'Audit / Adjust Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.xxxl),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required String hintText,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
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
}