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

enum _LookupMethod { phone, email }

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
  final _emailLookupController = TextEditingController();
  final _shopController = TextEditingController();

  final _supplierAddressController = TextEditingController();
  final _supplierTermsController = TextEditingController(text: '0');
  final _supplierOpeningBalanceController = TextEditingController(text: '0');
  final _supplierCurrentBalanceController = TextEditingController(text: '0');
  final _supplierNotesController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  String? _foundUserUid;
  String? _verificationMethod; // 'phone' or 'email'
  late ContactRole _selectedRole;
  bool _supplierAutoFillLocked = false;
  _LookupMethod _lookupMethod = _LookupMethod.phone;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    // Pre-select based on legacy initialRole
    if (widget.initialRole == ContactRole.supplier) _isSupplier = true;
  }

  bool _isRetailer = false;
  bool _isWholesaler = false;
  bool _isBroker = false;
  bool _isSupplier = false;

  bool get _isVerifiedBySystem => _foundUserUid != null;
  bool get _isSupplierAutoFillLocked => _selectedRole == ContactRole.supplier && _isVerifiedBySystem && _supplierAutoFillLocked;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailLookupController.dispose();
    _shopController.dispose();
    _supplierAddressController.dispose();
    _supplierTermsController.dispose();
    _supplierOpeningBalanceController.dispose();
    _supplierCurrentBalanceController.dispose();
    _supplierNotesController.dispose();
    super.dispose();
  }

  void _applyUserData(Map<String, dynamic> userData) {
    final name = userData['name']?.toString();
    final phoneFromProfile = userData['phone']?.toString();
    final shopFromProfile = userData['shopNumber']?.toString() ?? userData['shop']?.toString();
    final addressFromProfile = userData['supplierAddress']?.toString() ?? userData['address']?.toString();
    final notesFromProfile = userData['supplierNotes']?.toString() ?? userData['notes']?.toString();
    final termsFromProfile = userData['supplierTermsDays'] ?? userData['termsDays'];
    final openingFromProfile = userData['supplierOpeningBalance'] ?? userData['openingBalance'];
    final currentFromProfile = userData['supplierCurrentBalance'] ?? userData['currentBalance'];

    if (name != null && name.trim().isNotEmpty) _nameController.text = name;
    if (phoneFromProfile != null && phoneFromProfile.trim().isNotEmpty) _phoneController.text = phoneFromProfile;
    if (shopFromProfile != null && shopFromProfile.trim().isNotEmpty) _shopController.text = shopFromProfile;
    if (addressFromProfile != null && addressFromProfile.trim().isNotEmpty) _supplierAddressController.text = addressFromProfile;
    if (notesFromProfile != null && notesFromProfile.trim().isNotEmpty) _supplierNotesController.text = notesFromProfile;
    if (termsFromProfile != null) _supplierTermsController.text = termsFromProfile.toString();
    if (openingFromProfile != null) _supplierOpeningBalanceController.text = openingFromProfile.toString();
    if (currentFromProfile != null) _supplierCurrentBalanceController.text = currentFromProfile.toString();

    _foundUserUid = userData['uid']?.toString();
    if (_selectedRole == ContactRole.supplier) {
      _supplierAutoFillLocked = true;
    }
  }

  Future<void> _searchUserByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final userData = await repo.searchUserByPhone(phone);
      if (userData != null && mounted) {
        _applyUserData(userData);
        _verificationMethod = 'phone';
        final foundType = _selectedRole == ContactRole.supplier ? 'supplier' : 'merchant';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found verified $foundType: ${userData['name'] ?? 'user'}'), backgroundColor: AppColors.positive),
        );
      } else if (mounted) {
        _foundUserUid = null;
        _verificationMethod = null;
        _supplierAutoFillLocked = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app user found with this phone. Contact saved as unverified.')),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUserByEmail() async {
    final email = _emailLookupController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final userData = await repo.searchUserByEmail(email);
      if (userData != null && mounted) {
        _applyUserData(userData);
        _verificationMethod = 'email';
        final foundType = _selectedRole == ContactRole.supplier ? 'supplier' : 'merchant';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found verified $foundType: ${userData['name'] ?? 'user'}'), backgroundColor: AppColors.positive),
        );
      } else if (mounted) {
        _foundUserUid = null;
        _verificationMethod = null;
        _supplierAutoFillLocked = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app user found with this email. Contact saved as unverified.')),
        );
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
        role: _isSupplier ? ContactRole.supplier : ContactRole.merchant,
        verificationMethod: _verificationMethod,
        isRetailer: _isRetailer,
        isWholesaler: _isWholesaler,
        isBroker: _isBroker,
        isSupplier: _isSupplier,
      );

      if (_selectedRole == ContactRole.supplier) {
        await suppliersRepo.upsertSupplierProfile(
          id: contactId,
          name: _nameController.text.trim(),
          phone: normalizedPhone,
          email: _emailLookupController.text.trim().isEmpty ? null : _emailLookupController.text.trim(),
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
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.negative,
          ),
        );
      }
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
              title: 'Business Roles',
              icon: Icons.assignment_ind_rounded,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.xl, AppDimensions.sm, AppDimensions.xl, 0),
                  child: Text(
                    'Select all roles that apply to this contact:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Retailer'),
                  subtitle: const Text('Sells goods to end consumers'),
                  value: _isRetailer,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isRetailer = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Wholesaler'),
                  subtitle: const Text('Buys in bulk and resells'),
                  value: _isWholesaler,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isWholesaler = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Broker'),
                  subtitle: const Text('Acts as intermediary / agent'),
                  value: _isBroker,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isBroker = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Supplier'),
                  subtitle: const Text('Provides goods or services to you'),
                  value: _isSupplier,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() {
                    _isSupplier = v ?? false;
                    _selectedRole = _isSupplier ? ContactRole.supplier : ContactRole.merchant;
                    if (!_isSupplier) _supplierAutoFillLocked = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Identity',
              icon: Icons.person_rounded,
              children: [


                // --- Lookup Method Toggle ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: Row(
                    children: [
                      const Text('Search by:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: AppDimensions.md),
                      ChoiceChip(
                        label: const Text('Phone'),
                        selected: _lookupMethod == _LookupMethod.phone,
                        onSelected: (_) => setState(() {
                          _lookupMethod = _LookupMethod.phone;
                          _foundUserUid = null;
                          _verificationMethod = null;
                        }),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      ChoiceChip(
                        label: const Text('Email'),
                        selected: _lookupMethod == _LookupMethod.email,
                        onSelected: (_) => setState(() {
                          _lookupMethod = _LookupMethod.email;
                          _foundUserUid = null;
                          _verificationMethod = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // --- Phone lookup ---
                if (_lookupMethod == _LookupMethod.phone)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('phone_lookup_input'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchUserByPhone(),
                            decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+251...', border: InputBorder.none),
                          ),
                        ),
                        IconButton(
                          onPressed: _searchUserByPhone,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.search_rounded, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                // --- Email lookup ---
                if (_lookupMethod == _LookupMethod.email)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('email_lookup_input'),
                            controller: _emailLookupController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchUserByEmail(),
                            decoration: const InputDecoration(labelText: 'Email Address', hintText: 'user@example.com', border: InputBorder.none),
                          ),
                        ),
                        IconButton(
                          onPressed: _searchUserByEmail,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.search_rounded, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 1),

                // --- Verified badge (shows method) ---
                if (_isVerifiedBySystem)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppStatusBadge.success(
                        label: _verificationMethod == 'email'
                            ? 'VERIFIED BY EMAIL'
                            : 'VERIFIED BY PHONE',
                        small: true,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                  child: TextFormField(
                    controller: _nameController,
                    readOnly: _isSupplierAutoFillLocked,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: _selectedRole == ContactRole.merchant ? 'Customer Profile Name' : 'Supplier Business Name',
                      border: InputBorder.none,
                    ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
