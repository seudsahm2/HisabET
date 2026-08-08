import 'package:decimal/decimal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/utils/phone_util.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

/// Where the form's data came from, which decides what the user may edit.
enum _LookupState {
  /// Nothing looked up yet.
  idle,

  /// Network call in flight.
  searching,

  /// Matched a real HisabET account — details are theirs, so they are locked.
  found,

  /// Looked and found nobody; everything is open for manual entry.
  notFound,
}

enum _LookupMethod { email, phone }

class AddContactScreen extends ConsumerStatefulWidget {
  final ContactRole initialRole;

  const AddContactScreen({super.key, this.initialRole = ContactRole.merchant});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  /// One box for the lookup, whichever identifier it holds. Two controllers
  /// meant switching method silently kept the other field's value and searched
  /// something the user could no longer see.
  final _lookupController = TextEditingController();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopController = TextEditingController();

  final _supplierAddressController = TextEditingController();
  final _supplierTermsController = TextEditingController(text: '0');
  final _supplierOpeningBalanceController = TextEditingController(text: '0');
  final _supplierCurrentBalanceController = TextEditingController(text: '0');
  final _supplierNotesController = TextEditingController();

  _LookupState _lookupState = _LookupState.idle;
  _LookupMethod _lookupMethod = _LookupMethod.email;
  bool _isActive = true;
  bool _isSaving = false;

  final Set<BusinessRole> _roles = {};

