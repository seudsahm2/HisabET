import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_line_item_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class PurchaseOrderUpsertScreen extends ConsumerStatefulWidget {
  final PurchaseOrderModel? orderToEdit;

  const PurchaseOrderUpsertScreen({super.key, this.orderToEdit});

  @override
  ConsumerState<PurchaseOrderUpsertScreen> createState() => _PurchaseOrderUpsertScreenState();
}

class _PurchaseOrderUpsertScreenState extends ConsumerState<PurchaseOrderUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _supplierId;
  DateTime _orderDate = DateTime.now();
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _lineItemsLoaded = false;
  final List<_PurchaseOrderLineDraft> _lineItems = [];

  bool get _isEditing => widget.orderToEdit != null;

  @override
  void initState() {
    super.initState();
    final order = widget.orderToEdit;
    if (order == null) return;

    _supplierId = order.supplierId;
    _orderDate = order.orderDate;
    _dueDate = order.dueDate;
    _notesController.text = order.notes ?? '';
    Future.microtask(_loadExistingLineItems);
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final line in _lineItems) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingLineItems() async {
    if (_lineItemsLoaded || widget.orderToEdit == null) return;

    final repo = ref.read(purchaseOrdersRepositoryProvider);
    final products = await ref.read(allProductsProvider.future);
    final items = await repo.getPurchaseOrderLineItems(widget.orderToEdit!.id);

    if (!mounted) return;

    setState(() {
      _lineItems
        ..clear()
        ..addAll(
          items.map((item) {
            final product = products.firstWhere(
              (product) => product.id == item.productId,
              orElse: () => products.isNotEmpty ? products.first : ProductModel(
                id: item.productId,
                name: item.productName,
                sku: item.sku,
                barcode: null,
                category: null,
                brand: null,
                unit: item.unit ?? 'pcs',
                itemsPerCarton: item.itemsPerCarton,
                costPrice: item.unitCost,
                sellingPrice: item.unitCost,
                stockQuantity: 0,
                reorderLevel: 0,
                isActive: true,
                createdAt: item.createdAt,
                updatedAt: item.createdAt,
              ),
            );
            return _PurchaseOrderLineDraft.fromExisting(product, item);
          }),
        );
      _lineItemsLoaded = true;
    });
  }

  Decimal get _subtotal => _lineItems.fold<Decimal>(
        Decimal.zero,
        (sum, item) => sum + item.lineTotal,
      );

  void _addLineItem(ProductModel product) {
    setState(() {
      _lineItems.add(_PurchaseOrderLineDraft.fromProduct(product));
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems[index].dispose();
      _lineItems.removeAt(index);
    });
  }

  Future<void> _saveOrder() async {
    final allowed = await _ensureManagePurchasesPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_purchase_order' : 'create_purchase_order',
      entityId: widget.orderToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) return;
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one purchase line item.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      final suppliersRepo = ref.read(suppliersRepositoryProvider);
      final notes = _notesController.text.trim();
      final subtotal = _subtotal;
      final lineItems = _lineItems.map((line) => line.toInput()).toList();
      final actorRole = ref.read(currentRoleProvider);

      final contacts = await ref.read(allContactsProvider.future);
      ContactModel? selectedSupplier;
      for (final contact in contacts) {
        if (contact.id == _supplierId) {
          selectedSupplier = contact;
          break;
        }
      }

      if (selectedSupplier == null) {
        throw Exception('Selected supplier contact not found.');
      }

      // Keep compatibility with purchase_orders foreign key to suppliers table.
      await suppliersRepo.upsertSupplierProfile(
        id: selectedSupplier.id,
        name: selectedSupplier.name,
        phone: selectedSupplier.phoneNumber,
        address: selectedSupplier.shopNumber,
        termsDays: 0,
        openingBalance: Decimal.zero,
        currentBalance: selectedSupplier.netBalance,
        isActive: true,
      );

      if (_isEditing) {
        await repo.updatePurchaseOrder(
          widget.orderToEdit!.copyWith(
            supplierId: _supplierId,
            orderDate: _orderDate,
            dueDate: _dueDate,
            subtotal: subtotal,
            notes: notes.isEmpty ? null : notes,
          ),
          lineItems: lineItems,
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'purchase_order_updated',
          entityType: 'purchase_order',
          entityId: widget.orderToEdit!.id,
          message: 'Purchase order ${widget.orderToEdit!.id} was updated.',
        );
      } else {
        await repo.addPurchaseOrder(
          supplierId: _supplierId!,
          orderDate: _orderDate,
          dueDate: _dueDate,
          subtotal: subtotal,
          notes: notes.isEmpty ? null : notes,
          lineItems: lineItems,
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'purchase_order_created',
          entityType: 'purchase_order',
          message: 'A new purchase order was created for supplier $_supplierId.',
        );
      }

      ref.invalidate(allPurchaseOrdersProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensureManagePurchasesPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.managePurchases));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: 'purchase_order',
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Purchase Order' : 'New Purchase Order'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Subtotal', style: AppTextStyles.cardSubtitle),
                    Text('ETB $_subtotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveOrder,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'UPDATE ORDER' : 'SAVE ORDER'),
              ),
            ],
          ),
        ),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contacts) {
          final suppliers = contacts.where((contact) => contact.role == ContactRole.supplier || contact.role == ContactRole.both).toList();

          if (suppliers.isEmpty) {
            return const AppEmptyState(icon: Icons.person_off_outlined, title: 'No Suppliers Found', subtitle: 'You need to create a supplier contact before generating an order.');
          }

          _supplierId ??= suppliers.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
              children: [
                AppFormSection(
                  title: 'Order Setup',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: DropdownButtonFormField<String>(
                        value: _supplierId,
                        items: suppliers.map((supplier) => DropdownMenuItem(value: supplier.id, child: Text(supplier.name))).toList(),
                        onChanged: (value) => setState(() => _supplierId = value),
                        decoration: const InputDecoration(labelText: 'Supplier', border: InputBorder.none),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: _orderDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                                if (date != null) setState(() => _orderDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Order Date', border: InputBorder.none),
                                child: Text(DateFormat('MMM d, yyyy').format(_orderDate)),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.divider),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: _dueDate ?? _orderDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                                if (date != null) setState(() => _dueDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Due Date', border: InputBorder.none),
                                child: Text(_dueDate == null ? 'Optional' : DateFormat('MMM d, yyyy').format(_dueDate!)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.xl),
                productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                  data: (products) {
                    final availableProducts = products.where((product) => product.isActive).toList();
                    for (final line in _lineItems) {
                      if (availableProducts.every((product) => product.id != line.product.id)) availableProducts.insert(0, line.product);
                    }

                    if (!_lineItemsLoaded && _isEditing) return const SizedBox.shrink();

                    return AppFormSection(
                      title: 'Order Line Items',
                      icon: Icons.list_alt_rounded,
                      children: [
                        if (_lineItems.isEmpty)
                           const Padding(
                             padding: EdgeInsets.all(AppDimensions.xl),
                             child: AppEmptyState(icon: Icons.inventory_2_outlined, title: 'No items in order', subtitle: 'Tap below to add products.'),
                           )
                        else
                          ..._lineItems.asMap().entries.map((entry) => _PurchaseOrderLineItemTile(
                                draft: entry.value,
                                products: availableProducts,
                                onChanged: () => setState(() {}),
                                onRemove: () => _removeLineItem(entry.key),
                              )),
                        
                        Padding(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          child: OutlinedButton.icon(
                            onPressed: availableProducts.isEmpty ? null : () => _addLineItem(availableProducts.first),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product to Order'),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.xl),
                AppFormSection(
                  title: 'Order Notes',
                  icon: Icons.edit_note_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Internal notes or supplier instructions...', border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseOrderLineDraft {
  ProductModel product;
  final TextEditingController quantityController;
  final TextEditingController unitCostController;

  _PurchaseOrderLineDraft._(this.product, this.quantityController, this.unitCostController);

  factory _PurchaseOrderLineDraft.fromProduct(ProductModel product) {
    return _PurchaseOrderLineDraft._(product, TextEditingController(text: '1'), TextEditingController(text: product.costPrice.toString()));
  }

  factory _PurchaseOrderLineDraft.fromExisting(ProductModel product, PurchaseOrderLineItemModel item) {
    return _PurchaseOrderLineDraft._(product, TextEditingController(text: item.quantity.toString()), TextEditingController(text: item.unitCost.toString()));
  }

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;
  Decimal get unitCost => Decimal.tryParse(unitCostController.text.trim()) ?? Decimal.zero;
  Decimal get lineTotal => unitCost * Decimal.fromInt(quantity);

  PurchaseOrderLineInput toInput() {
    return PurchaseOrderLineInput(
      productId: product.id,
      productName: product.name,
      sku: product.sku,
      unit: product.unit,
      itemsPerCarton: product.itemsPerCarton,
      unitCost: unitCost,
      quantity: quantity,
      lineTotal: lineTotal,
    );
  }

  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
  }
}

class _PurchaseOrderLineItemTile extends StatelessWidget {
  final _PurchaseOrderLineDraft draft;
  final List<ProductModel> products;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PurchaseOrderLineItemTile({required this.draft, required this.products, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.background)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.xl, AppDimensions.sm, AppDimensions.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProductModel>(
                    value: draft.product,
                    decoration: const InputDecoration(labelText: 'Select Product', border: InputBorder.none),
                    items: products.map((product) => DropdownMenuItem(value: product, child: Text(product.name))).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      draft.product = value;
                      draft.unitCostController.text = value.costPrice.toString();
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.xl, 0, AppDimensions.xl, AppDimensions.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: draft.quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Quantity', border: InputBorder.none),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.divider),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppDimensions.md),
                    child: TextFormField(
                      controller: draft.unitCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: const InputDecoration(labelText: 'Unit Cost', border: InputBorder.none),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                  child: Text('ETB ${draft.lineTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}