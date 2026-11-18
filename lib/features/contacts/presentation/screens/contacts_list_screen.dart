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
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/connection_inbox_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/import_phone_contacts_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/contact_detail_screen.dart';

const _kLedgerFilters = ['All', 'Retailers', 'Wholesalers', 'Brokers', 'Suppliers'];

enum _Scope { saved, network }

/// How the "Find on HisabET" box reads its input. Phone first: it is what
/// traders know each other by, and the only identifier that is verified and
/// unique on every account.
enum _NetworkMode { phone, text }

class ContactsListScreen extends ConsumerStatefulWidget {
  final int initialFilterIndex;

  const ContactsListScreen({super.key, this.initialFilterIndex = 0});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  late String _selectedFilter;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  _Scope _scope = _Scope.saved;

  _NetworkMode _networkMode = _NetworkMode.phone;
  Timer? _debounce;
  bool _networkLoading = false;
  String? _networkSearchedFor;
  List<Map<String, dynamic>> _networkResults = [];

  /// UIDs added during this session — the row flips to "Added" straight away.
  final Set<String> _addedUids = {};
  String? _addingUid;

  @override
  void initState() {
    super.initState();
    final index = widget.initialFilterIndex.clamp(0, _kLedgerFilters.length - 1);
    _selectedFilter = _kLedgerFilters[index];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _setScope(_Scope scope) {
    if (scope == _scope) return;
    _debounce?.cancel();
    setState(() {
      _scope = scope;
      _searchController.clear();
      _query = '';
      _networkResults = [];
      _networkSearchedFor = null;
      _networkLoading = false;
    });
    if (scope == _Scope.network) _searchFocus.requestFocus();
  }

  void _setNetworkMode(_NetworkMode mode) {
    _debounce?.cancel();
    setState(() {
      _networkMode = mode;
      _searchController.clear();
      _query = '';
      _networkResults = [];
      _networkSearchedFor = null;
    });
    // Re-focus so the keyboard switches between the number pad and letters.
    _searchFocus.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 60), _searchFocus.requestFocus);
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    if (_scope != _Scope.network) return;

