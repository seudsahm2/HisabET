import 'dart:async';

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

/// Where the lookup stands.
enum _Lookup {
  /// Nothing complete enough to look up yet.
  idle,
  searching,

  /// A verified HisabET account owns this number/email: one tap to add.
  found,

  /// Nobody — the private-contact form opens with what was typed.
  notFound,

  /// This person is already in the ledger, or it is the user themselves.
  blocked,
}

enum _Method { phone, email }

/// Add a contact in the fewest steps.
///
/// It starts with one field — the phone number — and checks HisabET by itself
/// as soon as the number is complete. A verified account turns into a card and
/// a single "Add" button; nobody found opens a short form for a private
/// record, with the number already filled in.
class AddContactScreen extends ConsumerStatefulWidget {
  final ContactRole initialRole;

  /// Pre-fills the number (e.g. from a "not on HisabET yet" search) and
  /// checks it straight away.
  final String? initialPhone;

  const AddContactScreen({super.key, this.initialRole = ContactRole.merchant, this.initialPhone});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lookupController = TextEditingController();
  final _lookupFocus = FocusNode();

  final _nameController = TextEditingController();
  final _shopController = TextEditingController();
  final _supplierAddressController = TextEditingController();
  final _supplierTermsController = TextEditingController(text: '0');
  final _supplierOpeningBalanceController = TextEditingController(text: '0');
  final _supplierCurrentBalanceController = TextEditingController(text: '0');

  _Method _method = _Method.phone;
  _Lookup _lookup = _Lookup.idle;
  String? _blockedReason;
  String? _lookedUpFor;
  Timer? _debounce;
  bool _saving = false;

  /// The user chose to add someone without a phone number or email.
  bool _withoutLookup = false;

