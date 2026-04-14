import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';

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
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
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
      _qtyPerCartonController.text =
          (tx.qtyPerCarton ?? _metadataInt(tx.metadata, 'qtyPerCarton'))?.toString() ?? '';
      _unitPriceController.text =
          (tx.unitPrice ?? _metadataDecimal(tx.metadata, 'unitPrice'))?.toString() ?? '';
      _selectedPaymentMethod = tx.metadata?['paymentMethod']?.toString() ?? 'Cash';
    }
  }

  bool get _isGoods =>
      _currentType == TransactionType.goodsGiven ||
      _currentType == TransactionType.goodsTaken;

  bool get _isGive =>
      _currentType == TransactionType.goodsGiven ||
      _currentType == TransactionType.paymentGiven;

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
          (product) =>
              product != null &&
              desc.isNotEmpty &&
              product.name.trim().toLowerCase() == desc,
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
    if (!_formKey.currentState!.validate()) return;

    if (_isGoodsGive) {
      if (_selectedInventoryProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select an inventory item to give.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cartons = _currentCartons();
      if (cartons <= 0 || cartons > _selectedInventoryProduct!.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cartons must be between 1 and ${_selectedInventoryProduct!.stockQuantity}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final amount = Decimal.parse(_amountController.text.trim());
      final repo = ref.read(transactionsRepositoryProvider);
      final metadata = _buildMetadata();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final referenceId = _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim();

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
      } else {
        await repo.addTransaction(
          contactId: widget.contactId,
          type: _currentType,
          amount: amount,
          date: _selectedDate,
          description: description,
          metadata: metadata,
          referenceId: referenceId,
        );
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTypeSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentButton('Goods / Item', _isGoods, () => _updateType(isGoods: true)),
          _buildSegmentButton('Cash / Payment', !_isGoods, () => _updateType(isGoods: false)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildBigButton(
            label: _isGoods ? 'I GAVE' : 'PAID',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.give,
            isActive: _isGive,
            onTap: () => _updateType(isGive: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBigButton(
            label: _isGoods ? 'I TOOK' : 'RECEIVED',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.take,
            isActive: !_isGive,
            onTap: () => _updateType(isGive: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBigButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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
    final inventoryProducts = inventoryProductsAsync.maybeWhen(
      data: (products) => products.where((p) => p.stockQuantity > 0).toList(),
      orElse: () => <ProductModel>[],
    );
    _tryAutoSelectInventoryProduct(inventoryProducts);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Transaction', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTypeSegment(),
                      const SizedBox(height: 20),
                      _buildDirectionToggle(),
                      const SizedBox(height: 24),
                      if (currentContact != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentContact.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildContactVerificationBadge(currentContact.verificationStatus),
                          ],
                        ),
                        if (currentContact.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currentContact.phoneNumber!,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _isGive
                            ? (_isGoods ? 'You gave items to them' : 'You paid them money')
                            : (_isGoods ? 'You took items from them' : 'They paid you money'),
                        style: TextStyle(
                          color: _activeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        readOnly: _isGoodsGive,
                        decoration: InputDecoration(
                          labelText: _isGoods ? 'Description' : 'Description (Optional)',
                          prefixIcon: const Icon(Icons.notes_outlined, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        readOnly: _isGoodsGive,
                        decoration: const InputDecoration(
                          labelText: 'Ref #',
                          prefixIcon: Icon(Icons.tag, color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFFFAFAFA),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey),
                                  filled: true,
                                  fillColor: Color(0xFFFAFAFA),
                                ),
                                child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isGoods ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            if (_isGoods) ...[
                              if (_isGoodsGive) ...[
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedInventoryProductId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select from inventory',
                                    prefixIcon: Icon(Icons.inventory_2_outlined),
                                  ),
                                  items: inventoryProducts
                                      .map(
                                        (p) => DropdownMenuItem<String>(
                                          value: p.id,
                                          child: Text(
                                            '${p.name} (${p.stockQuantity} cartons)',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final found = inventoryProducts.firstWhere(
                                      (p) => p.id == value,
                                    );
                                    setState(() => _selectInventoryProduct(found));
                                  },
                                  validator: (value) {
                                    if (!_isGoodsGive) return null;
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please select an inventory item';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: _isGoodsGive
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'Cartons',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: (_selectedInventoryProduct == null ||
                                                                _currentCartons() <= 0)
                                                            ? null
                                                            : () => _setCartons(_currentCartons() - 1),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints.tightFor(
                                                          width: 20,
                                                          height: 20,
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        iconSize: 16,
                                                        icon: const Icon(Icons.remove_circle_outline),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      SizedBox(
                                                        width: 18,
                                                        child: Center(
                                                          child: Text(
                                                            '${_currentCartons()}',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      IconButton(
                                                        onPressed: (_selectedInventoryProduct == null)
                                                            ? null
                                                            : () => _setCartons(
                                                                  _currentCartons() + 1,
                                                                  maxStock: _selectedInventoryProduct!.stockQuantity,
                                                                ),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints.tightFor(
                                                          width: 20,
                                                          height: 20,
                                                        ),
                                                        visualDensity: VisualDensity.compact,
                                                        iconSize: 16,
                                                        icon: const Icon(Icons.add_circle_outline),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (_isGoodsGive && _selectedInventoryProduct != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'max ${_selectedInventoryProduct!.stockQuantity}',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : TextFormField(
                                            controller: _cartonsController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            onChanged: (_) => _recalculateGoodsTotal(),
                                            decoration: const InputDecoration(
                                              labelText: 'Cartons',
                                              hintText: '5',
                                              isDense: true,
                                            ),
                                            validator: (val) {
                                              final value = int.tryParse((val ?? '').trim()) ?? 0;
                                              if (value <= 0) return 'Required';
                                              return null;
                                            },
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _qtyPerCartonController,
                                      readOnly: _isGoodsGive,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (_) => _recalculateGoodsTotal(),
                                      decoration: const InputDecoration(
                                        labelText: 'Qty / Carton',
                                        hintText: '12',
                                        isDense: true,
                                      ),
                                      validator: (val) {
                                        final value = int.tryParse((val ?? '').trim()) ?? 0;
                                        if (value <= 0) return 'Required';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _unitPriceController,
                                      readOnly: _isGoodsGive,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                      ],
                                      onChanged: (_) => _recalculateGoodsTotal(),
                                      decoration: const InputDecoration(
                                        labelText: 'Individual Price',
                                        hintText: 'Price per single item',
                                        isDense: true,
                                      ),
                                      validator: (val) {
                                        final price = Decimal.tryParse((val ?? '').trim()) ?? Decimal.zero;
                                        if (price <= Decimal.zero) return 'Required';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Total items: ${int.tryParse(_cartonsController.text.trim()) == null || int.tryParse(_qtyPerCartonController.text.trim()) == null ? 0 : (int.parse(_cartonsController.text.trim()) * int.parse(_qtyPerCartonController.text.trim()))}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(
                                      fontSize: _isGoods ? 30 : 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    readOnly: _isGoods,
                                    decoration: InputDecoration(
                                      hintText: _isGoods ? 'Calculated total' : '0.00',
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      filled: false,
                                      prefixText: 'ETB ',
                                      prefixStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    validator: (val) {
                                      final price = Decimal.tryParse((val ?? '').trim()) ?? Decimal.zero;
                                      if (price <= Decimal.zero) {
                                        return 'Amount must be greater than 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (!_isGoods)
                                  IconButton(
                                    icon: const Icon(Icons.payments_outlined, color: Colors.grey, size: 30),
                                    onPressed: null,
                                  ),
                              ],
                            ),
                            if (_isGoods)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Calculated from cartons x qty/carton x individual price. Cash/payment entries stay amount-only.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isGoods) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: _activeColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'CBE', child: Text('CBE Transfer')),
                            DropdownMenuItem(value: 'BOA', child: Text('Abyssinia (BOA)')),
                            DropdownMenuItem(value: 'Telebirr', child: Text('Telebirr')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE TRANSACTION',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactVerificationBadge(ContactVerificationStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case ContactVerificationStatus.verified:
        icon = Icons.verified;
        color = AppColors.give;
        break;
      case ContactVerificationStatus.pending:
        icon = Icons.schedule;
        color = const Color(0xFFB26A00);
        break;
      case ContactVerificationStatus.expired:
        icon = Icons.cancel_outlined;
        color = AppColors.take;
        break;
      case ContactVerificationStatus.unverified:
        icon = Icons.circle_outlined;
        color = AppColors.textSecondary;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: status == ContactVerificationStatus.unverified
            ? const Text(
                'Unverified',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  icon,
                  color: color,
                  size: 13,
                ),
              ),
      ),
    );
  }
}
