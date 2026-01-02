import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/core/utils/money_util.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String contactId;
  final TransactionType type;
  final TransactionModel? transactionToEdit; // Added for Edit Mode

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

  // Controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

  // State
  late TransactionType _currentType;
  bool _isLoading = false;
  bool _showCalculator = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    _currentType = widget.transactionToEdit?.type ?? widget.type;

    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _selectedDate = tx.date;
      _amountController.text = tx.amount.toString();
      if (tx.description != null) _descriptionController.text = tx.description!;
      if (tx.referenceId != null) _referenceController.text = tx.referenceId!;

      if (tx.metadata != null) {
        if (tx.metadata!['paymentMethod'] != null) {
          _selectedPaymentMethod = tx.metadata!['paymentMethod'];
        }
        if (tx.metadata!['quantity'] != null) {
          _quantityController.text = tx.metadata!['quantity'].toString();
          _showCalculator = true;
        }
        if (tx.metadata!['unitPrice'] != null) {
          _unitPriceController.text = tx.metadata!['unitPrice'].toString();
          _showCalculator = true;
        }
      }
    }
  }

  // --- Logic Helpers ---

  bool get _isGoods =>
      _currentType == TransactionType.goodsGiven ||
      _currentType == TransactionType.goodsTaken;

  bool get _isGive =>
      _currentType == TransactionType.goodsGiven ||
      _currentType == TransactionType.paymentGiven;

  // Green for Give, Red for Take
  Color get _activeColor => _isGive ? AppColors.give : AppColors.take;

  void _updateType({bool? isGoods, bool? isGive}) {
    final useGoods = isGoods ?? _isGoods;
    final useGive = isGive ?? _isGive;

    setState(() {
      if (useGoods) {
        _currentType = useGive
            ? TransactionType.goodsGiven
            : TransactionType.goodsTaken;
      } else {
        _currentType = useGive
            ? TransactionType.paymentGiven
            : TransactionType.paymentReceived;
      }
    });
  }

  void _calculateTotal() {
    if (_quantityController.text.isNotEmpty &&
        _unitPriceController.text.isNotEmpty) {
      try {
        final quantity = int.parse(_quantityController.text);
        final unitPrice = Decimal.parse(_unitPriceController.text);
        final total = MoneyUtil.calculateTotal(quantity, unitPrice);
        _amountController.text = total.toString();
      } catch (_) {
        // Ignore errors
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final amount = Decimal.parse(_amountController.text.trim());

      Map<String, dynamic>? metadata;

      // Add Calculator Metadata
      if (_showCalculator &&
          _quantityController.text.isNotEmpty &&
          _unitPriceController.text.isNotEmpty) {
        metadata = {
          'quantity': int.parse(_quantityController.text),
          'unitPrice': _unitPriceController.text,
        };
      }

      // Add Payment Metadata
      if (!_isGoods) {
        metadata ??= {};
        metadata['paymentMethod'] = _selectedPaymentMethod;
      }

      if (widget.transactionToEdit != null) {
        // UPDATE MODE
        final updatedTx = widget.transactionToEdit!.copyWith(
          type: _currentType,
          amount: amount,
          date: _selectedDate,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          metadata: metadata,
          referenceId: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
        );
        await repo.updateTransaction(updatedTx);
      } else {
        // CREATE MODE
        await repo.addTransaction(
          contactId: widget.contactId,
          type: _currentType,
          amount: amount,
          date: _selectedDate,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          metadata: metadata,
          referenceId: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
        );
      }

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

  // --- UI Components ---

  Widget _buildTypeSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            'Goods / Item',
            _isGoods,
            () => _updateType(isGoods: true),
          ),
          _buildSegmentButton(
            'Cash / Payment',
            !_isGoods,
            () => _updateType(isGoods: false),
          ),
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
                      color: Colors.black.withOpacity(0.05),
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
        // GIVE Button
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
        // TAKE Button
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(color: Colors.black),
        ),
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
                      const SizedBox(height: 30),

                      // Semantic Header
                      Text(
                        _isGive
                            ? (_isGoods
                                  ? 'You gave items to them'
                                  : 'You paid them money')
                            : (_isGoods
                                  ? 'You took items from them'
                                  : 'They paid you money'),
                        style: TextStyle(
                          color: _activeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Calculator / Amount Section
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _showCalculator
                              ? const Color(0xFFF8FAFC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            if (_showCalculator) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _calculateTotal(),
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        hintText: '10',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'x',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _unitPriceController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => _calculateTotal(),
                                      decoration: const InputDecoration(
                                        labelText: 'Price',
                                        hintText: '500',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                            ],

                            // Main Amount Field
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    readOnly:
                                        _showCalculator, // Read-only if calculator is active
                                    decoration: InputDecoration(
                                      hintText: '0.00',
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
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => _showCalculator = !_showCalculator,
                                  ),
                                  icon: Icon(
                                    Icons.calculate_outlined,
                                    color: _showCalculator
                                        ? _activeColor
                                        : Colors.grey,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Optional Details
                      if (!_isGoods) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
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
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Text('Cash'),
                            ),
                            DropdownMenuItem(
                              value: 'CBE',
                              child: Text('CBE Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'BOA',
                              child: Text('Abyssinia (BOA)'),
                            ),
                            DropdownMenuItem(
                              value: 'Telebirr',
                              child: Text('Telebirr'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedPaymentMethod = v),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: const Icon(
                            Icons.notes_outlined,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (d != null)
                                  setState(() => _selectedDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFFAFAFA),
                                ),
                                child: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _referenceController,
                              decoration: const InputDecoration(
                                labelText: 'Ref #',
                                prefixIcon: Icon(Icons.tag, color: Colors.grey),
                                filled: true,
                                fillColor: Color(0xFFFAFAFA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Save Button Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
}
