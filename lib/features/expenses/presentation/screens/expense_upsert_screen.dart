import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:intl/intl.dart';

class ExpenseUpsertScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expenseToEdit;

  const ExpenseUpsertScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<ExpenseUpsertScreen> createState() => _ExpenseUpsertScreenState();
}

class _ExpenseUpsertScreenState extends ConsumerState<ExpenseUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiptPathController = TextEditingController();
  final _recurrenceDaysController = TextEditingController();
  String? _categoryId;
  String _paymentMethod = 'cash';
  DateTime _spentAt = DateTime.now();
  bool _isRecurring = false;
  bool _isLoading = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseToEdit;
    if (expense == null) return;

    _categoryId = expense.categoryId;
    _titleController.text = expense.title;
    _vendorController.text = expense.vendor ?? '';
    _amountController.text = expense.amount.toString();
    _descriptionController.text = expense.description ?? '';
    _receiptPathController.text = expense.receiptPath ?? '';
    _recurrenceDaysController.text = expense.recurrenceDays?.toString() ?? '';
    _paymentMethod = expense.paymentMethod;
    _spentAt = expense.spentAt;
    _isRecurring = expense.isRecurring;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _vendorController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptPathController.dispose();
    _recurrenceDaysController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an expense category.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expensesRepositoryProvider);
      final amount = Decimal.tryParse(_amountController.text.trim()) ?? Decimal.zero;
      final title = _titleController.text.trim();
      final vendor = _vendorController.text.trim();
      final description = _descriptionController.text.trim();
      final receiptPath = _receiptPathController.text.trim();
      final recurrenceDays = int.tryParse(_recurrenceDaysController.text.trim());

      if (_isEditing) {
        await repo.updateExpense(
          widget.expenseToEdit!.copyWith(
            categoryId: _categoryId,
            title: title,
            vendor: vendor.isEmpty ? null : vendor,
            amount: amount,
            spentAt: _spentAt,
            paymentMethod: _paymentMethod,
            description: description.isEmpty ? null : description,
            receiptPath: receiptPath.isEmpty ? null : receiptPath,
            isRecurring: _isRecurring,
            recurrenceDays: _isRecurring ? recurrenceDays : null,
          ),
        );
      } else {
        await repo.addExpense(
          categoryId: _categoryId!,
          title: title,
          vendor: vendor.isEmpty ? null : vendor,
          amount: amount,
          spentAt: _spentAt,
          paymentMethod: _paymentMethod,
          description: description.isEmpty ? null : description,
          receiptPath: receiptPath.isEmpty ? null : receiptPath,
          isRecurring: _isRecurring,
          recurrenceDays: _isRecurring ? recurrenceDays : null,
        );
      }

      ref.invalidate(allExpensesProvider);

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
    final categoriesAsync = ref.watch(allExpenseCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Create an expense category first.'));
          }

          _categoryId ??= categories.first.id;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Expense title'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vendorController,
                      decoration: const InputDecoration(labelText: 'Vendor / Payee (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: const InputDecoration(labelText: 'Amount', prefixText: 'ETB '),
                      validator: (value) {
                        final amount = Decimal.tryParse((value ?? '').trim()) ?? Decimal.zero;
                        if (amount <= Decimal.zero) return 'Amount must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'mobile', child: Text('Mobile Money')),
                        DropdownMenuItem(value: 'credit', child: Text('Credit / Pay Later')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _paymentMethod = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _spentAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _spentAt = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(DateFormat('MMM d, yyyy').format(_spentAt)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _receiptPathController,
                      decoration: const InputDecoration(labelText: 'Receipt / File Path (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                      title: const Text('Recurring expense'),
                      subtitle: const Text('Enable for costs that repeat every fixed number of days.'),
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _recurrenceDaysController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Repeat every N days'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isEditing ? 'UPDATE EXPENSE' : 'SAVE EXPENSE'),
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