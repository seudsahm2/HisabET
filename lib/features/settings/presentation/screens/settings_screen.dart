import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/l10n/language_provider.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/settings/data/models/app_settings_model.dart';
import 'package:hisabet/features/settings/presentation/providers/settings_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
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
                _sectionTitle('Business Profile'),
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
                _sectionTitle('Tax & Invoice'),
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
                _sectionTitle('Localization'),
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
                _sectionTitle('Backup Options'),
                _card(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Create Database Backup'),
                      subtitle: const Text(
                        'Creates a timestamped SQLite backup file',
                      ),
                      onTap: _createBackup,
                    ),
                    const Divider(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export Settings Snapshot'),
                      subtitle: const Text('Exports current settings to JSON'),
                      onTap: _exportSettings,
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
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
