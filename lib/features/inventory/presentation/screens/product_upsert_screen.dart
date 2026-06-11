import 'dart:io';
import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
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
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _itemsPerCartonController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '0');
  
  // Shoe Batch Controllers
  final _itemNumberController = TextEditingController();
  final _sizeFromController = TextEditingController();
  final _sizeToController = TextEditingController();
  final _seriesSizeController = TextEditingController(text: '6');
  final _containerRefController = TextEditingController();

  final List<String> _categories = ['Groceries', 'Electronics', 'Clothing', 'Hardware', 'Services', 'Other', 'Shoes'];
  final List<String> _brands = ['Generic', 'Nestle', 'Coca-Cola', 'Unilever', 'Samsung', 'Local', 'Other'];
  final List<String> _units = ['pcs', 'carton', 'kg', 'L', 'box', 'pack', 'series'];

  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();

  String? _selectedUnit;
  String? _selectedSupplierContactId;
  String _selectedBusinessRole = 'retailer';

  // Colors
  List<ColorSlot> _colors = [];
  final _colorNameController = TextEditingController();
  final _colorCountController = TextEditingController(text: '1');

  bool _isActive = true;
  bool _isLoading = false;
  String? _photoUrl;
  File? _localImage;

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
      _categoryController.text = product.category!;
    }
    if (product.brand != null && product.brand!.isNotEmpty) {
      if (!_brands.contains(product.brand)) _brands.add(product.brand!);
      _brandController.text = product.brand!;
    }
    if (product.unit.isNotEmpty) {
      if (!_units.contains(product.unit)) _units.add(product.unit);
      _selectedUnit = product.unit;
    }
    _itemsPerCartonController.text = product.itemsPerCarton?.toString() ?? '';
    _costPriceController.text = product.costPrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _stockQuantityController.text = product.stockQuantity.toString();
    _isActive = product.isActive;
    _photoUrl = product.photoUrl;

    // Shoe Batch
    _itemNumberController.text = product.itemNumber ?? '';
    _sizeFromController.text = product.sizeFrom?.toString() ?? '';
    _sizeToController.text = product.sizeTo?.toString() ?? '';
    _seriesSizeController.text = product.seriesSize.toString();
    _containerRefController.text = product.containerRef ?? '';
    _selectedSupplierContactId = product.supplierContactId;
    _selectedBusinessRole = product.businessRole;
    _colors = List.from(product.parsedColorDistribution);
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
    _itemNumberController.dispose();
    _sizeFromController.dispose();
    _sizeToController.dispose();
    _seriesSizeController.dispose();
    _containerRefController.dispose();
    _colorNameController.dispose();
    _colorCountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() => _localImage = File(picked.path));
  }

  Future<void> _saveProduct() async {
    final allowed = await _ensureManageInventoryPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_product' : 'create_product',
      entityId: widget.productToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;

    // Validate color ratio sums to series size (for shoe batches)
    if (_colors.isNotEmpty) {
      final seriesSize = int.tryParse(_seriesSizeController.text.trim()) ?? 6;
      final colorTotal = _colors.fold<int>(0, (sum, c) => sum + c.count);
      if (colorTotal != seriesSize) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Color pairs per series must add up to $seriesSize. Currently: $colorTotal.'),
          backgroundColor: AppColors.negative,
        ));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productsRepositoryProvider);
      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();
      final barcode = _barcodeController.text.trim();
      final category = _categoryController.text.trim();
      final brand = _brandController.text.trim();
      final unit = _selectedUnit ?? 'pcs';
      final itemsPerCarton = int.tryParse(_itemsPerCartonController.text.trim());
      
      final costPrice = Decimal.tryParse(_costPriceController.text.trim()) ?? Decimal.zero;
      final sellingPrice = Decimal.tryParse(_sellingPriceController.text.trim()) ?? Decimal.zero;
      final stockQuantity = int.tryParse(_stockQuantityController.text.trim()) ?? 0;
      const reorderLevel = 0;
      final actorRole = ref.read(currentRoleProvider);

      // Shoe Batch fields
      final itemNumber = _itemNumberController.text.trim();
      final sizeFrom = int.tryParse(_sizeFromController.text.trim());
      final sizeTo = int.tryParse(_sizeToController.text.trim());
      final seriesSize = int.tryParse(_seriesSizeController.text.trim()) ?? 6;
      final containerRef = _containerRefController.text.trim();
      final colorDistJson = _colors.isNotEmpty ? jsonEncode(_colors.map((c) => c.toJson()).toList()) : null;

      String? uploadedUrl = _photoUrl;
      if (_localImage != null) {
        final imageName = _isEditing
            ? widget.productToEdit!.id
            : DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance.ref('product_photos/$imageName.jpg');
        await storageRef.putFile(_localImage!);
        uploadedUrl = await storageRef.getDownloadURL();
      }

      if (_isEditing) {
        await repo.updateProduct(
          widget.productToEdit!.copyWith(
            name: name,
            sku: sku.isEmpty ? null : sku,
            barcode: barcode.isEmpty ? null : barcode,
            category: category.isEmpty ? null : category,
            brand: brand.isEmpty ? null : brand,
            photoUrl: uploadedUrl,
            unit: unit,
            itemsPerCarton: unit.toLowerCase() == 'carton' ? itemsPerCarton : null,
            itemNumber: itemNumber.isEmpty ? null : itemNumber,
            sizeFrom: sizeFrom,
            sizeTo: sizeTo,
            seriesSize: seriesSize,
            colorDistribution: colorDistJson,
            containerRef: containerRef.isEmpty ? null : containerRef,
            supplierContactId: _selectedSupplierContactId,
            businessRole: _selectedBusinessRole,
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
          photoUrl: uploadedUrl,
          unit: unit,
          itemsPerCarton: unit.toLowerCase() == 'carton' ? itemsPerCarton : null,
          itemNumber: itemNumber.isEmpty ? null : itemNumber,
          sizeFrom: sizeFrom,
          sizeTo: sizeTo,
          seriesSize: seriesSize,
          colorDistribution: colorDistJson,
          containerRef: containerRef.isEmpty ? null : containerRef,
          supplierContactId: _selectedSupplierContactId,
          businessRole: _selectedBusinessRole,
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
    if (product == null) return;

    final allowed = await _ensureManageInventoryPermission(
      context, ref, attemptedAction: 'delete_product', entityId: product.id,
    );
    if (!allowed) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AppDeleteDialog(
        title: 'Delete Product?',
        content: 'Are you sure you want to delete "${product.name}"?\n\nThis cannot be undone.',
      ),
    );

    if (shouldDelete != true) return;

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.negative),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addColorSlot() {
    final name = _colorNameController.text.trim();
    final count = int.tryParse(_colorCountController.text.trim()) ?? 1;
    if (name.isNotEmpty) {
      setState(() {
        _colors.add(ColorSlot(color: name, count: count));
        _colorNameController.clear();
        _colorCountController.text = '1';
      });
    }
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedBusinessRole = role;
      _selectedSupplierContactId = null;
      if (role == 'importer' || role == 'broker') {
        _selectedUnit = 'carton';
      } else if (role == 'retailer') {
        _selectedUnit = 'pcs';
      } else {
        _selectedUnit = 'carton'; // default for wholesaler
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text(_isEditing ? 'Edit Product / Batch' : 'New Product / Batch'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete product',
              onPressed: _isLoading ? null : _deleteProduct,
              icon: const Icon(Icons.delete_outline, color: AppColors.negative),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _currentStep--);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
              ],
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentStep < 2) {
                            HapticFeedback.lightImpact();
                            setState(() => _currentStep++);
                          } else {
                            _saveProduct();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep < 2 ? 'NEXT STEP' : (_isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepDot(0, Icons.info_outline_rounded, 'Basic'),
                    _buildStepLine(_currentStep >= 1),
                    _buildStepDot(1, Icons.inventory_2_outlined, 'Stock'),
                    _buildStepLine(_currentStep >= 2),
                    _buildStepDot(2, Icons.settings_outlined, 'More'),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IndexedStack(
                      key: ValueKey<int>(_currentStep),
                      index: _currentStep,
                      children: [
                        // ── STEP 0: BASIC INFO ────────────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 140, height: 140,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    boxShadow: const [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, 4))],
                                    image: _localImage != null
                                        ? DecorationImage(image: FileImage(_localImage!), fit: BoxFit.cover)
                                        : (_photoUrl != null
                                            ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                                            : null),
                                  ),
                                  child: (_localImage == null && _photoUrl == null)
                                      ? const Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.primary)
                                      : null,
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary, 
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                                      ),
                                      child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xxxl),

                          const Center(
                            child: Text(
                              'BUSINESS ROLE',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.5,
                            children: [
                              _RoleGridCard(role: 'importer', label: 'Importer', icon: Icons.directions_boat_rounded, selected: _selectedBusinessRole == 'importer', onTap: () => _onRoleSelected('importer')),
                              _RoleGridCard(role: 'broker', label: 'Broker', icon: Icons.handshake_rounded, selected: _selectedBusinessRole == 'broker', onTap: () => _onRoleSelected('broker')),
                              _RoleGridCard(role: 'wholesaler', label: 'Wholesaler', icon: Icons.warehouse_rounded, selected: _selectedBusinessRole == 'wholesaler', onTap: () => _onRoleSelected('wholesaler')),
                              _RoleGridCard(role: 'retailer', label: 'Retailer', icon: Icons.storefront_rounded, selected: _selectedBusinessRole == 'retailer', onTap: () => _onRoleSelected('retailer')),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.xxxl),

                          AppFormSection(
                            title: 'Core Details',
                            icon: Icons.info_outline,
                            children: [
                              _buildTextFormField(
                                controller: _nameController,
                                label: 'Product Name',
                                hintText: 'e.g. Adidas Yeezy',
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
                                child: DropdownMenu<String>(
                                  controller: _categoryController,
                                  label: const Text('Category (Optional)'),
                                  leadingIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                                  dropdownMenuEntries: _categories.map((c) => DropdownMenuEntry(value: c, label: c)).toList(),
                                  expandedInsets: EdgeInsets.zero,
                                  inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
                                child: DropdownMenu<String>(
                                  controller: _brandController,
                                  label: const Text('Brand (Optional)'),
                                  leadingIcon: const Icon(Icons.branding_watermark_outlined, color: AppColors.primary),
                                  dropdownMenuEntries: _brands.map((b) => DropdownMenuEntry(value: b, label: b)).toList(),
                                  expandedInsets: EdgeInsets.zero,
                                  inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          AppFormSection(
                            title: 'Pricing',
                            icon: Icons.sell_outlined,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: _costPriceController,
                                      label: 'Cost (ETB)',
                                      hintText: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                    ),
                                  ),
                                  Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
                                  Expanded(
                                    child: _buildTextFormField(
                                      controller: _sellingPriceController,
                                      label: 'Price (ETB)',
                                      hintText: '0.00',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // ── STEP 1: INVENTORY & SOURCING ─────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFormSection(
                            title: 'Inventory Details',
                            icon: Icons.inventory_2_outlined,
                            children: [
                              if (_selectedBusinessRole == 'wholesaler') ...[
                                _buildDropdownField(
                                  value: _selectedUnit,
                                  items: const ['carton', 'series'],
                                  label: 'Unit of Measurement',
                                  hintText: 'Select Unit',
                                  onChanged: (val) => setState(() => _selectedUnit = val),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                ),
                                const Divider(height: 1),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
                                  child: Row(
                                    children: [
                                      const Text('Unit: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                      Text(_selectedUnit?.toUpperCase() ?? 'PCS', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],

                              _buildTextFormField(
                                controller: _stockQuantityController,
                                label: 'Current Stock Quantity ($_selectedUnit)',
                                hintText: '0',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),

                              if (_selectedUnit?.toLowerCase() == 'carton') ...[
                                const Divider(height: 1),
                                _buildTextFormField(
                                  controller: _itemsPerCartonController,
                                  label: 'Series per Carton',
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

                              if (_selectedBusinessRole != 'retailer') ...[
                                const Divider(height: 1),
                                _buildTextFormField(
                                  controller: _seriesSizeController,
                                  label: 'Pairs per Series',
                                  hintText: '6',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          if (_selectedBusinessRole != 'retailer') ...[
                            AppFormSection(
                              title: 'Sourcing & Tracking',
                              icon: Icons.track_changes_rounded,
                              children: [
                                _buildTextFormField(
                                  controller: _itemNumberController,
                                  label: 'Item Number',
                                  hintText: 'e.g. AB-15',
                                ),
                                if (_selectedBusinessRole != 'importer') ...[
                                  const Divider(height: 1),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final provider = _selectedBusinessRole == 'broker'
                                          ? importerContactsProvider
                                          : _selectedBusinessRole == 'wholesaler'
                                              ? brokerContactsProvider
                                              : wholesalerContactsProvider;
                                      final label = _selectedBusinessRole == 'broker'
                                          ? 'Bought From (Importer)'
                                          : _selectedBusinessRole == 'wholesaler'
                                              ? 'Bought From (Broker)'
                                              : 'Bought From (Wholesaler)';
                                      final asyncContacts = ref.watch(provider);
                                      return asyncContacts.when(
                                        data: (contacts) => contacts.isEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.all(AppDimensions.lg),
                                                child: Text('No $label contacts found. Add them in Contacts first.', style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                                              )
                                            : _buildDropdownField(
                                                value: _selectedSupplierContactId,
                                                items: contacts.map((e) => e.name).toList(),
                                                label: label,
                                                hintText: 'Select Contact',
                                                onChanged: (val) {
                                                  if (val == null) return;
                                                  final contact = contacts.firstWhere((e) => e.name == val);
                                                  setState(() => _selectedSupplierContactId = contact.id);
                                                },
                                              ),
                                        loading: () => const Padding(padding: EdgeInsets.all(AppDimensions.lg), child: LinearProgressIndicator()),
                                        error: (_, __) => const SizedBox(),
                                      );
                                    },
                                  ),
                                ],
                                if (_selectedBusinessRole == 'importer') ...[
                                  const Divider(height: 1),
                                  _buildTextFormField(
                                    controller: _containerRefController,
                                    label: 'Container Reference',
                                    hintText: 'e.g. MSCU-12345',
                                  ),
                                ],
                              ],
                            ),
                          ] else ...[
                            AppFormSection(
                              title: 'Supplier',
                              icon: Icons.local_shipping_outlined,
                              children: [
                                Consumer(
                                  builder: (context, ref, child) {
                                    final asyncContacts = ref.watch(wholesalerContactsProvider);
                                    return asyncContacts.when(
                                      data: (contacts) => contacts.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.all(AppDimensions.lg),
                                              child: Text('No Wholesaler contacts found.', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                                            )
                                          : _buildDropdownField(
                                              value: _selectedSupplierContactId,
                                              items: contacts.map((e) => e.name).toList(),
                                              label: 'Bought From (Wholesaler)',
                                              hintText: 'Select Contact',
                                              onChanged: (val) {
                                                if (val == null) return;
                                                final contact = contacts.firstWhere((e) => e.name == val);
                                                setState(() => _selectedSupplierContactId = contact.id);
                                              },
                                            ),
                                      loading: () => const Padding(padding: EdgeInsets.all(AppDimensions.lg), child: LinearProgressIndicator()),
                                      error: (_, __) => const SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppDimensions.xl),

                          if (_selectedBusinessRole == 'importer' || _selectedBusinessRole == 'wholesaler') ...[
                            AppFormSection(
                              title: 'Color Ratio',
                              icon: Icons.color_lens_outlined,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppDimensions.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Each color\'s value = pairs inside 1 series. Must total to "Pairs per Series".',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: _colors.asMap().entries.map((e) => InputChip(
                                          label: Text('${e.value.color} (${e.value.count})'),
                                          avatar: const Icon(Icons.color_lens, size: 16),
                                          onDeleted: () => setState(() => _colors.removeAt(e.key)),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                        )).toList(),
                                      ),
                                      if (_colors.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Builder(builder: (_) {
                                          final seriesSize = int.tryParse(_seriesSizeController.text.trim()) ?? 6;
                                          final seriesPerCarton = int.tryParse(_itemsPerCartonController.text.trim()) ?? 0;
                                          final colorTotal = _colors.fold<int>(0, (s, c) => s + c.count);
                                          final isValid = colorTotal == seriesSize;
                                          return Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (isValid ? AppColors.positive : AppColors.negative).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: isValid ? AppColors.positive : AppColors.negative, width: 1),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Series total: $colorTotal / $seriesSize pairs ${isValid ? '✓' : '✗'}', style: TextStyle(fontWeight: FontWeight.bold, color: isValid ? AppColors.positive : AppColors.negative, fontSize: 13)),
                                                if (isValid && seriesPerCarton > 0 && _selectedUnit == 'carton') ...[
                                                  const SizedBox(height: 4),
                                                  const Text('Carton Breakdown:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                  ..._colors.map((c) => Text('  • ${c.color}: ${c.count * seriesPerCarton} pairs', style: const TextStyle(fontSize: 12))),
                                                  Text('  Total: ${colorTotal * seriesPerCarton} pairs per carton', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ],
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: _colorNameController,
                                              decoration: const InputDecoration(hintText: 'Color (e.g. Red)', border: OutlineInputBorder()),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              controller: _colorCountController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(hintText: 'Pairs', border: OutlineInputBorder()),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _addColorSlot,
                                            icon: const Icon(Icons.add_circle),
                                            color: AppColors.primary,
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ],
                      ),

                      // ── STEP 2: ADVANCED ──────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFormSection(
                            title: 'Advanced Details',
                            icon: Icons.settings_outlined,
                            children: [
                              _buildTextFormField(
                                controller: _skuController,
                                label: 'SKU',
                                hintText: 'e.g. SKU-001',
                              ),
                              const Divider(height: 1),
                              _buildTextFormField(
                                controller: _barcodeController,
                                label: 'Barcode',
                                hintText: 'e.g. 1234567890123',
                                keyboardType: TextInputType.number,
                              ),
                              if (_selectedBusinessRole != 'retailer') ...[
                                const Divider(height: 1),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextFormField(
                                        controller: _sizeFromController,
                                        label: 'Size From',
                                        hintText: '39',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      ),
                                    ),
                                    Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
                                    Expanded(
                                      child: _buildTextFormField(
                                        controller: _sizeToController,
                                        label: 'Size To',
                                        hintText: '44',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 1),
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
                            const SizedBox(height: AppDimensions.xxxl),
                            const Text(
                              'DANGER ZONE',
                              style: TextStyle(color: AppColors.negative, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _deleteProduct,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.negative),
                                  foregroundColor: AppColors.negative,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, IconData icon, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
            border: Border.all(color: isActive ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant, width: 2),
          ),
          child: Icon(icon, color: isActive ? Colors.white : AppColors.textHint, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2),
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
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: style,
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
        validator: validator,
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<bool> _ensureManageInventoryPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.manageInventory));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'product', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.'), backgroundColor: AppColors.negative));
    return false;
  }
}

class _RoleGridCard extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleGridCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
