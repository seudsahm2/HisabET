import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

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
    final allowed = await _ensureManageExpensesPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_expense' : 'create_expense',
      entityId: widget.expenseToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an expense category.')));
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
      final actorRole = ref.read(currentRoleProvider);

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
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'expense_updated',
          entityType: 'expense',
          entityId: widget.expenseToEdit!.id,
          message: 'Expense "$title" was updated.',
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
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'expense_created',
          entityType: 'expense',
          message: 'Expense "$title" was created.',
        );
      }

      ref.invalidate(allExpensesProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allExpenseCategoriesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'UPDATE EXPENSE' : 'SAVE EXPENSE'),
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const AppEmptyState(icon: Icons.category_rounded, title: 'No Categories Generated', subtitle: 'You must add a category before recording expenses.');
          }

          _categoryId ??= categories.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
              children: [
                AppFormSection(
                  title: 'Core Details',
                  icon: Icons.article_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: const InputDecoration(labelText: 'Expense Title', border: InputBorder.none, hintText: 'e.g. Office Supplies'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.negative),
                              decoration: const InputDecoration(labelText: 'Total Amount', prefixText: 'ETB ', border: InputBorder.none),
                              validator: (value) {
                                final amount = Decimal.tryParse((value ?? '').trim()) ?? Decimal.zero;
                                if (amount <= Decimal.zero) return 'Must be > 0';
                                return null;
                              },
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.divider),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(left: AppDimensions.md),
                              child: DropdownButtonFormField<String>(
                                initialValue: _categoryId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Category', border: InputBorder.none),
                                items: categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() => _categoryId = value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Payment Method', border: InputBorder.none),
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
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.xl),
                AppFormSection(
                  title: 'Date & Tracking',
                  icon: Icons.event_available_rounded,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: _spentAt, firstDate: DateTime(2020), lastDate: DateTime(2100));
                                if (date != null) setState(() => _spentAt = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Spent On', border: InputBorder.none),
                                child: Text(DateFormat('MMM d, yyyy').format(_spentAt)),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.divider),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: AppDimensions.md),
                              child: TextFormField(
                                controller: _vendorController,
                                decoration: const InputDecoration(labelText: 'Vendor / Payee', border: InputBorder.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: TextFormField(
                        controller: _receiptPathController,
                        decoration: const InputDecoration(labelText: 'Receipt Drive Path (Optional)', border: InputBorder.none, hintText: 'Cloud URI / File path'),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Ledger Description', border: InputBorder.none),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.xl),
                AppFormSection(
                  title: 'Automation',
                  icon: Icons.sync_rounded,
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      title: Text('Recurring Expense', style: AppTextStyles.cardTitle),
                      subtitle: const Text('Automatically repeat this cost in reports.'),
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                    ),
                    if (_isRecurring) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                        child: TextFormField(
                          controller: _recurrenceDaysController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Repeat interval (Days)', border: InputBorder.none),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _ensureManageExpensesPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.manageExpenses));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: 'expense',
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}