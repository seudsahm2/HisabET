import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';

class SupplierUpsertScreen extends ConsumerStatefulWidget {
  final SupplierModel? supplierToEdit;

  const SupplierUpsertScreen({super.key, this.supplierToEdit});

  @override
  ConsumerState<SupplierUpsertScreen> createState() => _SupplierUpsertScreenState();
}

class _SupplierUpsertScreenState extends ConsumerState<SupplierUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _termsDaysController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0');
  final _currentBalanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.supplierToEdit != null;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplierToEdit;
    if (supplier == null) return;

    _nameController.text = supplier.name;
    _phoneController.text = supplier.phone ?? '';
    _emailController.text = supplier.email ?? '';
    _addressController.text = supplier.address ?? '';
    _termsDaysController.text = supplier.termsDays.toString();
    _openingBalanceController.text = supplier.openingBalance.toString();
    _currentBalanceController.text = supplier.currentBalance.toString();
    _notesController.text = supplier.notes ?? '';
    _isActive = supplier.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _termsDaysController.dispose();
    _openingBalanceController.dispose();
    _currentBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(suppliersRepositoryProvider);
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();
      final termsDays = int.tryParse(_termsDaysController.text.trim()) ?? 0;
      final openingBalance = Decimal.tryParse(_openingBalanceController.text.trim()) ?? Decimal.zero;
      final currentBalance = Decimal.tryParse(_currentBalanceController.text.trim()) ?? Decimal.zero;
      final notes = _notesController.text.trim();

      if (_isEditing) {
        await repo.updateSupplier(
          widget.supplierToEdit!.copyWith(
            name: name,
            phone: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            address: address.isEmpty ? null : address,
            termsDays: termsDays,
            openingBalance: openingBalance,
            currentBalance: currentBalance,
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          ),
        );
      } else {
        await repo.addSupplier(
          name: name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
          address: address.isEmpty ? null : address,
          termsDays: termsDays,
          openingBalance: openingBalance,
          currentBalance: currentBalance,
          notes: notes.isEmpty ? null : notes,
          isActive: _isActive,
        );
      }

      ref.invalidate(allSuppliersProvider);

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit Supplier' : 'New Supplier'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldCard(
                  label: 'Supplier Name',
                  icon: Icons.business,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'ABC Trading',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _fieldCard(
                        label: 'Phone',
                        icon: Icons.phone,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+251 ...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _fieldCard(
                        label: 'Terms (days)',
                        icon: Icons.schedule,
                        child: TextFormField(
                          controller: _termsDaysController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fieldCard(
                  label: 'Email',
                  icon: Icons.email,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'supplier@example.com',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _fieldCard(
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  child: TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'City, sub-city, area',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _fieldCard(
                        label: 'Opening Balance',
                        icon: Icons.account_balance_wallet_outlined,
                        child: TextFormField(
                          controller: _openingBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _fieldCard(
                        label: 'Current Balance',
                        icon: Icons.balance,
                        child: TextFormField(
                          controller: _currentBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fieldCard(
                  label: 'Notes',
                  icon: Icons.notes,
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Terms, contact preferences, delivery notes',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active supplier'),
                  subtitle: const Text('Use this supplier in purchase flows.'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSupplier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isEditing ? 'UPDATE SUPPLIER' : 'SAVE SUPPLIER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldCard({required String label, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}