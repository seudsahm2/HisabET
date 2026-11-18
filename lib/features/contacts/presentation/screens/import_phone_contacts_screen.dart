import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/data/phone_book/phone_book.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/providers/phone_book_providers.dart';

/// "Import from phone contacts": the phone book, split into people already on
/// HisabET (verified accounts — their entries get confirmed from both sides)
/// and everyone else. One tap on a name saves that person to the ledger.
class ImportPhoneContactsScreen extends ConsumerStatefulWidget {
  const ImportPhoneContactsScreen({super.key});

  @override
  ConsumerState<ImportPhoneContactsScreen> createState() => _ImportPhoneContactsScreenState();
}

class _ImportPhoneContactsScreenState extends ConsumerState<ImportPhoneContactsScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _saving = {};

  /// Set when the user went to system settings to grant access; re-check on return.
  bool _awaitingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingSettings) {
      _awaitingSettings = false;
      ref.invalidate(phoneBookImportProvider);
    }
  }

  String _key(PhoneBookEntry e) => '${e.contact.id}|${e.phone}';

  Future<void> _save(PhoneBookEntry entry) async {
    final key = _key(entry);
    if (_saving.contains(key) || entry.alreadySaved) return;
    setState(() => _saving.add(key));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final user = entry.user;
      if (user != null) {
        // A real account: save under their verified business name and
        // number, linked, so both ledgers line up.
        await repo.addContact(
          user.name,
          user.phone,
          null,
          linkedUserUid: user.uid,
          verificationMethod: 'phone',
          isRetailer: user.roles.contains(BusinessRole.retailer),
          isWholesaler: user.roles.contains(BusinessRole.wholesaler),
          isBroker: user.roles.contains(BusinessRole.broker),
          isSupplier: user.roles.contains(BusinessRole.supplier),
        );
      } else {
        await repo.addContact(entry.contact.name, entry.phone, null);
      }
      ref.invalidate(allContactsProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('${user?.name ?? entry.contact.name} saved to your ledger'),
        backgroundColor: AppColors.positive,
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.negative,
      ));
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  bool _matches(PhoneBookEntry e) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return e.contact.name.toLowerCase().contains(q) ||
        (e.user?.name.toLowerCase().contains(q) ?? false) ||
        (digits.length >= 3 && e.phone.replaceAll(RegExp(r'\D'), '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final importAsync = ref.watch(phoneBookImportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: AppTopBar(
                eyebrow: 'CONTACTS',
                title: 'From your phone',
                leading: AppTopBarAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            ...importAsync.when(
              loading: () => [const _CenteredStatus(text: 'Reading your contacts…')],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not read your contacts',
                    subtitle: '$e',
                    iconColor: AppColors.negative,
                  ),
                ),
              ],
              data: (state) => switch (state) {
                PhoneBookNeedsAccess(:final permanently) => [_accessSliver(permanently)],
                PhoneBookLoaded() => _loadedSlivers(state),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Permission ──────────────────────────────────────────────────────────

  Widget _accessSliver(bool permanently) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_rounded, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'Find your trading partners',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              permanently
                  ? 'Contacts access is turned off for HisabET. Turn it on in Settings → Permissions → Contacts.'
                  : 'Allow HisabET to read your contacts to see who is already on HisabET and save anyone in one tap. '
                      'Numbers are only checked, never stored.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle.copyWith(color: colorScheme.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton.icon(
                icon: Icon(permanently ? Icons.settings_rounded : Icons.lock_open_rounded, size: AppDimensions.iconSm),
                label: Text(permanently ? 'Open Settings' : 'Allow access'),
                onPressed: () async {
                  if (permanently) {
                    _awaitingSettings = true;
                    await ref.read(phoneBookSourceProvider).openSettings();
                  } else {
                    ref.invalidate(phoneBookImportProvider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loaded ──────────────────────────────────────────────────────────────

  List<Widget> _loadedSlivers(PhoneBookLoaded state) {
    final ledger = ref.watch(allContactsProvider).valueOrNull ?? const [];
    final match = matchPhoneBook(
      contacts: state.contacts,
      usersByPhone: state.usersByPhone,
      savedUids: {for (final c in ledger) if (c.linkedUserUid != null) c.linkedUserUid!},
      savedPhones: {
        for (final c in ledger)
          if (c.phoneNumber != null && c.phoneNumber!.isNotEmpty) PhoneUtil.normalize(c.phoneNumber!),
      },
    );

    if (match.total == 0) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.contact_phone_outlined,
            title: 'No contacts with phone numbers',
            subtitle: 'Contacts saved on this phone will appear here.',
          ),
        ),
      ];
    }

    final onHisabet = match.onHisabet.where(_matches).toList();
    final others = match.notOnHisabet.where(_matches).toList();

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.md),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchBar(
                margin: EdgeInsets.zero,
                controller: _searchController,
                hintText: 'Search ${match.total} contacts',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: AppDimensions.md),
              _SummaryStrip(onHisabet: match.onHisabet.length, others: match.notOnHisabet.length),
              if (state.directoryUnavailable) ...[
                const SizedBox(height: AppDimensions.md),
                const _InlineNotice(
                  icon: Icons.cloud_off_rounded,
                  text: 'Offline — could not check who is on HisabET. You can still save contacts.',
                ),
              ],
            ],
          ),
        ),
      ),
      if (onHisabet.isNotEmpty) ...[
        _SectionHeader(
          label: 'On HisabET',
          count: onHisabet.length,
          caption: 'Verified accounts. Their entries are confirmed from both sides.',
        ),
        _entriesSliver(onHisabet),
      ],
      if (others.isNotEmpty) ...[
        _SectionHeader(
          label: 'Not on HisabET yet',
          count: others.length,
          caption: 'Saved as private records only you can see.',
        ),
        _entriesSliver(others),
      ],
      if (onHisabet.isEmpty && others.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: 'Nobody in your contacts matches "$_query".',
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xxxl)),
    ];
  }

  Widget _entriesSliver(List<PhoneBookEntry> entries) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return _EntryRow(
            entry: entry,
            query: _query,
            isFirst: i == 0,
            isLast: i == entries.length - 1,
            state: entry.alreadySaved
                ? AppAddPillState.done
                : (_saving.contains(_key(entry)) ? AppAddPillState.busy : AppAddPillState.idle),
            onSave: () => _save(entry),
          );
        },
      ),
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────────

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimensions.lg),
          Text(text, style: AppTextStyles.cardSubtitle.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.onHisabet, required this.others});
  final int onHisabet;
  final int others;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget cell(String value, String label, Color tone) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: isDark ? AppColors.hairlineDark : AppColors.hairline),
      ),
      child: Row(
        children: [
          cell('$onHisabet', 'on HisabET', isDark ? AppColors.primaryBright : AppColors.primary),
          Container(width: 1, height: 32, color: isDark ? AppColors.hairlineDark : AppColors.hairline),
          const SizedBox(width: AppDimensions.lg),
          cell('$others', 'not on HisabET yet', colorScheme.onSurface),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.warning),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, required this.caption});
  final String label;
  final int count;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.lg,
        AppDimensions.pagePaddingH,
        AppDimensions.sm,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  '$count',
                  style: AppTextStyles.sectionLabel.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(caption, style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// One person, as a row of the section's grouped surface.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.query,
    required this.isFirst,
    required this.isLast,
    required this.state,
    required this.onSave,
  });

  final PhoneBookEntry entry;
  final String query;
  final bool isFirst;
  final bool isLast;
  final AppAddPillState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = entry.user;
    final title = user?.name ?? entry.contact.name;
    final secondary = user != null && user.name.toLowerCase() != entry.contact.name.toLowerCase()
        ? '${entry.contact.name} · ${entry.phone}'
        : entry.phone;

    return AppGroupedRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: state == AppAddPillState.idle ? onSave : null,
      child: Row(
        children: [
          AppInitialAvatar(name: title, verified: user != null),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHighlightedText(
                  title,
                  query: query,
                  style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (user != null) ...[const AppHisabetBadge(), const SizedBox(width: 6)],
                    Expanded(
                      child: AppHighlightedText(
                        secondary,
                        query: query,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          AppAddPill(state: state, onTap: onSave),
        ],
      ),
    );
  }
}
