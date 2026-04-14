import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expensesRepositoryProvider);
      final name = _nameController.text.trim();
      final colorHex = _colorController.text.trim().replaceFirst('#', '');
      final notes = _notesController.text.trim();

      if (_isEditing) {
        await repo.updateCategory(
          widget.categoryToEdit!.copyWith(
            name: name,
            colorHex: colorHex,
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          ),
        );
      } else {
        await repo.addCategory(
          name: name,
          colorHex: colorHex,
          notes: notes.isEmpty ? null : notes,
          isActive: _isActive,
        );
      }

      ref.invalidate(allExpenseCategoriesProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Category name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(labelText: 'Color hex', prefixText: '#'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active category'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isEditing ? 'UPDATE CATEGORY' : 'SAVE CATEGORY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}