  final Set<BusinessRole> _roles = {};
  Map<String, dynamic>? _account;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole == ContactRole.supplier) _roles.add(BusinessRole.supplier);
    final phone = widget.initialPhone;
    if (phone != null && phone.isNotEmpty) {
      _lookupController.text = phone;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookUp());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _lookupController,
      _nameController,
      _shopController,
      _supplierAddressController,
      _supplierTermsController,
      _supplierOpeningBalanceController,
      _supplierCurrentBalanceController,
    ]) {
      c.dispose();
    }
    _lookupFocus.dispose();
    super.dispose();
  }

  bool get _isSupplier => _roles.contains(BusinessRole.supplier);

  String? get _normalizedPhone {
    if (_method != _Method.phone) return null;
    final normalized = PhoneUtil.normalize(_lookupController.text.trim());
    return PhoneUtil.isValidE164(normalized) ? normalized : null;
  }

  bool get _inputComplete => _method == _Method.phone
      ? _normalizedPhone != null
      : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_lookupController.text.trim());

  // ── Lookup ────────────────────────────────────────────────────────────────

  void _onLookupChanged(String _) {
    _debounce?.cancel();
    final key = _lookupKey();
    if (key != _lookedUpFor && _lookup != _Lookup.idle) {
      setState(() {
        _lookup = _Lookup.idle;
        _account = null;
        _blockedReason = null;
      });
    }
    if (_inputComplete) _debounce = Timer(const Duration(milliseconds: 400), _lookUp);
  }

  String _lookupKey() => _method == _Method.phone
      ? (_normalizedPhone ?? _lookupController.text.trim())
      : _lookupController.text.trim().toLowerCase();

  void _setMethod(_Method method) {
    _debounce?.cancel();
    setState(() {
      _method = method;
      _lookupController.clear();
      _lookup = _Lookup.idle;
      _account = null;
      _lookedUpFor = null;
    });
    _lookupFocus.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 60), _lookupFocus.requestFocus);
  }

  Future<void> _lookUp() async {
    if (!_inputComplete) return;
    final key = _lookupKey();
    setState(() {
      _lookup = _Lookup.searching;
      _lookedUpFor = key;
    });

    final repo = ref.read(contactsRepositoryProvider);
    final user = _method == _Method.phone ? await repo.searchUserByPhone(key) : await repo.searchUserByEmail(key);
    if (!mounted || _lookedUpFor != key) return;

    if (user == null) {
      setState(() {
        _lookup = _Lookup.notFound;
        _account = null;
      });
      return;
    }

    final uid = user['uid']?.toString();
    final ledger = ref.read(allContactsProvider).valueOrNull ?? const <ContactModel>[];
    String? blocked;
    if (uid != null && uid == FirebaseAuth.instance.currentUser?.uid) {
      blocked = 'That is your own account.';
    } else if (ledger.any((c) => c.linkedUserUid == uid)) {
      blocked = '${user['name'] ?? 'This business'} is already in your contacts.';
    }

    setState(() {
      _account = user;
      _lookup = blocked == null ? _Lookup.found : _Lookup.blocked;
      _blockedReason = blocked;
      _roles
        ..clear()
        ..addAll(BusinessRole.parseAll(user['roles'] as List<dynamic>?));
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    _debounce?.cancel();

    // A complete number that hasn't been checked yet: check before saving, so
    // someone already on HisabET is never saved as an unlinked duplicate.
    if (_inputComplete && _lookedUpFor != _lookupKey()) await _lookUp();
    if (!mounted) return;

    if (_lookup == _Lookup.blocked) {
      messenger.showSnackBar(SnackBar(content: Text(_blockedReason ?? 'Cannot add this contact.')));
      return;
    }
    if (_method == _Method.phone && _lookupController.text.trim().isNotEmpty && _normalizedPhone == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter the full phone number, e.g. 0911 22 33 44.')));
      return;
    }
    if (_lookup != _Lookup.found && !(_formKey.currentState?.validate() ?? false)) return;

    final permission = _isSupplier ? TeamPermission.managePurchases : TeamPermission.processSales;
    if (!await _ensurePermission(messenger, permission)) return;
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      final account = _lookup == _Lookup.found ? _account : null;
      final name = account?['name']?.toString() ?? _nameController.text.trim();
      final phone = account?['phone']?.toString() ?? _normalizedPhone;
      final email = account?['email']?.toString() ??
          (_method == _Method.email ? _lookupController.text.trim().toLowerCase() : null);

      final contactId = await ref.read(contactsRepositoryProvider).addContact(
            name,
            phone,
            _isSupplier || _shopController.text.trim().isEmpty ? null : _shopController.text.trim(),
            linkedUserUid: account?['uid']?.toString(),
            role: _isSupplier ? ContactRole.supplier : ContactRole.merchant,
            verificationMethod: account == null ? null : (_method == _Method.phone ? 'phone' : 'email'),
            isRetailer: _roles.contains(BusinessRole.retailer),
            isWholesaler: _roles.contains(BusinessRole.wholesaler),
            isBroker: _roles.contains(BusinessRole.broker),
            isSupplier: _isSupplier,
          );

      if (_isSupplier) {
        await ref.read(suppliersRepositoryProvider).upsertSupplierProfile(
              id: contactId,
              name: name,
              phone: phone,
              email: email,
              address: (account?['supplierAddress']?.toString() ?? _supplierAddressController.text.trim()).isEmpty
                  ? null
                  : (account?['supplierAddress']?.toString() ?? _supplierAddressController.text.trim()),
              termsDays: int.tryParse(_supplierTermsController.text.trim()) ?? 0,
              openingBalance: Decimal.tryParse(_supplierOpeningBalanceController.text.trim()) ?? Decimal.zero,
              currentBalance: Decimal.tryParse(_supplierCurrentBalanceController.text.trim()) ?? Decimal.zero,
              notes: null,
              isActive: true,
            );
      }

      final actorRole = ref.read(currentRoleProvider);
      await ref.read(auditRepositoryProvider).logAction(
            actorRole: actorRole,
            action: 'contact_created',
            entityType: 'contact',
            entityId: contactId,
            message: 'Contact $name created.',
          );
      ref.invalidate(recentAuditLogsProvider);
      ref.invalidate(allContactsProvider);

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$name added'), backgroundColor: AppColors.positive));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.negative,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _ensurePermission(ScaffoldMessengerState messenger, TeamPermission permission) async {
    if (ref.read(hasPermissionProvider(permission))) return true;
    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'permission_denied',
          entityType: 'contact',
          message: 'Denied create_contact for role ${actorRole.name}.',
        );
    ref.invalidate(recentAuditLogsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('You do not have permission to create contacts.')));
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showForm = _lookup == _Lookup.notFound || (_withoutLookup && _lookup == _Lookup.idle);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _lookupField(),
                    const SizedBox(height: AppDimensions.md),
                    _lookupResult(),
                    if (showForm) ...[
                      const SizedBox(height: AppDimensions.lg),
                      _privateForm(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomActionBar(
        child: AppPrimaryActionButton(
          busy: _saving,
          onPressed: _lookup == _Lookup.searching || _lookup == _Lookup.blocked ? null : _save,
          label: _lookup == _Lookup.found ? 'Add ${_account?['name'] ?? 'contact'}' : 'Save contact',
        ),
      ),
    );
  }

  Widget _lookupField() {
    final colorScheme = Theme.of(context).colorScheme;
    final phone = _method == _Method.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(phone ? 'PHONE NUMBER' : 'EMAIL', style: AppTextStyles.sectionLabel),
        const SizedBox(height: AppDimensions.sm),
        AppSearchBar(
          margin: EdgeInsets.zero,
          controller: _lookupController,
          focusNode: _lookupFocus,
          autofocus: widget.initialPhone == null,
          leadingIcon: phone ? Icons.dialpad_rounded : Icons.alternate_email_rounded,
          hintText: phone ? '0911 22 33 44' : 'name@example.com',
          keyboardType: phone ? TextInputType.phone : TextInputType.emailAddress,
          textInputAction: TextInputAction.search,
          onChanged: _onLookupChanged,
          onSubmitted: (_) => _lookUp(),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                phone ? 'We check HisabET as you type.' : 'Exact email of their HisabET account.',
                style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
              ),
              onPressed: () => _setMethod(phone ? _Method.email : _Method.phone),
              child: Text(phone ? 'Use email instead' : 'Use phone number'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _lookupResult() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_lookup) {
      case _Lookup.idle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hint(
              icon: Icons.info_outline_rounded,
              tone: colorScheme.onSurfaceVariant,
              text: 'People on HisabET confirm every entry from their side. Others are kept as private records.',
            ),
            if (!_withoutLookup && _lookupController.text.trim().isEmpty)
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => setState(() => _withoutLookup = true),
                child: const Text('Add without a phone number'),
              ),
          ],
        );
      case _Lookup.searching:
        return const _Hint(icon: Icons.search_rounded, tone: AppColors.info, text: 'Checking HisabET…', busy: true);
      case _Lookup.blocked:
        return _Hint(icon: Icons.block_rounded, tone: AppColors.warning, text: _blockedReason ?? '');
      case _Lookup.notFound:
        return const _Hint(
          icon: Icons.person_off_outlined,
          tone: AppColors.warning,
          text: 'Not on HisabET yet. Add a name below to keep a private record.',
        );
      case _Lookup.found:
        final account = _account!;
        final name = account['name']?.toString() ?? 'HisabET user';
        final roles = BusinessRole.parseAll(account['roles'] as List<dynamic>?).map((r) => r.label).join(' · ');
        return AppGroupedRow(
          isFirst: true,
          isLast: true,
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              AppInitialAvatar(name: name, verified: true, size: 48),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const AppHisabetBadge(),
                        if (roles.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              roles,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified account — entries you add will be confirmed by them.',
                      style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _privateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Name',
          controller: _nameController,
          isRequired: true,
          autofocus: _lookup == _Lookup.notFound,
          textCapitalization: TextCapitalization.words,
          hint: 'e.g. Bereket Shoes',
          validator: (v) => (v == null || v.trim().isEmpty) ? 'A name is required' : null,
        ),
        if (!_isSupplier) ...[
          const SizedBox(height: AppDimensions.lg),
          AppTextField(label: 'Shop location (optional)', controller: _shopController, hint: 'Merkato Tera, B-12'),
        ],
        const SizedBox(height: AppDimensions.lg),
        Text('ROLE (OPTIONAL)', style: AppTextStyles.sectionLabel),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: [
            for (final role in BusinessRole.values)
              _RoleChip(
                role: role,
                selected: _roles.contains(role),
                onTap: () => setState(() {
                  if (!_roles.remove(role)) _roles.add(role);
                }),
              ),
          ],
        ),
        if (_isSupplier) ...[
          const SizedBox(height: AppDimensions.lg),
          AppFormSection(
            title: 'Supplier terms',
            icon: Icons.account_balance_wallet_rounded,
            margin: EdgeInsets.zero,
            children: [
              AppTextField(label: 'Office address', controller: _supplierAddressController, maxLines: 2, minLines: 1),
              const SizedBox(height: AppDimensions.lg),
              AppTextField(
                label: 'Payment terms (days)',
                controller: _supplierTermsController,
                numeric: true,
                keyboardType: TextInputType.number,
                helper: '0 = cash only.',
              ),
              const SizedBox(height: AppDimensions.lg),
              AppTextField(
                label: 'Opening balance',
                controller: _supplierOpeningBalanceController,
                numeric: true,
                prefixText: 'ETB ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                helper: 'What you already owed them before HisabET.',
              ),
              const SizedBox(height: AppDimensions.lg),
              AppTextField(
                label: 'Current balance owed',
                controller: _supplierCurrentBalanceController,
                numeric: true,
                prefixText: 'ETB ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.tone, required this.text, this.busy = false});
  final IconData icon;
  final Color tone;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: busy
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: tone))
              : Icon(icon, size: 16, color: tone),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.cardSubtitle.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.selected, required this.onTap});
  final BusinessRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected ? AppColors.primary : (isDark ? AppColors.hairlineDark : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(role.icon, size: 16, color: selected ? Colors.white : colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                role.label,
                style: AppTextStyles.badgeLabel.copyWith(
                  fontSize: 13,
                  color: selected ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