    _debounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _networkResults = [];
        _networkSearchedFor = null;
        _networkLoading = false;
      });
      return;
    }
    // Search by itself once the input is complete enough to match anyone:
    // a full phone number, or an email / name of 3+ characters.
    final ready = _networkMode == _NetworkMode.phone
        ? PhoneUtil.isValidE164(PhoneUtil.normalize(trimmed))
        : trimmed.length >= 3;
    if (ready) {
      _debounce = Timer(const Duration(milliseconds: 450), _searchNetwork);
    }
  }

  Future<void> _searchNetwork() async {
    final raw = _query;
    if (raw.isEmpty) return;
    final query = _networkMode == _NetworkMode.phone ? PhoneUtil.normalize(raw) : raw;
    if (query == _networkSearchedFor && !_networkLoading) return;

    setState(() {
      _networkLoading = true;
      _networkSearchedFor = query;
    });
    final results = await ref.read(contactsRepositoryProvider).searchNetwork(query);
    if (!mounted || _networkSearchedFor != query) return;
    setState(() {
      _networkResults = results;
      _networkLoading = false;
    });
  }

  Future<void> _addNetworkUser(Map<String, dynamic> user) async {
    final uid = user['uid']?.toString();
    setState(() => _addingUid = uid);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final roles = BusinessRole.parseAll(user['roles'] as List<dynamic>?);
      final email = user['email']?.toString();
      await ref.read(contactsRepositoryProvider).addContact(
            user['name']?.toString() ?? 'Unknown Business',
            user['phone']?.toString(),
            user['shop']?.toString(),
            linkedUserUid: uid,
            verificationMethod: (user['phone']?.toString().isNotEmpty ?? false)
                ? 'phone'
                : (email != null && email.isNotEmpty ? 'email' : 'phone'),
            isRetailer: roles.contains(BusinessRole.retailer),
            isWholesaler: roles.contains(BusinessRole.wholesaler),
            isBroker: roles.contains(BusinessRole.broker),
            isSupplier: roles.contains(BusinessRole.supplier),
          );
      if (!mounted) return;
      setState(() {
        _addingUid = null;
        if (uid != null) _addedUids.add(uid);
      });
      ref.invalidate(allContactsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('${user['name'] ?? 'Contact'} added to your ledger'),
        backgroundColor: AppColors.positive,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _addingUid = null);
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.negative,
      ));
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openImport() async {
    if (!await _ensureCreateContactPermission()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportPhoneContactsScreen()));
    ref.invalidate(allContactsProvider);
  }

  Future<void> _openAddManually({String? phone}) async {
    if (!await _ensureCreateContactPermission()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddContactScreen(initialPhone: phone)));
    ref.invalidate(allContactsProvider);
  }

  Future<void> _showAddSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a contact', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppDimensions.md),
              const _SheetOption(
                value: 'import',
                icon: Icons.contacts_rounded,
                title: 'Import from phone contacts',
                subtitle: 'See who is on HisabET and save anyone in one tap',
                isFirst: true,
              ),
              const _SheetOption(
                value: 'manual',
                icon: Icons.dialpad_rounded,
                title: 'Add by phone number',
                subtitle: 'Type a number — we check if they are on HisabET',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'import') await _openImport();
    if (choice == 'manual') await _openAddManually();
  }

  Future<bool> _ensureCreateContactPermission() async {
    final messenger = ScaffoldMessenger.of(context);
    if (ref.read(hasPermissionProvider(TeamPermission.processSales)) ||
        ref.read(hasPermissionProvider(TeamPermission.managePurchases))) {
      return true;
    }
    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'permission_denied',
          entityType: 'contact',
          message: 'Denied open_add_contact for role ${actorRole.name}.',
        );
    ref.invalidate(recentAuditLogsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<ContactModel> _applySearch(List<ContactModel> contacts) {
    if (_query.isEmpty) return contacts;
    final q = _query.toLowerCase();
    final digits = _query.replaceAll(RegExp(r'\D'), '');
    return contacts.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      final phone = c.phoneNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
      return digits.length >= 3 && phone.contains(digits);
    }).toList();
  }

  List<ContactModel> _applyRole(List<ContactModel> contacts, String filter) {
    return switch (filter) {
      'Retailers' => contacts.where((c) => c.isRetailer).toList(),
      'Wholesalers' => contacts.where((c) => c.isWholesaler).toList(),
      'Brokers' => contacts.where((c) => c.isBroker).toList(),
      'Suppliers' => contacts.where((c) => c.isSupplier || c.role == ContactRole.supplier).toList(),
      _ => contacts,
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final requestsCount = ref.watch(connectionRequestsProvider).valueOrNull?.length ?? 0;
    final allContacts = contactsAsync.valueOrNull ?? const <ContactModel>[];

    final linkedUids = <String>{
      for (final c in allContacts)
        if (c.linkedUserUid != null) c.linkedUserUid!,
      ..._addedUids,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: AppTopBar(
                eyebrow: 'LEDGER',
                title: 'Contacts',
                actions: [
                  AppTopBarAction(
                    icon: Icons.contacts_rounded,
                    tooltip: 'Import from phone contacts',
                    onTap: _openImport,
                  ),
                  AppTopBarAction(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Connection requests',
                    badge: requestsCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConnectionInboxScreen()),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.md),
              sliver: SliverToBoxAdapter(child: _searchHeader(allContacts.length)),
            ),
            if (_scope == _Scope.saved) ...[
              if (allContacts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.md),
                    child: AppFilterChips<String>(
                      options: _kLedgerFilters,
                      selected: _selectedFilter,
                      labelBuilder: (f) => f,
                      countBuilder: (f) => _applyRole(_applySearch(allContacts), f).length,
                      onSelected: (f) => setState(() => _selectedFilter = f),
                    ),
                  ),
                ),
              ..._savedSlivers(contactsAsync, allContacts),
            ] else
              ..._networkSlivers(linkedUids),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add contact'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddSheet,
      ),
    );
  }

  Widget _searchHeader(int savedCount) {
    final network = _scope == _Scope.network;
    final phoneMode = _networkMode == _NetworkMode.phone;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSegmentedTabs<_Scope>(
          selected: _scope,
          onChanged: _setScope,
          segments: [
            AppSegment(value: _Scope.saved, label: 'Your contacts', icon: Icons.menu_book_rounded, count: savedCount),
            const AppSegment(value: _Scope.network, label: 'Find on HisabET', icon: Icons.travel_explore_rounded),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        AppSearchBar(
          margin: EdgeInsets.zero,
          controller: _searchController,
          focusNode: _searchFocus,
          leadingIcon: network ? (phoneMode ? Icons.dialpad_rounded : Icons.alternate_email_rounded) : Icons.search_rounded,
          hintText: network
              ? (phoneMode ? 'Phone number, e.g. 0911 22 33 44' : 'Email or business name')
              : 'Search name or phone',
          keyboardType: network && phoneMode ? TextInputType.phone : TextInputType.text,
          textInputAction: network ? TextInputAction.search : TextInputAction.done,
          onChanged: _onQueryChanged,
          onSubmitted: network ? (_) => _searchNetwork() : null,
        ),
        if (network) ...[
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  phoneMode ? 'Finds verified HisabET accounts by number' : 'Exact email, or the start of a business name',
                  style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                ),
                onPressed: () => _setNetworkMode(phoneMode ? _NetworkMode.text : _NetworkMode.phone),
                child: Text(phoneMode ? 'Use email or name' : 'Use phone number'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Saved contacts ────────────────────────────────────────────────────────

  List<Widget> _savedSlivers(AsyncValue<List<ContactModel>> contactsAsync, List<ContactModel> all) {
    if (contactsAsync.isLoading && all.isEmpty) {
      return const [SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }
    if (contactsAsync.hasError && all.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load contacts',
            subtitle: '${contactsAsync.error}',
            iconColor: AppColors.negative,
          ),
        ),
      ];
    }
    if (all.isEmpty) return [_emptyLedger()];

    final contacts = _applyRole(_applySearch(all), _selectedFilter);
    if (contacts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: _query.isEmpty
                ? 'No contacts in this group yet.'
                : 'Nobody in your contacts matches "$_query". Try "Find on HisabET".',
          ),
        ),
      ];
    }

    return [
      if (_query.isNotEmpty)
        _resultsCaption('${contacts.length} ${contacts.length == 1 ? 'match' : 'matches'}'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
        sliver: SliverList.builder(
          itemCount: contacts.length,
          itemBuilder: (context, i) => _ContactRow(
            contact: contacts[i],
            query: _query,
            isFirst: i == 0,
            isLast: i == contacts.length - 1,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contacts[i])),
              );
              ref.invalidate(allContactsProvider);
            },
          ),
        ),
      ),
    ];
  }

  Widget _emptyLedger() {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'Start your ledger',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Add the people you trade with. Those already on HisabET confirm every entry from their side.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle.copyWith(color: colorScheme.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _openImport,
                icon: const Icon(Icons.contacts_rounded, size: AppDimensions.iconSm),
                label: const Text('Import from phone contacts'),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => _openAddManually(),
                icon: const Icon(Icons.dialpad_rounded, size: AppDimensions.iconSm),
                label: const Text('Add by phone number'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsCaption(String text) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.sm),
      sliver: SliverToBoxAdapter(child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel)),
    );
  }

  // ── Network ───────────────────────────────────────────────────────────────

  List<Widget> _networkSlivers(Set<String> linkedUids) {
    if (_networkLoading) {
      return const [SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }

    if (_networkSearchedFor != null) {
      if (_networkResults.isEmpty) {
        final phoneMode = _networkMode == _NetworkMode.phone;
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppEmptyState(
                    icon: Icons.person_search_rounded,
                    title: phoneMode ? 'Not on HisabET yet' : 'No businesses found',
                    subtitle: phoneMode
                        ? '$_networkSearchedFor has no HisabET account. You can still keep a private record.'
                        : 'Check the spelling, or search by phone number.',
                  ),
                  if (phoneMode) ...[
                    const SizedBox(height: AppDimensions.lg),
                    OutlinedButton.icon(
                      onPressed: () => _openAddManually(phone: _networkSearchedFor),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: AppDimensions.iconSm),
                      label: const Text('Save as private contact'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ];
      }
      return [
        _resultsCaption('${_networkResults.length} on HisabET'),
        _networkList(_networkResults, linkedUids),
      ];
    }

    if (_query.isNotEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: _networkMode == _NetworkMode.phone ? Icons.dialpad_rounded : Icons.keyboard_rounded,
            title: _networkMode == _NetworkMode.phone ? 'Keep typing the number' : 'Keep typing',
            subtitle: 'The search runs by itself, or press search on the keyboard.',
          ),
        ),
      ];
    }

    return [
      ref.watch(networkSuggestionsProvider).when(
            loading: () => const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => const SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Network unavailable',
                subtitle: 'Could not load suggestions. Check your connection.',
              ),
            ),
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'Find a trading partner',
                    subtitle: 'Type their phone number to find their verified HisabET account.',
                  ),
                );
              }
              return SliverMainAxisGroup(
                slivers: [
                  _resultsCaption('Businesses you may know'),
                  _networkList(suggestions, linkedUids),
                ],
              );
            },
          ),
    ];
  }

  Widget _networkList(List<Map<String, dynamic>> users, Set<String> linkedUids) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      sliver: SliverList.builder(
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];
          final uid = user['uid']?.toString();
          return _NetworkRow(
            user: user,
            isFirst: i == 0,
            isLast: i == users.length - 1,
            isMe: uid != null && uid == me,
            state: uid != null && linkedUids.contains(uid)
                ? AppAddPillState.done
                : (_addingUid != null && _addingUid == uid ? AppAddPillState.busy : AppAddPillState.idle),
            onAdd: () => _addNetworkUser(user),
          );
        },
      ),
    );
  }
}

