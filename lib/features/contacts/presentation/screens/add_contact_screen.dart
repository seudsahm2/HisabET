import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/utils/phone_util.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  final ContactRole initialRole;

  const AddContactScreen({super.key, this.initialRole = ContactRole.merchant});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopController = TextEditingController();

  final _supplierEmailController = TextEditingController();
  final _supplierAddressController = TextEditingController();
  final _supplierTermsController = TextEditingController(text: '0');
  final _supplierOpeningBalanceController = TextEditingController(text: '0');
  final _supplierCurrentBalanceController = TextEditingController(text: '0');
  final _supplierNotesController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  String? _foundUserUid;
  late ContactRole _selectedRole;
  bool _supplierAutoFillLocked = false;
  VerificationTimeoutPolicy _verificationTimeoutPolicy = VerificationTimeoutPolicy.autoConfirm;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  bool get _isVerifiedBySystem => _foundUserUid != null;
  bool get _isSupplierAutoFillLocked => _selectedRole == ContactRole.supplier && _isVerifiedBySystem && _supplierAutoFillLocked;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _shopController.dispose();
    _supplierEmailController.dispose();
    _supplierAddressController.dispose();
    _supplierTermsController.dispose();
    _supplierOpeningBalanceController.dispose();
    _supplierCurrentBalanceController.dispose();
    _supplierNotesController.dispose();
    super.dispose();
  }

  Future<void> _searchUserByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final userData = await repo.searchUserByPhone(phone);
      if (userData != null && mounted) {
        final name = userData['name']?.toString();
        final phoneFromProfile = userData['phone']?.toString();
        final shopFromProfile = userData['shopNumber']?.toString() ?? userData['shop']?.toString();
        final emailFromProfile = userData['supplierEmail']?.toString() ?? userData['email']?.toString();
        final addressFromProfile = userData['supplierAddress']?.toString() ?? userData['address']?.toString();
        final notesFromProfile = userData['supplierNotes']?.toString() ?? userData['notes']?.toString();
        final termsFromProfile = userData['supplierTermsDays'] ?? userData['termsDays'];
        final openingFromProfile = userData['supplierOpeningBalance'] ?? userData['openingBalance'];
        final currentFromProfile = userData['supplierCurrentBalance'] ?? userData['currentBalance'];

        if (name != null && name.trim().isNotEmpty) _nameController.text = name;
        if (phoneFromProfile != null && phoneFromProfile.trim().isNotEmpty) _phoneController.text = phoneFromProfile;
        if (shopFromProfile != null && shopFromProfile.trim().isNotEmpty) _shopController.text = shopFromProfile;
        if (emailFromProfile != null && emailFromProfile.trim().isNotEmpty) _supplierEmailController.text = emailFromProfile;
        if (addressFromProfile != null && addressFromProfile.trim().isNotEmpty) _supplierAddressController.text = addressFromProfile;
        if (notesFromProfile != null && notesFromProfile.trim().isNotEmpty) _supplierNotesController.text = notesFromProfile;
        if (termsFromProfile != null) _supplierTermsController.text = termsFromProfile.toString();
        if (openingFromProfile != null) _supplierOpeningBalanceController.text = openingFromProfile.toString();
        if (currentFromProfile != null) _supplierCurrentBalanceController.text = currentFromProfile.toString();

        _foundUserUid = userData['uid']?.toString();
        if (_selectedRole == ContactRole.supplier) {
          _supplierAutoFillLocked = true;
        }
        final foundType = _selectedRole == ContactRole.supplier ? 'supplier' : 'merchant';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found verified $foundType: ${name ?? 'user'}'), backgroundColor: AppColors.positive));
      } else if (mounted) {
        _foundUserUid = null;
        _supplierAutoFillLocked = false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No app user found. Contact will be saved as unverified (trusted by you).')));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContact() async {
    final permission = _selectedRole == ContactRole.supplier ? TeamPermission.managePurchases : TeamPermission.processSales;
    final allowed = await _ensurePermission(context, ref, permission: permission, attemptedAction: 'create_contact_${_selectedRole.name}');
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      final suppliersRepo = ref.read(suppliersRepositoryProvider);
      final actorRole = ref.read(currentRoleProvider);

      final normalizedPhone = _phoneController.text.trim().isNotEmpty ? PhoneUtil.normalize(_phoneController.text.trim()) : null;

      final contactId = await contactsRepo.addContact(
        _nameController.text.trim(),
        normalizedPhone,
        _selectedRole == ContactRole.merchant ? (_shopController.text.trim().isEmpty ? null : _shopController.text.trim()) : null,
        linkedUserUid: _foundUserUid,
        role: _selectedRole,
        verificationTimeoutPolicy: _verificationTimeoutPolicy,
      );

      if (_selectedRole == ContactRole.supplier) {
        await suppliersRepo.upsertSupplierProfile(
          id: contactId,
          name: _nameController.text.trim(),
          phone: normalizedPhone,
          email: _supplierEmailController.text.trim().isEmpty ? null : _supplierEmailController.text.trim(),
          address: _supplierAddressController.text.trim().isEmpty ? null : _supplierAddressController.text.trim(),
          termsDays: int.tryParse(_supplierTermsController.text.trim()) ?? 0,
          openingBalance: Decimal.tryParse(_supplierOpeningBalanceController.text.trim()) ?? Decimal.zero,
          currentBalance: Decimal.tryParse(_supplierCurrentBalanceController.text.trim()) ?? Decimal.zero,
          notes: _supplierNotesController.text.trim().isEmpty ? null : _supplierNotesController.text.trim(),
          isActive: _isActive,
        );
      }

      await ref.read(auditRepositoryProvider).logAction(
        actorRole: actorRole,
        action: 'contact_created',
        entityType: 'contact',
        entityId: contactId,
        message: 'Contact ${_nameController.text.trim()} created as ${_selectedRole.name}.',
      );
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensurePermission(
    BuildContext context,
    WidgetRef ref, {
    required TeamPermission permission,
    required String attemptedAction,
  }) async {
    final allowed = ref.read(hasPermissionProvider(permission));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: 'contact',
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to create contacts.')));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Contact Record'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveContact,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE CONTACT'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
          children: [
            AppFormSection(
              title: 'Role Specification',
              icon: Icons.assignment_ind_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: DropdownButtonFormField<ContactRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Contact Role', border: InputBorder.none),
                    items: const [
                      DropdownMenuItem(value: ContactRole.merchant, child: Text('Merchant (Customer)')),
                      DropdownMenuItem(value: ContactRole.supplier, child: Text('Supplier')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          if (value != ContactRole.supplier) _supplierAutoFillLocked = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Identity',
              icon: Icons.person_rounded,
              children: [
                if (_isVerifiedBySystem)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: DropdownButtonFormField<VerificationTimeoutPolicy>(
                      initialValue: _verificationTimeoutPolicy,
                      decoration: const InputDecoration(labelText: 'Verification Strategy', border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(value: VerificationTimeoutPolicy.autoConfirm, child: Text('Auto-confirm after timeout (48h)')),
                        DropdownMenuItem(value: VerificationTimeoutPolicy.autoExpire, child: Text('Auto-expire after timeout (48h)')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _verificationTimeoutPolicy = value);
                      },
                    ),
                  ),
                if (_isVerifiedBySystem)
                  const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _searchUserByPhone(),
                          decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+251...', border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        onPressed: _searchUserByPhone,
                        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_isVerifiedBySystem)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppStatusBadge.success(label: 'MATCHED APPLICATION USER PROFILE', small: true),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _nameController,
                    readOnly: _isSupplierAutoFillLocked,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: InputDecoration(labelText: _selectedRole == ContactRole.merchant ? 'Customer Profile Name' : 'Supplier Business Name', border: InputBorder.none),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            
            if (_selectedRole == ContactRole.merchant)
              AppFormSection(
                title: 'Location Data',
                icon: Icons.storefront_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: TextFormField(
                      controller: _shopController,
                      decoration: const InputDecoration(labelText: 'Shop Location', hintText: 'Merkato Tera, B-12', border: InputBorder.none),
                    ),
                  ),
                ],
              )
            else ...[
              if (_isSupplierAutoFillLocked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Autofill fields are locked by matching profile', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    TextButton(onPressed: () => setState(() => _supplierAutoFillLocked = false), child: const Text('Unlock')),
                  ],
                ),
              AppFormSection(
                title: 'Business Info',
                icon: Icons.business_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: TextFormField(
                      controller: _supplierEmailController,
                      readOnly: _isSupplierAutoFillLocked,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address', border: InputBorder.none),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: TextFormField(
                      controller: _supplierAddressController,
                      readOnly: _isSupplierAutoFillLocked,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Office Address', border: InputBorder.none),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              AppFormSection(
                title: 'B2B Trade Status',
                icon: Icons.handshake_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.xs),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      title: const Text('Active B2B Supplier', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Include in purchase flows and tender network'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              AppFormSection(
                title: 'Financial Parameters',
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _supplierTermsController,
                            readOnly: _isSupplierAutoFillLocked,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Terms (Days)', border: InputBorder.none),
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.divider),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppDimensions.md),
                            child: TextFormField(
                              controller: _supplierOpeningBalanceController,
                              readOnly: _isSupplierAutoFillLocked,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Opening Balance', border: InputBorder.none),
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
                      controller: _supplierCurrentBalanceController,
                      readOnly: _isSupplierAutoFillLocked,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Current Balance (Owed)', border: InputBorder.none),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: TextFormField(
                      controller: _supplierNotesController,
                      readOnly: _isSupplierAutoFillLocked,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Delivery Term Notes', border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 80), // Keyboard scroll padding
          ],
        ),
      ),
    );
  }
}
