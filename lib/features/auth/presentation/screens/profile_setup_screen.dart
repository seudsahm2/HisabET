import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/phone_identity/presentation/providers/phone_identity_providers.dart';
import 'package:hisabet/features/phone_identity/presentation/widgets/phone_verification_panel.dart';

/// Collects the profile every other screen depends on: display name, business
/// roles, and — for suppliers — the vendor ledger fields.
///
/// Shown by `AuthGate` when the user is authenticated but `users/{uid}` is
/// missing or incomplete. On save it writes the profile and lets the gate's
/// Firestore stream route onward; this screen never navigates itself.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.initialRoles = const []});

  /// Roles already stored on a partially-completed profile.
  final List<String> initialRoles;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _addressController = TextEditingController();
  final _termsController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0');
  final _currentBalanceController = TextEditingController(text: '0');

  final Set<BusinessRole> _roles = {};

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _roles.addAll(BusinessRole.parseAll(widget.initialRoles));
    _nameController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    _openingBalanceController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  bool get _needsSupplierProfile =>
      _roles.any((role) => role.keepsVendorLedger);

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_roles.isEmpty) {
      setState(() => _error = 'Choose at least one role so we can set up your workspace.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Your session expired. Please sign in again.');
      return;
    }

    // The number itself is already saved by the verification flow (Telegram
    // via the backend, SMS via PhoneClaimRepository); this only checks it.
    if (ref.read(verifiedPhoneProvider).valueOrNull == null) {
      setState(() => _error = 'Verify your phone number to continue.');
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'id': user.uid,
        'name': _nameController.text.trim(),
        'roles': BusinessRole.toStorageKeys(
          BusinessRole.values.where(_roles.contains),
        ),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (user.email != null && user.email!.isNotEmpty) {
        payload['email'] = user.email!.toLowerCase();
      }

      if (_needsSupplierProfile) {
        final address = _addressController.text.trim();
        payload['supplierAddress'] = address.isEmpty ? null : address;
        payload['supplierTermsDays'] =
            int.tryParse(_termsController.text.trim()) ?? 0;
        payload['supplierOpeningBalance'] =
            _normalizedAmount(_openingBalanceController.text);
        payload['supplierCurrentBalance'] =
            _normalizedAmount(_currentBalanceController.text);
      }

      // Only stamp created_at the first time. Check the field, not the
      // document: phone verification may already have created the document.
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final existing = (await docRef.get()).data();
      if (existing?['created_at'] == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
      }
      if (existing?['contacts_uids'] == null) {
        payload['contacts_uids'] = <String>[];
      }

      await docRef.set(payload, SetOptions(merge: true));
      // AuthGate's snapshot listener sees the completed profile and routes on.
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.code == 'permission-denied'
            ? 'Saving was blocked by security rules. Allow writes to users/{uid}.'
            : 'Could not save your profile: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save your profile. $e';
      });
    }
  }

  String _normalizedAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '0';
    return double.tryParse(trimmed) == null ? '0' : trimmed;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      final google = GoogleSignIn();
      if (await google.isSignedIn()) await google.signOut();
    } catch (_) {
      // Google session may not exist (phone sign-in) — harmless.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create your profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _signOut,
            icon: const Icon(Icons.logout_rounded, size: AppDimensions.iconSm),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.lg,
              AppDimensions.pagePaddingH,
              AppDimensions.xxxl,
            ),
            children: [
              const AppMissionHeader(
                eyebrow: 'SETUP',
                title: 'Tell us who you are',
                subtitle:
                    'This shapes your dashboard, your inventory, and how partners find you.',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppDimensions.xl),

              _identitySection(),
              _rolesSection(),
              _contactSection(),
              if (_needsSupplierProfile) _supplierSection(),

              if (_error != null) ...[
                const SizedBox(height: AppDimensions.sm),
                _Note(
                  icon: Icons.error_outline_rounded,
                  message: _error!,
                  tone: AppColors.negative,
                ),
              ],

              const SizedBox(height: AppDimensions.xl),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: AppDimensions.iconSm,
                        height: AppDimensions.iconSm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Text('Start using HisabET'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identitySection() {
    return AppFormSection(
      title: 'Your business',
      icon: Icons.badge_outlined,
      children: [
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'e.g. Ahmed Shoe Store',
            prefixIcon: Icon(Icons.storefront_rounded),
          ),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Enter the name partners will recognise.';
            if (name.length < 2) return 'That name looks too short.';
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Your contacts see this name on every shared transaction.',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _rolesSection() {
    return AppFormSection(
      title: 'What you do',
      icon: Icons.workspaces_outline,
      trailing: _roles.isEmpty
          ? null
          : Text(
              '${_roles.length} selected',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
      children: [
        Text(
          'Pick every role that applies — many traders buy and sell at more than one level.',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        ...BusinessRole.values.map((role) {
          final selected = _roles.contains(role);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: _RoleCard(
              role: role,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _roles.remove(role);
                  } else {
                    _roles.add(role);
                  }
                  _error = null;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _contactSection() {
    final user = FirebaseAuth.instance.currentUser;

    return AppFormSection(
      title: 'How partners reach you',
      icon: Icons.contact_phone_outlined,
      children: [
        if (user?.email != null && user!.email!.isNotEmpty) ...[
          _ReadOnlyRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: user.email!,
            badge: 'VERIFIED',
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        Text(
          'Phone number — required. Partners find you by it and your ledgers match through it. '
          'Each number belongs to one HisabET account only.',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        const PhoneVerificationPanel(),
      ],
    );
  }

  Widget _supplierSection() {
    return AppFormSection(
      title: 'Supplier profile',
      icon: Icons.directions_boat_outlined,
      children: [
        Text(
          'You import and sell in bulk, so buyers track what they owe you. These are optional.',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Business address',
            hintText: 'e.g. Merkato, Addis Ababa',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: _termsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Credit terms (days)',
            hintText: '0 for cash only',
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _openingBalanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Opening balance'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: _currentBalanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Current balance'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        const _Note(
          icon: Icons.lightbulb_outline_rounded,
          message:
              'Leave both at 0 unless you are carrying over balances from a paper notebook.',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final BusinessRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : colorScheme.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                  border: selected
                      ? null
                      : Border.all(color: colorScheme.outlineVariant),
                ),
                child: Icon(
                  role.icon,
                  size: AppDimensions.iconMd,
                  color: selected
                      ? AppColors.textOnPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? AppColors.primary
                    : colorScheme.outlineVariant,
                size: AppDimensions.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: AppDimensions.iconSm,
              color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardSubtitle.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) AppStatusBadge.success(label: badge!, small: true),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.message,
    this.tone,
  });

  final IconData icon;
  final String message;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = tone ?? AppColors.info;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: accent),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
