import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

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
  String? _foundUserUid;
  ContactRole _selectedRole = ContactRole.merchant;
  bool _supplierAutoFillLocked = false;
  VerificationTimeoutPolicy _verificationTimeoutPolicy =
      VerificationTimeoutPolicy.autoConfirm;

  bool get _isVerifiedBySystem => _foundUserUid != null;
  bool get _isSupplierAutoFillLocked =>
      _selectedRole == ContactRole.supplier &&
      _isVerifiedBySystem &&
      _supplierAutoFillLocked;

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
        final shopFromProfile = userData['shopNumber']?.toString() ??
            userData['shop']?.toString();
        final emailFromProfile = userData['supplierEmail']?.toString() ??
            userData['email']?.toString();
        final addressFromProfile = userData['supplierAddress']?.toString() ??
            userData['address']?.toString();
        final notesFromProfile = userData['supplierNotes']?.toString() ??
            userData['notes']?.toString();
        final termsFromProfile =
            userData['supplierTermsDays'] ?? userData['termsDays'];
        final openingFromProfile =
            userData['supplierOpeningBalance'] ?? userData['openingBalance'];
        final currentFromProfile =
            userData['supplierCurrentBalance'] ?? userData['currentBalance'];

        if (name != null && name.trim().isNotEmpty) {
          _nameController.text = name;
        }
        if (phoneFromProfile != null && phoneFromProfile.trim().isNotEmpty) {
          _phoneController.text = phoneFromProfile;
        }
        if (shopFromProfile != null && shopFromProfile.trim().isNotEmpty) {
          _shopController.text = shopFromProfile;
        }
        if (emailFromProfile != null && emailFromProfile.trim().isNotEmpty) {
          _supplierEmailController.text = emailFromProfile;
        }
        if (addressFromProfile != null && addressFromProfile.trim().isNotEmpty) {
          _supplierAddressController.text = addressFromProfile;
        }
        if (notesFromProfile != null && notesFromProfile.trim().isNotEmpty) {
          _supplierNotesController.text = notesFromProfile;
        }
        if (termsFromProfile != null) {
          _supplierTermsController.text = termsFromProfile.toString();
        }
        if (openingFromProfile != null) {
          _supplierOpeningBalanceController.text = openingFromProfile.toString();
        }
        if (currentFromProfile != null) {
          _supplierCurrentBalanceController.text = currentFromProfile.toString();
        }

        _foundUserUid = userData['uid']?.toString();
        if (_selectedRole == ContactRole.supplier) {
          _supplierAutoFillLocked = true;
        }
        final foundType = _selectedRole == ContactRole.supplier
            ? 'supplier'
            : 'merchant';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found verified $foundType: ${name ?? 'user'}'),
            backgroundColor: AppColors.give,
          ),
        );
      } else if (mounted) {
        _foundUserUid = null;
        _supplierAutoFillLocked = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No app user found. Contact will be saved as unverified (trusted by you).',
            ),
          ),
        );
      }
    } catch (_) {
      // Keep silent; user can still create local contact.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      final suppliersRepo = ref.read(suppliersRepositoryProvider);

      final normalizedPhone = _phoneController.text.trim().isNotEmpty
          ? PhoneUtil.normalize(_phoneController.text.trim())
          : null;

      final contactId = await contactsRepo.addContact(
        _nameController.text.trim(),
        normalizedPhone,
        _selectedRole == ContactRole.merchant
            ? (_shopController.text.trim().isEmpty ? null : _shopController.text.trim())
            : null,
        linkedUserUid: _foundUserUid,
        role: _selectedRole,
        verificationTimeoutPolicy: _verificationTimeoutPolicy,
      );

      if (_selectedRole == ContactRole.supplier) {
        await suppliersRepo.upsertSupplierProfile(
          id: contactId,
          name: _nameController.text.trim(),
          phone: normalizedPhone,
          email: _supplierEmailController.text.trim().isEmpty
              ? null
              : _supplierEmailController.text.trim(),
          address: _supplierAddressController.text.trim().isEmpty
              ? null
              : _supplierAddressController.text.trim(),
          termsDays: int.tryParse(_supplierTermsController.text.trim()) ?? 0,
          openingBalance:
              Decimal.tryParse(_supplierOpeningBalanceController.text.trim()) ?? Decimal.zero,
          currentBalance:
              Decimal.tryParse(_supplierCurrentBalanceController.text.trim()) ?? Decimal.zero,
          notes: _supplierNotesController.text.trim().isEmpty
              ? null
              : _supplierNotesController.text.trim(),
          isActive: true,
        );
      }

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Contact',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _buildInputCard(
                  label: 'Contact Type',
                  icon: Icons.badge_outlined,
                  child: DropdownButtonFormField<ContactRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ContactRole.merchant,
                        child: Text('Merchant'),
                      ),
                      DropdownMenuItem(
                        value: ContactRole.supplier,
                        child: Text('Supplier'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          if (value != ContactRole.supplier) {
                            _supplierAutoFillLocked = false;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputCard(
                  label: _selectedRole == ContactRole.merchant
                      ? 'Merchant Name'
                      : 'Business Name',
                  icon: Icons.person_outline_rounded,
                  child: TextFormField(
                    controller: _nameController,
                    readOnly: _isSupplierAutoFillLocked,
                    decoration: InputDecoration(
                      hintText: _selectedRole == ContactRole.merchant
                          ? 'Mr. Abebe'
                          : 'ABC Trading',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputCard(
                  label: 'Phone Number',
                  icon: Icons.phone_android_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.search,
                              onFieldSubmitted: (_) => _searchUserByPhone(),
                              decoration: const InputDecoration(
                                hintText: '+251...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _searchUserByPhone,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isVerifiedBySystem
                            ? 'Verified by system: matched app user profile.'
                            : 'If not found, this contact is unverified and trusted by you.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isVerifiedBySystem
                              ? AppColors.give
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isVerifiedBySystem)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInputCard(
                      label: 'Pending Verification Policy',
                      icon: Icons.timer_outlined,
                      child: DropdownButtonFormField<VerificationTimeoutPolicy>(
                        initialValue: _verificationTimeoutPolicy,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: VerificationTimeoutPolicy.autoConfirm,
                            child: Text('Auto-confirm after timeout (48h)'),
                          ),
                          DropdownMenuItem(
                            value: VerificationTimeoutPolicy.autoExpire,
                            child: Text('Auto-expire after timeout (48h)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _verificationTimeoutPolicy = value);
                        },
                      ),
                    ),
                  ),
                if (_selectedRole == ContactRole.merchant)
                  _buildInputCard(
                    label: 'Shop / Location (Optional)',
                    icon: Icons.storefront_outlined,
                    child: TextFormField(
                      controller: _shopController,
                      decoration: const InputDecoration(
                        hintText: 'Merkato Tera, B-12',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                else ...[
                  if (_isSupplierAutoFillLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Supplier fields are locked from verified profile match.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.give,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _supplierAutoFillLocked = false;
                            }),
                            child: const Text('Unlock'),
                          ),
                        ],
                      ),
                    ),
                  _buildInputCard(
                    label: 'Email (Optional)',
                    icon: Icons.email_outlined,
                    child: TextFormField(
                      controller: _supplierEmailController,
                      readOnly: _isSupplierAutoFillLocked,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'supplier@company.com',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputCard(
                    label: 'Address (Optional)',
                    icon: Icons.location_on_outlined,
                    child: TextFormField(
                      controller: _supplierAddressController,
                      readOnly: _isSupplierAutoFillLocked,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Addis Ababa',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputCard(
                          label: 'Terms (Days)',
                          icon: Icons.schedule,
                          child: TextFormField(
                            controller: _supplierTermsController,
                            readOnly: _isSupplierAutoFillLocked,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputCard(
                          label: 'Opening Balance (Optional)',
                          icon: Icons.account_balance_wallet_outlined,
                          child: TextFormField(
                            controller: _supplierOpeningBalanceController,
                            readOnly: _isSupplierAutoFillLocked,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  const SizedBox(height: 20),
                  _buildInputCard(
                    label: 'Current Balance (Optional)',
                    icon: Icons.balance,
                    child: TextFormField(
                      controller: _supplierCurrentBalanceController,
                      readOnly: _isSupplierAutoFillLocked,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tip: leave balances as 0 when adding a new supplier unless you are migrating old payables.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _buildInputCard(
                    label: 'Notes (Optional)',
                    icon: Icons.notes_outlined,
                    child: TextFormField(
                      controller: _supplierNotesController,
                      readOnly: _isSupplierAutoFillLocked,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Delivery terms, contact notes',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SAVE CONTACT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
