import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabet/core/l10n/language_provider.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/settings/data/models/app_settings_model.dart';
import 'package:hisabet/features/settings/presentation/providers/settings_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/settings/presentation/screens/trash_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _businessPhoneCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();
  final _currencySymbolCtrl = TextEditingController();
  final _taxPercentCtrl = TextEditingController();
  final _invoiceFooterCtrl = TextEditingController();
  final _invoicePrefixCtrl = TextEditingController();

  String _languageCode = 'en';
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _businessAddressCtrl.dispose();
    _currencySymbolCtrl.dispose();
    _taxPercentCtrl.dispose();
    _invoiceFooterCtrl.dispose();
    _invoicePrefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (settings) {
          if (!_initialized) {
            _seedForm(settings);
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const AppSectionHeader(
                  title: 'Business Profile',
                  uppercase: false,
                  padding: EdgeInsets.only(left: 2, bottom: 6),
                ),
                _card(
                  children: [
                    _field(
                      controller: _businessNameCtrl,
                      label: 'Business Name',
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Business name required'
                          : null,
                    ),
                    _gap(),
                    _field(
                      controller: _businessPhoneCtrl,
                      label: 'Business Phone (optional)',
                    ),
                    _gap(),
                    _field(
                      controller: _businessAddressCtrl,
                      label: 'Business Address (optional)',
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const AppSectionHeader(
                  title: 'Tax & Invoice',
                  uppercase: false,
                  padding: EdgeInsets.only(left: 2, bottom: 6),
                ),
                _card(
                  children: [
                    _field(
                      controller: _currencySymbolCtrl,
                      label: 'Currency Symbol (e.g. ETB)',
                    ),
                    _gap(),
                    _field(
                      controller: _taxPercentCtrl,
                      label: 'Default Tax %',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _gap(),
                    _field(
                      controller: _invoicePrefixCtrl,
                      label: 'Invoice Prefix',
                    ),
                    _gap(),
                    _field(
                      controller: _invoiceFooterCtrl,
                      label: 'Invoice Footer',
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const AppSectionHeader(
                  title: 'Localization',
                  uppercase: false,
                  padding: EdgeInsets.only(left: 2, bottom: 6),
                ),
                _card(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _languageCode,
                      decoration: const InputDecoration(labelText: 'Language'),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(
                          value: 'am',
                          child: Text('Amharic (አማርኛ)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _languageCode = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const AppSectionHeader(
                  title: 'Backup Options',
                  uppercase: false,
                  padding: EdgeInsets.only(left: 2, bottom: 6),
                ),
                _card(
                  children: [
                    AppSettingTile(
                      title: 'Trash / Recovery',
                      subtitle: 'View and restore deleted items (30 days)',
                      icon: Icons.delete_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrashScreen()),
                        );
                      },
                    ),
                    const Divider(height: 12),
                    AppSettingTile(
                      title: 'Create Database Backup',
                      subtitle: 'Creates a timestamped SQLite backup file',
                      icon: Icons.backup_outlined,
                      onTap: _createBackup,
                    ),
                    const Divider(height: 12),
                    AppSettingTile(
                      title: 'Export Settings Snapshot',
                      subtitle: 'Exports current settings to JSON',
                      icon: Icons.file_download_outlined,
                      onTap: _exportSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const AppSectionHeader(
                  title: 'Danger Zone',
                  uppercase: false,
                  padding: EdgeInsets.only(left: 2, bottom: 6),
                ),
                _card(
                  children: [
                    AppSettingTile(
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data.',
                      icon: Icons.delete_forever_rounded,
                      iconColor: colorScheme.error,
                      titleColor: colorScheme.error,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: _saving
                        ? CircularProgressIndicator(color: colorScheme.onPrimary)
                        : const Text('SAVE SETTINGS'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return AppCard(
      style: AppCardStyle.glass,
      padding: const EdgeInsets.all(14),
      child: Column(children: children),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _gap() => const SizedBox(height: 10);

  void _seedForm(AppSettingsModel settings) {
    _businessNameCtrl.text = settings.businessName;
    _businessPhoneCtrl.text = settings.businessPhone ?? '';
    _businessAddressCtrl.text = settings.businessAddress ?? '';
    _currencySymbolCtrl.text = settings.currencySymbol;
    _taxPercentCtrl.text = settings.defaultTaxPercent.toString();
    _invoiceFooterCtrl.text = settings.invoiceFooter;
    _invoicePrefixCtrl.text = settings.invoicePrefix;
    _languageCode = settings.languageCode;
  }

  Future<void> _save(AppSettingsModel current) async {
    final allowed = await _ensureSettingsPermission(
      context,
      ref,
      attemptedAction: 'save_settings',
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        businessName: _businessNameCtrl.text.trim(),
        businessPhone: _businessPhoneCtrl.text.trim().isEmpty
            ? null
            : _businessPhoneCtrl.text.trim(),
        businessAddress: _businessAddressCtrl.text.trim().isEmpty
            ? null
            : _businessAddressCtrl.text.trim(),
        currencySymbol: _currencySymbolCtrl.text.trim().isEmpty
            ? 'ETB'
            : _currencySymbolCtrl.text.trim(),
        defaultTaxPercent: double.tryParse(_taxPercentCtrl.text.trim()) ?? 0,
        invoiceFooter: _invoiceFooterCtrl.text.trim().isEmpty
            ? 'Thank you for your business.'
            : _invoiceFooterCtrl.text.trim(),
        invoicePrefix: _invoicePrefixCtrl.text.trim().isEmpty
            ? 'INV'
            : _invoicePrefixCtrl.text.trim(),
        languageCode: _languageCode,
      );

      final repo = ref.read(appSettingsRepositoryProvider);
      await repo.saveSettings(updated);

      ref.read(languageProvider.notifier).setLanguage(Locale(_languageCode));

      final actorRole = ref.read(currentRoleProvider);
      await ref
          .read(auditRepositoryProvider)
          .logAction(
            actorRole: actorRole,
            action: 'settings_updated',
            entityType: 'settings',
            message: 'Business and invoice settings updated.',
          );

      ref.invalidate(appSettingsProvider);
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createBackup() async {
    final allowed = await _ensureSettingsPermission(
      context,
      ref,
      attemptedAction: 'create_database_backup',
    );
    if (!allowed) return;

    try {
      final path = await ref
          .read(appSettingsRepositoryProvider)
          .createDatabaseBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup created: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _exportSettings() async {
    final allowed = await _ensureSettingsPermission(
      context,
      ref,
      attemptedAction: 'export_settings_snapshot',
    );
    if (!allowed) return;

    try {
      final path = await ref
          .read(appSettingsRepositoryProvider)
          .exportSettingsSnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Settings exported: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted from our servers and this device.',
                style: TextStyle(color: AppColors.negative),
              ),
              const SizedBox(height: 16),
              const Text('Type "DELETE" to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
              onPressed: () {
                if (ctrl.text.trim() == 'DELETE') {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('You must type DELETE exactly.')));
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _saving = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete from Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          // Wipe local DB
          await ref.read(appDatabaseProvider).clearAllData();
          // Delete Auth User
          await user.delete();
          // Ensure Google Session is also cleared
          try {
            final googleSignIn = GoogleSignIn();
            if (await googleSignIn.isSignedIn()) {
              await googleSignIn.signOut();
            }
          } catch (_) {}
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }
}

Future<bool> _ensureSettingsPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.manageTeam));
  if (allowed) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref
      .read(auditRepositoryProvider)
      .logAction(
        actorRole: actorRole,
        action: 'permission_denied',
        entityType: 'settings',
        message: 'Denied $attemptedAction for role ${actorRole.name}.',
      );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to manage settings.'),
      ),
    );
  }
  return false;
}
