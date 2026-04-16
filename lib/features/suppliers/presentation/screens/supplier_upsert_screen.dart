import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

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
    final allowed = await _ensureManagePurchasesPermission(context, ref, attemptedAction: _isEditing ? 'update_supplier' : 'create_supplier', entityId: widget.supplierToEdit?.id);
    if (!allowed) return;

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
      final actorRole = ref.read(currentRoleProvider);

      if (_isEditing) {
        await repo.updateSupplier(widget.supplierToEdit!.copyWith(name: name, phone: phone.isEmpty ? null : phone, email: email.isEmpty ? null : email, address: address.isEmpty ? null : address, termsDays: termsDays, openingBalance: openingBalance, currentBalance: currentBalance, notes: notes.isEmpty ? null : notes, isActive: _isActive));
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'supplier_updated', entityType: 'supplier', entityId: widget.supplierToEdit!.id, message: 'Supplier "$name" was updated.');
      } else {
        await repo.addSupplier(name: name, phone: phone.isEmpty ? null : phone, email: email.isEmpty ? null : email, address: address.isEmpty ? null : address, termsDays: termsDays, openingBalance: openingBalance, currentBalance: currentBalance, notes: notes.isEmpty ? null : notes, isActive: _isActive);
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'supplier_created', entityType: 'supplier', message: 'Supplier "$name" was created.');
      }

      ref.invalidate(allSuppliersProvider);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modify B2B Supplier' : 'Register B2B Supplier'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSupplier,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'UPDATE SUPPLIER' : 'REGISTER SUPPLIER'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
          children: [
            AppFormSection(
              title: 'Business Identity',
              icon: Icons.storefront_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Supplier Name', border: InputBorder.none, hintText: 'ABC Trading'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone', border: InputBorder.none, hintText: '+251...'),
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppDimensions.md),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Address', border: InputBorder.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.xs),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    title: const Text('Active B2B Supplier', style: TextStyle(fontSize: 14)),
                  ),
                )
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Trading Parameters',
              icon: Icons.handshake_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _termsDaysController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Tender Terms (Days)', border: InputBorder.none),
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppDimensions.md),
                          child: TextFormField(
                            controller: _currentBalanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            decoration: const InputDecoration(labelText: 'Current Owed Balance', border: InputBorder.none),
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
                    controller: _openingBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Historic Opening Balance', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Location & Addendums',
              icon: Icons.map_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Factory / Office Address', border: InputBorder.none),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Terms / Logistics Notes', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensureManagePurchasesPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.managePurchases));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'supplier', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}