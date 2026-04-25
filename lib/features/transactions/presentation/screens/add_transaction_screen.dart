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
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String contactId;
  final TransactionType type;
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({
    super.key,
    required this.contactId,
    required this.type,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _cartonsController = TextEditingController();
  final _qtyPerCartonController = TextEditingController();
  final _unitPriceController = TextEditingController();

  late TransactionType _currentType;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod = 'Cash';
  String? _selectedInventoryProductId;
  ProductModel? _selectedInventoryProduct;
  bool _didAutoSelectInventoryProduct = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.transactionToEdit?.type ?? widget.type;

    final tx = widget.transactionToEdit;
    if (tx != null) {
      _selectedDate = tx.date;
      _amountController.text = tx.amount.toString();
      _descriptionController.text = tx.description ?? '';
      _referenceController.text = tx.referenceId ?? '';
      _cartonsController.text = (tx.cartons ?? _metadataInt(tx.metadata, 'cartons'))?.toString() ?? '';
      _qtyPerCartonController.text = (tx.qtyPerCarton ?? _metadataInt(tx.metadata, 'qtyPerCarton'))?.toString() ?? '';
      _unitPriceController.text = (tx.unitPrice ?? _metadataDecimal(tx.metadata, 'unitPrice'))?.toString() ?? '';
      _selectedPaymentMethod = tx.metadata?['paymentMethod']?.toString() ?? 'Cash';
    }
  }

  bool get _isGoods => _currentType == TransactionType.goodsGiven || _currentType == TransactionType.goodsTaken;
  bool get _isGive => _currentType == TransactionType.goodsGiven || _currentType == TransactionType.paymentGiven;
  bool get _isGoodsGive => _isGoods && _isGive;
  Color get _activeColor => _isGive ? AppColors.give : AppColors.take;

  static int? _metadataInt(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return null;
    final value = metadata[key];
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static Decimal? _metadataDecimal(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return null;
    final value = metadata[key];
    if (value == null) return null;
    return Decimal.tryParse(value.toString());
  }

  void _updateType({bool? isGoods, bool? isGive}) {
    final useGoods = isGoods ?? _isGoods;
    final useGive = isGive ?? _isGive;

    setState(() {
      _currentType = useGoods
          ? (useGive ? TransactionType.goodsGiven : TransactionType.goodsTaken)
          : (useGive ? TransactionType.paymentGiven : TransactionType.paymentReceived);

      if (!_isGoods) {
        _cartonsController.clear();
        _qtyPerCartonController.clear();
        _unitPriceController.clear();
        _selectedInventoryProductId = null;
        _selectedInventoryProduct = null;
      }
    });
  }

  int _currentCartons() {
    return int.tryParse(_cartonsController.text.trim()) ?? 0;
  }

  void _setCartons(int value, {int? maxStock}) {
    var next = value;
    if (next < 0) next = 0;
    if (maxStock != null && maxStock >= 0 && next > maxStock) {
      next = maxStock;
    }
    _cartonsController.text = next.toString();
    _recalculateGoodsTotal();
    setState(() {});
  }

  void _selectInventoryProduct(ProductModel product) {
    _selectedInventoryProductId = product.id;
    _selectedInventoryProduct = product;

    _descriptionController.text = product.name;
    _referenceController.text = product.sku ?? '';

    final qtyPerCarton = product.itemsPerCarton ?? 1;
    _qtyPerCartonController.text = qtyPerCarton.toString();
    _unitPriceController.text = product.sellingPrice.toString();

    final preferredCartons = product.stockQuantity > 0 ? 1 : 0;
    _setCartons(preferredCartons, maxStock: product.stockQuantity);
  }

  void _tryAutoSelectInventoryProduct(List<ProductModel> products) {
    if (_didAutoSelectInventoryProduct || !_isGoodsGive) return;
    _didAutoSelectInventoryProduct = true;

    if (products.isEmpty) return;

    final desc = _descriptionController.text.trim().toLowerCase();
    final ref = _referenceController.text.trim().toLowerCase();

    ProductModel? matched;
    for (final product in products) {
      final sku = (product.sku ?? '').trim().toLowerCase();
      if (ref.isNotEmpty && sku.isNotEmpty && sku == ref) {
        matched = product;
        break;
      }
    }

    matched ??= products.cast<ProductModel?>().firstWhere(
      (product) => product != null && desc.isNotEmpty && product.name.trim().toLowerCase() == desc,
      orElse: () => null,
    );

    if (matched != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectInventoryProduct(matched!));
      });
    }
  }

  void _recalculateGoodsTotal() {
    if (!_isGoods) return;
    final cartons = int.tryParse(_cartonsController.text.trim()) ?? 0;
    final qtyPerCarton = int.tryParse(_qtyPerCartonController.text.trim()) ?? 0;
    final unitPrice = Decimal.tryParse(_unitPriceController.text.trim()) ?? Decimal.zero;

    if (cartons <= 0 || qtyPerCarton <= 0 || unitPrice <= Decimal.zero) {
      _amountController.text = '';
      return;
    }

    final total = unitPrice * Decimal.fromInt(cartons * qtyPerCarton);
    _amountController.text = total.toString();
  }

  Map<String, dynamic>? _buildMetadata() {
    if (_isGoods) {
      final cartons = int.tryParse(_cartonsController.text.trim()) ?? 0;
      final qtyPerCarton = int.tryParse(_qtyPerCartonController.text.trim()) ?? 0;
      final unitPrice = Decimal.tryParse(_unitPriceController.text.trim()) ?? Decimal.zero;

      return {
        'cartons': cartons,
        'qtyPerCarton': qtyPerCarton,
        'unitPrice': unitPrice.toString(),
      };
    }

    return {
      'paymentMethod': _selectedPaymentMethod,
    };
  }

  Future<void> _saveTransaction() async {
    final allowed = await _ensureProcessSalesPermission(
      context, ref,
      attemptedAction: widget.transactionToEdit != null ? 'update_transaction' : 'create_transaction',
      entityId: widget.transactionToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;

    if (_isGoodsGive) {
      if (_selectedInventoryProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an inventory item to give.'), backgroundColor: AppColors.negative));
        return;
      }
      final cartons = _currentCartons();
      if (cartons <= 0 || cartons > _selectedInventoryProduct!.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cartons must be between 1 and ${_selectedInventoryProduct!.stockQuantity}.'), backgroundColor: AppColors.negative));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final amount = Decimal.parse(_amountController.text.trim());
      final repo = ref.read(transactionsRepositoryProvider);
      final actorRole = ref.read(currentRoleProvider);
      final metadata = _buildMetadata();
      final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
      final referenceId = _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim();

      if (widget.transactionToEdit != null) {
        await repo.updateTransaction(
          widget.transactionToEdit!.copyWith(
            type: _currentType,
            amount: amount,
            date: _selectedDate,
            description: description,
            referenceId: referenceId,
            metadata: metadata,
            cartons: _isGoods ? int.tryParse(_cartonsController.text.trim()) : null,
            qtyPerCarton: _isGoods ? int.tryParse(_qtyPerCartonController.text.trim()) : null,
            unitPrice: _isGoods ? Decimal.tryParse(_unitPriceController.text.trim()) : null,
          ),
        );
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'transaction_updated', entityType: 'transaction', entityId: widget.transactionToEdit!.id, message: 'Transaction ${widget.transactionToEdit!.id} was updated.');
      } else {
        await repo.addTransaction(contactId: widget.contactId, type: _currentType, amount: amount, date: _selectedDate, description: description, metadata: metadata, referenceId: referenceId);
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'transaction_created', entityType: 'transaction', entityId: widget.contactId, message: 'A new ${_currentType.name} transaction was created.');
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensureProcessSalesPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'transaction', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to process sales transactions.')));
    }
    return false;
  }

  Widget _buildDirectionToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildBigButton(
            label: _isGoods ? 'I GAVE' : 'I PAID',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.give,
            isActive: _isGive,
            onTap: () => _updateType(isGive: true),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _buildBigButton(
            label: _isGoods ? 'I TOOK' : 'I RECEIVED',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.take,
            isActive: !_isGive,
            onTap: () => _updateType(isGive: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton({required String label, required IconData icon, required Color color, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          border: Border.all(color: isActive ? color : AppColors.divider, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : AppColors.textSecondary, size: 24),
            const SizedBox(width: AppDimensions.sm),
            Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactVerificationBadge(ContactVerificationStatus status) {
    switch (status) {
      case ContactVerificationStatus.verified:
        return AppStatusBadge.success(label: 'Verified', small: true);
      case ContactVerificationStatus.pending:
        return AppStatusBadge.warning(label: 'Pending', small: true);
      case ContactVerificationStatus.expired:
        return AppStatusBadge.danger(label: 'Expired', small: true);
      case ContactVerificationStatus.unverified:
        return AppStatusBadge.neutral(label: 'Unverified', small: true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _cartonsController.dispose();
    _qtyPerCartonController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProductsAsync = ref.watch(allProductsProvider);
    final contactAsync = ref.watch(contactProvider(widget.contactId));
    final currentContact = contactAsync.valueOrNull;
    final inventoryProducts = inventoryProductsAsync.maybeWhen(data: (products) => products.where((p) => p.stockQuantity > 0).toList(), orElse: () => <ProductModel>[]);
    _tryAutoSelectInventoryProduct(inventoryProducts);

    final String typeTitle = _isGive
        ? (_isGoods ? 'You gave items to them' : 'You paid them money')
        : (_isGoods ? 'You took items from them' : 'They paid you money');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(widget.transactionToEdit == null ? 'Record Transaction' : 'Edit Transaction')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: AppFilterChips<bool>(
                          options: const [true, false],
                          selected: _isGoods,
                          labelBuilder: (isG) => isG ? 'Goods / Items' : 'Cash / Payment',
                          onSelected: (val) => _updateType(isGoods: val),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      _buildDirectionToggle(),
                      const SizedBox(height: AppDimensions.xl),
                      
                      if (currentContact != null)
                        AppCard(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentContact.name, style: AppTextStyles.cardTitle),
                                  if (currentContact.phoneNumber != null)
                                    Text(currentContact.phoneNumber!, style: AppTextStyles.cardSubtitle),
                                ],
                              ),
                              _buildContactVerificationBadge(currentContact.verificationStatus),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppDimensions.lg),
                      Text(typeTitle, style: TextStyle(color: _activeColor, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: AppDimensions.md),

                      AppFormSection(
                        title: 'Log Metrics',
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            readOnly: _isGoodsGive,
                            decoration: InputDecoration(labelText: _isGoods ? 'Description' : 'Description (Optional)', prefixIcon: const Icon(Icons.notes_rounded)),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          TextFormField(
                            controller: _referenceController,
                            readOnly: _isGoodsGive,
                            decoration: const InputDecoration(labelText: 'Reference ID', prefixIcon: Icon(Icons.tag_rounded)),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (date != null) setState(() => _selectedDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Logged Date', prefixIcon: Icon(Icons.calendar_today_rounded)),
                              child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      if (_isGoods) ...[
                        AppFormSection(
                          title: 'Item Breakdowns',
                          children: [
                            if (_isGoodsGive) ...[
                              DropdownButtonFormField<String>(
                                initialValue: _selectedInventoryProductId,
                                decoration: const InputDecoration(labelText: 'Select from inventory', prefixIcon: Icon(Icons.inventory_2_rounded)),
                                items: inventoryProducts.map((p) => DropdownMenuItem<String>(value: p.id, child: Text('${p.name} (${p.stockQuantity} cartons)'))).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  final found = inventoryProducts.firstWhere((p) => p.id == value);
                                  setState(() => _selectInventoryProduct(found));
                                },
                                validator: (val) {
                                  if (!_isGoodsGive) return null;
                                  if (val == null || val.trim().isEmpty) return 'Selection required';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimensions.md),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _cartonsController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) => _recalculateGoodsTotal(),
                                    decoration: const InputDecoration(labelText: 'Cartons'),
                                    validator: (val) => (int.tryParse((val ?? '').trim()) ?? 0) <= 0 ? 'Req.' : null,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _qtyPerCartonController,
                                    readOnly: _isGoodsGive,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (_) => _recalculateGoodsTotal(),
                                    decoration: const InputDecoration(labelText: 'Qty / Ctn'),
                                    validator: (val) => (int.tryParse((val ?? '').trim()) ?? 0) <= 0 ? 'Req.' : null,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _unitPriceController,
                                    readOnly: _isGoodsGive,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (_) => _recalculateGoodsTotal(),
                                    decoration: const InputDecoration(labelText: 'Unit Price'),
                                    validator: (val) => (Decimal.tryParse((val ?? '').trim()) ?? Decimal.zero) <= Decimal.zero ? 'Req.' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.xl),
                      ],

                      AppFormSection(
                        title: 'Settlement Amount',
                        children: [
                          TextFormField(
                            controller: _amountController,
                            readOnly: _isGoods,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            style: TextStyle(color: _activeColor, fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Total Value (ETB)',
                              labelStyle: const TextStyle(fontSize: 16),
                              prefixIcon: Icon(Icons.payments_rounded, color: _activeColor),
                            ),
                            validator: (val) {
                              final v = Decimal.tryParse((val ?? '').trim()) ?? Decimal.zero;
                              if (v <= Decimal.zero) return 'Invalid amount';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xl * 2), // Padding for button
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          widget.transactionToEdit == null ? "Save Execution" : "Update Protocol",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
