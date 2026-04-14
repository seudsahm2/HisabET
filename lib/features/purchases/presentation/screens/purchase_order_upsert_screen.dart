import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_line_item_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';

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
      // Suppliers are now managed from contacts, so we mirror the selected contact.
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
      } else {
        await repo.addPurchaseOrder(
          supplierId: _supplierId!,
          orderDate: _orderDate,
          dueDate: _dueDate,
          subtotal: subtotal,
          notes: notes.isEmpty ? null : notes,
          lineItems: lineItems,
        );
      }

      ref.invalidate(allPurchaseOrdersProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Purchase Order' : 'New Purchase Order'),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contacts) {
          final suppliers = contacts
              .where(
                (contact) =>
                    contact.role == ContactRole.supplier ||
                    contact.role == ContactRole.both,
              )
              .toList();

          if (suppliers.isEmpty) {
            return const Center(child: Text('Create a supplier contact first.'));
          }

          _supplierId ??= suppliers.first.id;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _supplierId,
                      items: suppliers
                          .map(
                            (supplier) => DropdownMenuItem(
                              value: supplier.id,
                              child: Text(supplier.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _supplierId = value),
                      decoration: const InputDecoration(labelText: 'Supplier'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _orderDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => _orderDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Order Date'),
                              child: Text(_orderDate.toString().split(' ').first),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? _orderDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) setState(() => _dueDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Due Date'),
                              child: Text(_dueDate?.toString().split(' ').first ?? '-'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    productsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                      data: (products) {
                        final availableProducts = products.where((product) => product.isActive).toList();
                        for (final line in _lineItems) {
                          if (availableProducts.every((product) => product.id != line.product.id)) {
                            availableProducts.insert(0, line.product);
                          }
                        }

                        if (!_lineItemsLoaded && _isEditing) {
                          return const SizedBox.shrink();
                        }

                        if (_lineItems.isEmpty) {
                          return Column(
                            children: [
                              const Text('No line items yet.'),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: availableProducts.isEmpty
                                      ? null
                                      : () => _addLineItem(availableProducts.first),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Line Item'),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            ..._lineItems.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PurchaseOrderLineItemCard(
                                  draft: entry.value,
                                  products: availableProducts,
                                  onChanged: () => setState(() {}),
                                  onRemove: () => _removeLineItem(entry.key),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: availableProducts.isEmpty
                                    ? null
                                    : () => _addLineItem(availableProducts.first),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Line Item'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Subtotal'),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('ETB $_subtotal'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isEditing ? 'UPDATE ORDER' : 'SAVE ORDER'),
                      ),
                    ),
                  ],
                ),
              ),
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

  _PurchaseOrderLineDraft._(
    this.product,
    this.quantityController,
    this.unitCostController,
  );

  factory _PurchaseOrderLineDraft.fromProduct(ProductModel product) {
    return _PurchaseOrderLineDraft._(
      product,
      TextEditingController(text: '1'),
      TextEditingController(text: product.costPrice.toString()),
    );
  }

  factory _PurchaseOrderLineDraft.fromExisting(ProductModel product, PurchaseOrderLineItemModel item) {
    return _PurchaseOrderLineDraft._(
      product,
      TextEditingController(text: item.quantity.toString()),
      TextEditingController(text: item.unitCost.toString()),
    );
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

class _PurchaseOrderLineItemCard extends StatelessWidget {
  final _PurchaseOrderLineDraft draft;
  final List<ProductModel> products;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PurchaseOrderLineItemCard({
    required this.draft,
    required this.products,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ProductModel>(
                  value: draft.product,
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
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
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: draft.unitCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(labelText: 'Unit Cost'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total: ETB ${draft.lineTotal}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}