  String? _foundUserUid;
  String? _foundEmail;
  String? _verificationMethod;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole == ContactRole.supplier) {
      _roles.add(BusinessRole.supplier);
    }
  }

  @override
  void dispose() {
    _lookupController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _shopController.dispose();
    _supplierAddressController.dispose();
    _supplierTermsController.dispose();
    _supplierOpeningBalanceController.dispose();
    _supplierCurrentBalanceController.dispose();
    _supplierNotesController.dispose();
    super.dispose();
  }

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get _locked => _lookupState == _LookupState.found;
  bool get _isSupplier => _roles.contains(BusinessRole.supplier);

  // ── Lookup ────────────────────────────────────────────────────────────────

  void _applyUserData(Map<String, dynamic> userData) {
    _nameController.text = userData['name']?.toString() ?? '';
    final phone = userData['phone']?.toString() ?? '';
    if (phone.isNotEmpty) _phoneController.text = phone;
    _shopController.text = userData['shopNumber']?.toString() ??
        userData['shop']?.toString() ??
        '';
    _supplierAddressController.text = userData['supplierAddress']?.toString() ??
        userData['address']?.toString() ??
        '';
    _supplierNotesController.text = userData['supplierNotes']?.toString() ??
        userData['notes']?.toString() ??
        '';
    if (userData['supplierTermsDays'] != null) {
      _supplierTermsController.text = userData['supplierTermsDays'].toString();
    }
    if (userData['supplierOpeningBalance'] != null) {
      _supplierOpeningBalanceController.text =
          userData['supplierOpeningBalance'].toString();
    }
    if (userData['supplierCurrentBalance'] != null) {
      _supplierCurrentBalanceController.text =
          userData['supplierCurrentBalance'].toString();
    }

    _foundUserUid = userData['uid']?.toString();
    _foundEmail = userData['email']?.toString();

    // Parse through BusinessRole rather than matching raw strings: profiles are
    // stored lowercase now, older ones are capitalised, and 'importer' means
    // supplier. Direct `contains('Supplier')` checks silently missed all three.
    _roles
      ..clear()
      ..addAll(BusinessRole.parseAll(userData['roles'] as List<dynamic>?));
  }

  void _clearLookupResult() {
    _nameController.clear();
    _shopController.clear();
    _supplierAddressController.clear();
    _supplierTermsController.text = '0';
    _supplierOpeningBalanceController.text = '0';
    _supplierCurrentBalanceController.text = '0';
    _supplierNotesController.clear();
    _foundUserUid = null;
    _foundEmail = null;
    _verificationMethod = null;
    _roles.clear();
  }

  void _setLookupMethod(_LookupMethod method) {
    if (method == _lookupMethod) return;
    setState(() {
      _lookupMethod = method;
      _lookupController.clear();
      _lookupState = _LookupState.idle;
      _clearLookupResult();
    });
  }

  Future<void> _performSearch() async {
    final identifier = _lookupController.text.trim();
    if (identifier.isEmpty) return;

    setState(() => _lookupState = _LookupState.searching);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = ref.read(contactsRepositoryProvider);
      final localContacts = ref.read(allContactsProvider).valueOrNull ?? [];

      final Map<String, dynamic>? userData;
      if (_lookupMethod == _LookupMethod.phone) {
        userData = await repo.searchUserByPhone(identifier);
        _verificationMethod = 'phone';
      } else {
        userData = await repo.searchUserByEmail(identifier);
        _verificationMethod = 'email';
      }
      if (!mounted) return;

      if (userData == null) {
        _clearLookupResult();
        // Nothing found — keep what they typed as a head start.
        if (_lookupMethod == _LookupMethod.phone) {
          _phoneController.text = identifier;
        }
        setState(() => _lookupState = _LookupState.notFound);
        return;
      }

      if (userData['uid'] != null &&
          userData['uid'] == FirebaseAuth.instance.currentUser?.uid) {
        setState(() => _lookupState = _LookupState.idle);
        messenger.showSnackBar(const SnackBar(
          content: Text('That is your own account.'),
          backgroundColor: AppColors.negative,
        ));
        return;
      }

      if (localContacts.any((c) => c.linkedUserUid == userData!['uid'])) {
        setState(() => _lookupState = _LookupState.idle);
        messenger.showSnackBar(const SnackBar(
          content: Text('This business is already in your contacts.'),
          backgroundColor: AppColors.warning,
        ));
        return;
      }

      _applyUserData(userData);
      setState(() => _lookupState = _LookupState.found);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lookupState = _LookupState.idle);
      messenger.showSnackBar(const SnackBar(
        content: Text('Search failed. Check your connection and try again.'),
        backgroundColor: AppColors.negative,
      ));
    }
  }

  void _resetLookup() {
    setState(() {
      _lookupState = _LookupState.idle;
      _lookupController.clear();
      _phoneController.clear();
      _clearLookupResult();
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveContact() async {
    final messenger = ScaffoldMessenger.of(context);

    // Typing an identifier and never searching would create an unlinked
    // duplicate of somebody who is already on HisabET.
    if (_lookupState == _LookupState.idle &&
        _lookupController.text.trim().isNotEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Search for this contact first, or clear the box.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_roles.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Choose at least one business role.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    final permission =
        _isSupplier ? TeamPermission.managePurchases : TeamPermission.processSales;
    final allowed = await _ensurePermission(
      messenger,
      permission: permission,
      attemptedAction: 'create_contact_${_isSupplier ? 'supplier' : 'merchant'}',
    );
    if (!allowed || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      final suppliersRepo = ref.read(suppliersRepositoryProvider);
      final actorRole = ref.read(currentRoleProvider);

      final rawPhone = _phoneController.text.trim();
      final normalizedPhone =
          rawPhone.isEmpty ? null : PhoneUtil.normalize(rawPhone);
      final name = _nameController.text.trim();

      final contactId = await contactsRepo.addContact(
        name,
        normalizedPhone,
        _isSupplier || _shopController.text.trim().isEmpty
            ? null
            : _shopController.text.trim(),
        linkedUserUid: _foundUserUid,
        role: _isSupplier ? ContactRole.supplier : ContactRole.merchant,
        verificationMethod: _verificationMethod,
        isRetailer: _roles.contains(BusinessRole.retailer),
        isWholesaler: _roles.contains(BusinessRole.wholesaler),
        isBroker: _roles.contains(BusinessRole.broker),
        isSupplier: _isSupplier,
      );

      if (_isSupplier) {
        await suppliersRepo.upsertSupplierProfile(
          id: contactId,
          name: name,
          phone: normalizedPhone,
          email: _foundEmail ??
              (_lookupMethod == _LookupMethod.email
                  ? _lookupController.text.trim()
                  : null),
          address: _supplierAddressController.text.trim().isEmpty
              ? null
              : _supplierAddressController.text.trim(),
          termsDays: int.tryParse(_supplierTermsController.text.trim()) ?? 0,
          openingBalance:
              Decimal.tryParse(_supplierOpeningBalanceController.text.trim()) ??
                  Decimal.zero,
          currentBalance:
              Decimal.tryParse(_supplierCurrentBalanceController.text.trim()) ??
                  Decimal.zero,
          notes: _supplierNotesController.text.trim().isEmpty
              ? null
              : _supplierNotesController.text.trim(),
          isActive: _isActive,
        );
      }

      await ref.read(auditRepositoryProvider).logAction(
            actorRole: actorRole,
            action: 'contact_created',
            entityType: 'contact',
            entityId: contactId,
            message: 'Contact $name created.',
          );
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.negative,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _ensurePermission(
    ScaffoldMessengerState messenger, {
    required TeamPermission permission,
    required String attemptedAction,
  }) async {
    if (ref.read(hasPermissionProvider(permission))) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'permission_denied',
          entityType: 'contact',
          message: 'Denied $attemptedAction for role ${actorRole.name}.',
        );
    ref.invalidate(recentAuditLogsProvider);
    messenger.showSnackBar(const SnackBar(
      content: Text('You do not have permission to create contacts.'),
    ));
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
            children: [
              AppTopBar(
                eyebrow: 'CONTACTS',
                title: 'Add contact',
                leading: AppTopBarAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _lookupSection(),
                    const SizedBox(height: AppDimensions.md),
                    _detailsSection(),
                    const SizedBox(height: AppDimensions.md),
                    _rolesSection(),
                    if (_isSupplier) ...[
                      const SizedBox(height: AppDimensions.md),
                      _supplierSection(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _saveBar(context),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _lookupSection() {
    final searching = _lookupState == _LookupState.searching;

    return AppFormSection(
      title: 'Find on HisabET',
      icon: Icons.manage_search_rounded,
      margin: EdgeInsets.zero,
      children: [
        AppSearchBar(
          margin: EdgeInsets.zero,
          controller: _lookupController,
          hintText: _lookupMethod == _LookupMethod.email
              ? 'name@example.com'
              : '0911 22 33 44',
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          trailing: AppSearchScopeButton<_LookupMethod>(
            value: _lookupMethod,
            onChanged: _setLookupMethod,
            tooltip: 'Search by',
            scopes: const [
              AppSearchScope(
                value: _LookupMethod.email,
                label: 'Email',
                icon: Icons.alternate_email_rounded,
              ),
              AppSearchScope(
                value: _LookupMethod.phone,
                label: 'Phone',
                icon: Icons.phone_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 44,
          child: _locked
              ? OutlinedButton.icon(
                  onPressed: _resetLookup,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Search someone else'),
                )
              : FilledButton.icon(
                  onPressed: searching ? null : _performSearch,
                  icon: searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(searching ? 'Searching…' : 'Search'),
                ),
        ),
        if (_lookupState == _LookupState.found) ...[
          const SizedBox(height: AppDimensions.md),
          const _LookupNote(
            icon: Icons.verified_rounded,
            color: AppColors.info,
            text: 'Matched a verified HisabET account. Their details are '
                'filled in and locked so both ledgers stay identical.',
          ),
        ] else if (_lookupState == _LookupState.notFound) ...[
          const SizedBox(height: AppDimensions.md),
          const _LookupNote(
            icon: Icons.edit_note_rounded,
            color: AppColors.warning,
            text: 'Nobody found. Fill in the details below to keep an '
                'unverified record — they will not see or confirm it.',
          ),
        ] else ...[
          const SizedBox(height: AppDimensions.sm),
          const _LookupNote(
            icon: Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            text: 'A matched account confirms every entry from their side. '
                'Skip this to keep a private record instead.',
          ),
        ],
      ],
    );
  }

  Widget _detailsSection() {
    return AppFormSection(
      title: 'Contact details',
      icon: Icons.badge_rounded,
      margin: EdgeInsets.zero,
      children: [
        AppTextField(
          label: _isSupplier ? 'Supplier business name' : 'Business or person',
          controller: _nameController,
          readOnly: _locked,
          isRequired: true,
          textCapitalization: TextCapitalization.words,
          hint: 'e.g. Bereket Shoes',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'A name is required' : null,
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: 'Phone number',
          controller: _phoneController,
          readOnly: _locked,
          keyboardType: TextInputType.phone,
          hint: '0911 22 33 44',
          helper: 'Used to match your ledger with theirs later.',
        ),
        if (!_isSupplier) ...[
          const SizedBox(height: AppDimensions.lg),
          AppTextField(
            label: 'Shop location',
            controller: _shopController,
            readOnly: _locked,
            hint: 'Merkato Tera, B-12',
          ),
        ],
      ],
    );
  }

  Widget _rolesSection() {
    return AppFormSection(
      title: 'Business roles',
      icon: Icons.workspaces_rounded,
      margin: EdgeInsets.zero,
      trailing: _locked
          ? Icon(
              Icons.lock_outline_rounded,
              size: AppDimensions.iconSm,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: Text(
            _locked
                ? 'Taken from their verified profile.'
                : 'Pick everything that applies — most traders wear more than '
                    'one hat.',
            style: AppTextStyles.cardSubtitle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final role in BusinessRole.values)
          AppChoiceTile(
            title: role.label,
            description: role.contactDescription,
            icon: role.icon,
            selected: _roles.contains(role),
            margin: EdgeInsets.only(
              bottom: role == BusinessRole.values.last ? 0 : AppDimensions.sm,
            ),
            onTap: _locked
                ? null
                : () => setState(() {
                      if (!_roles.remove(role)) _roles.add(role);
                    }),
          ),
      ],
    );
  }

  Widget _supplierSection() {
    return AppFormSection(
      title: 'Supplier terms',
      icon: Icons.account_balance_wallet_rounded,
      margin: EdgeInsets.zero,
      children: [
        AppTextField(
          label: 'Office address',
          controller: _supplierAddressController,
          readOnly: _locked,
          maxLines: 2,
          minLines: 1,
          hint: 'Where you collect containers from',
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: 'Payment terms',
          controller: _supplierTermsController,
          readOnly: _locked,
          numeric: true,
          keyboardType: TextInputType.number,
          helper: 'Days you have to settle after taking goods. 0 = cash only.',
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: 'Opening balance',
          controller: _supplierOpeningBalanceController,
          readOnly: _locked,
          numeric: true,
          prefixText: 'ETB ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helper: 'What you already owed them before using HisabET.',
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: 'Current balance owed',
          controller: _supplierCurrentBalanceController,
          readOnly: _locked,
          numeric: true,
          prefixText: 'ETB ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: 'Delivery notes',
          controller: _supplierNotesController,
          readOnly: _locked,
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: AppDimensions.lg),
        _ToggleRow(
          title: 'Active supplier',
          subtitle: 'Show in purchase flows and the tender network',
          value: _isActive,
          onChanged: _locked ? null : (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }

  Widget _saveBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.hairlineDark : AppColors.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.md,
            AppDimensions.pagePaddingH,
            AppDimensions.md,
          ),
          child: SizedBox(
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveContact,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save contact'),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short status line under the lookup box. Colour is carried by the icon and
/// a hairline, not by a filled block — the note explains, it does not alarm.
class _LookupNote extends StatelessWidget {
  const _LookupNote({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.cardSubtitle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.cardSubtitle.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