// ── Rows ──────────────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.query,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final ContactModel contact;
  final String query;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = contact.netBalance;
    final settled = balance == Decimal.zero;
    final linked = contact.linkedUserUid != null;
    final roles = contact.roleLabels;
    final secondary = [
      if (roles.isNotEmpty) roles.join(' · '),
      if (contact.phoneNumber?.isNotEmpty ?? false) contact.phoneNumber!,
    ].join('  ·  ');

    return AppGroupedRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: onTap,
      child: Row(
        children: [
          AppInitialAvatar(name: contact.name, verified: linked),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppHighlightedText(
                        contact.name,
                        query: query,
                        style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface, fontSize: 15),
                      ),
                    ),
                    if (contact.verificationStatus == ContactVerificationStatus.pending) ...[
                      const SizedBox(width: 6),
                      AppStatusBadge.warning(label: 'PENDING', small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (linked) ...[const AppHisabetBadge(), const SizedBox(width: 6)],
                    Expanded(
                      child: AppHighlightedText(
                        secondary.isEmpty ? 'Private record' : secondary,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (settled)
                Text('Settled', style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant))
              else ...[
                AppMoney.directional(amount: balance, size: AppMoneySize.small),
                const SizedBox(height: 2),
                Text(
                  balance > Decimal.zero ? 'to collect' : 'to pay',
                  style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({
    required this.user,
    required this.isFirst,
    required this.isLast,
    required this.isMe,
    required this.state,
    required this.onAdd,
  });

  final Map<String, dynamic> user;
  final bool isFirst;
  final bool isLast;
  final bool isMe;
  final AppAddPillState state;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = user['name']?.toString() ?? 'Unknown Business';
    final roles = BusinessRole.parseAll(user['roles'] as List<dynamic>?).map((r) => r.label).join(' · ');

    return AppGroupedRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: isMe || state != AppAddPillState.idle ? null : onAdd,
      child: Row(
        children: [
          AppInitialAvatar(name: name, verified: true),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface, fontSize: 15),
                ),
                const SizedBox(height: 3),
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
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          if (isMe)
            Text('You', style: AppTextStyles.badgeLabel.copyWith(color: colorScheme.onSurfaceVariant))
          else
            AppAddPill(state: state, onTap: onAdd, label: 'Add', doneLabel: 'Added'),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final String value;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppGroupedRow(
      isFirst: isFirst,
      isLast: isLast,
      onTap: () => Navigator.of(context).pop(value),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryBright.withValues(alpha: 0.14) : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, color: isDark ? AppColors.primaryBright : AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
