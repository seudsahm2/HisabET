import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ExpenseCategoryUpsertScreen extends ConsumerStatefulWidget {
  final ExpenseCategoryModel? categoryToEdit;

  const ExpenseCategoryUpsertScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<ExpenseCategoryUpsertScreen> createState() => _ExpenseCategoryUpsertScreenState();
}

class _ExpenseCategoryUpsertScreenState extends ConsumerState<ExpenseCategoryUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: 'FF8A3D');
  final _notesController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    final category = widget.categoryToEdit;
    if (category == null) return;

    _nameController.text = category.name;
    _colorController.text = category.colorHex;
    _notesController.text = category.notes ?? '';
    _isActive = category.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final allowed = await _ensureManageExpensesPermission(
      context,
      ref,
      attemptedAction: _isEditing ? 'update_expense_category' : 'create_expense_category',
      entityId: widget.categoryToEdit?.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expensesRepositoryProvider);
      final name = _nameController.text.trim();
      final colorHex = _colorController.text.trim().replaceFirst('#', '');
      final notes = _notesController.text.trim();
      final actorRole = ref.read(currentRoleProvider);

      if (_isEditing) {
        await repo.updateCategory(
          widget.categoryToEdit!.copyWith(
            name: name,
            colorHex: colorHex,
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          ),
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'expense_category_updated',
          entityType: 'expense_category',
          entityId: widget.categoryToEdit!.id,
          message: 'Expense category "$name" was updated.',
        );
      } else {
        await repo.addCategory(
          name: name,
          colorHex: colorHex,
          notes: notes.isEmpty ? null : notes,
          isActive: _isActive,
        );
        await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'expense_category_created',
          entityType: 'expense_category',
          message: 'Expense category "$name" was created.',
        );
      }

      ref.invalidate(allExpenseCategoriesProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      entityType: 'expense_category',
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isEditing ? 'UPDATE CATEGORY' : 'SAVE CATEGORY'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
          children: [
            AppFormSection(
              title: 'Configuration',
              icon: Icons.palette_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Tag Name', border: InputBorder.none, hintText: 'E.g. Travel, Salary, Rent'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color Hex Code', border: InputBorder.none, prefixText: '#'),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Tag Description', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Visibility',
              icon: Icons.visibility_rounded,
              children: [
                SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text('Active Category', style: AppTextStyles.cardTitle),
                  subtitle: const Text('Show this category when selecting in expenses.'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}