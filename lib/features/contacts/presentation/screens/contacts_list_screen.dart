import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/connection_inbox_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/contact_detail_screen.dart';

const _kLedgerFilters = ['All', 'Retailers', 'Wholesalers', 'Brokers', 'Suppliers'];

class ContactsListScreen extends ConsumerStatefulWidget {
  final int initialFilterIndex;

  const ContactsListScreen({super.key, this.initialFilterIndex = 0});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  late String _selectedFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isGlobalSearch = false;
  bool _isNetworkLoading = false;
  List<Map<String, dynamic>> _networkResults = [];
  bool _hasNetworkSearched = false;

  /// UIDs added during this session — the row flips to "Added" straight away
  /// instead of leaving a live button that can add the same person twice.
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
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      if (_isGlobalSearch) {
        if (trimmed.isEmpty) {
          _hasNetworkSearched = false;
          _networkResults = [];
        }
      } else {
        _searchQuery = trimmed.toLowerCase();
      }
    });
  }

  void _setScope(bool global) {
    if (global == _isGlobalSearch) return;
    setState(() {
      _isGlobalSearch = global;
      _searchController.clear();
      _searchQuery = '';
      _hasNetworkSearched = false;
      _networkResults = [];
    });
  }

  Future<void> _performNetworkSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isNetworkLoading = true;
      _hasNetworkSearched = true;
      _networkResults = [];
    });

    final repo = ref.read(contactsRepositoryProvider);
    final results = await repo.searchNetwork(query);

    if (mounted) {
      setState(() {
        _networkResults = results;
        _isNetworkLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, dynamic> user) async {
    final uid = user['uid']?.toString();
    setState(() => _addingUid = uid);

    try {
      final repo = ref.read(contactsRepositoryProvider);

      final email = user['email']?.toString();
      final phone = user['phone']?.toString();
      final roles = BusinessRole.parseAll(user['roles'] as List<dynamic>?);

      await repo.addContact(
        user['name']?.toString() ?? 'Unknown Business',
        phone,
        user['shop']?.toString(),
        linkedUserUid: uid,
        verificationMethod: email != null && email.isNotEmpty ? 'email' : 'phone',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['name'] ?? 'Contact'} added to your ledger'),
          backgroundColor: AppColors.positive,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _addingUid = null);
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.negative),
      );
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<ContactModel> _applySearch(List<ContactModel> contacts) {
    if (_isGlobalSearch || _searchQuery.isEmpty) return contacts;
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery) ||
          (contact.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  List<ContactModel> _applyRole(List<ContactModel> contacts, String filter) {
    return switch (filter) {
      'Retailers' => contacts.where((c) => c.isRetailer).toList(),
      'Wholesalers' => contacts.where((c) => c.isWholesaler).toList(),
      'Brokers' => contacts.where((c) => c.isBroker).toList(),
      'Suppliers' => contacts
          .where((c) => c.isSupplier || c.role == ContactRole.supplier)
          .toList(),
      _ => contacts,
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final requestsCount =
        ref.watch(connectionRequestsProvider).valueOrNull?.length ?? 0;

    final allContacts = contactsAsync.valueOrNull ?? const <ContactModel>[];
    final searched = _applySearch(allContacts);

    // Anyone already in the ledger shows as "Added" in network results, not as
    // a button that would fail on tap.
    final linkedUids = <String>{
      for (final contact in allContacts)
        if (contact.linkedUserUid != null) contact.linkedUserUid!,
      ..._addedUids,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppTopBar(
                eyebrow: 'LEDGER',
                title: 'Contacts',
                actions: [
                  AppTopBarAction(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Connection requests',
                    badge: requestsCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConnectionInboxScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                0,
                AppDimensions.pagePaddingH,
                AppDimensions.md,
              ),
              sliver: SliverToBoxAdapter(
                child: AppSearchBar(
                  margin: EdgeInsets.zero,
                  controller: _searchController,
                  hintText: _isGlobalSearch
                      ? 'Email or phone number'
                      : 'Search contacts',
                  onChanged: _onSearchChanged,
                  onSubmitted:
                      _isGlobalSearch ? (_) => _performNetworkSearch() : null,
                  textInputAction: _isGlobalSearch
                      ? TextInputAction.search
                      : TextInputAction.done,
                  trailing: _SearchScopeButton(
                    isGlobal: _isGlobalSearch,
                    onChanged: _setScope,
                  ),
                ),
              ),
            ),

            // ── Role filters (ledger only) ────────────────────────────────
            if (!_isGlobalSearch)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: AppFilterChips<String>(
                    options: _kLedgerFilters,
                    selected: _selectedFilter,
                    labelBuilder: (filter) => filter,
                    countBuilder: (filter) =>
                        _applyRole(searched, filter).length,
                    onSelected: (filter) =>
                        setState(() => _selectedFilter = filter),
                  ),
                ),
              ),

            // ── Body ──────────────────────────────────────────────────────
            if (_isGlobalSearch)
              ..._networkSlivers(linkedUids)
            else
              _ledgerSliver(contactsAsync, searched),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Contact'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final allowed = await _ensureCreateContactPermission(messenger, ref);
          if (!allowed) return;
          await navigator
              .push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
          ref.invalidate(allContactsProvider);
        },
      ),
    );
  }

  // ── Ledger list ───────────────────────────────────────────────────────────

  Widget _ledgerSliver(
    AsyncValue<List<ContactModel>> contactsAsync,
    List<ContactModel> searched,
  ) {
    return contactsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load contacts',
          subtitle: '$err',
          iconColor: AppColors.negative,
        ),
      ),
      data: (_) {
        final contacts = _applyRole(searched, _selectedFilter);

        if (contacts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: _searchQuery.isNotEmpty ? 'No matches' : 'No contacts yet',
              subtitle: _searchQuery.isNotEmpty
                  ? 'Nothing matches "$_searchQuery".'
                  : 'Add a contact to start a shared ledger.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _contactRow(contacts[index]),
              childCount: contacts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _contactRow(ContactModel contact) {
    final balance = contact.netBalance.toDouble();
    final isPositive = balance >= 0;
    final roles = contact.roleLabels;

    return AppListTile(
      leadingIcon: Icons.badge_rounded,
      leadingColor: isPositive ? AppColors.positive : AppColors.negative,
      title: contact.name,
      // Roles only. The old subtitle also printed "via email" / "No Phone",
      // which said nothing about who this contact is to the business.
      subtitle: roles.isEmpty ? null : roles.join(' · '),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)),
        );
        ref.invalidate(allContactsProvider);
      },
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVerificationBadge(contact.verificationStatus),
              const SizedBox(width: AppDimensions.xs),
              AppStatusBadge(
                label: isPositive ? 'COLLECT' : 'DUE',
                color: isPositive ? AppColors.positive : AppColors.negative,
                small: true,
              ),
            ],
          ),
          AppAmountText(
            amount: contact.netBalance.toString(),
            isPositive: isPositive,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  // ── Network search ────────────────────────────────────────────────────────

  List<Widget> _networkSlivers(Set<String> linkedUids) {
    if (_isNetworkLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_hasNetworkSearched) {
      if (_networkResults.isEmpty) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No businesses found',
              subtitle: 'Search by the exact email or phone number they '
                  'registered with.',
            ),
          ),
        ];
      }
      return [
        _networkList(
          label: 'Search results',
          users: _networkResults,
          linkedUids: linkedUids,
        ),
      ];
    }

    return [
      ref.watch(networkSuggestionsProvider).when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const SliverFillRemaining(
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
                    title: 'Discover the network',
                    subtitle: 'Search an email or phone number to find a '
                        'business and add it as a verified contact.',
                  ),
                );
              }
              return _networkList(
                label: 'Businesses you may know',
                users: suggestions,
                linkedUids: linkedUids,
              );
            },
          ),
    ];
  }

  Widget _networkList({
    required String label,
    required List<Map<String, dynamic>> users,
    required Set<String> linkedUids,
  }) {
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: Text(label.toUpperCase(),
                    style: AppTextStyles.sectionLabel),
              );
            }
            return _networkRow(users[index - 1], linkedUids);
          },
          childCount: users.length + 1,
        ),
      ),
    );
  }

  /// Same row as the saved-contact list — same avatar box, same title, same
  /// subtitle — so the two lists read as one thing. Only the trailing slot
  /// differs: there is no balance to show yet, so it carries the add control.
  Widget _networkRow(Map<String, dynamic> user, Set<String> linkedUids) {
    final uid = user['uid']?.toString();
    final name = user['name']?.toString() ?? 'Unknown Business';
    final roles = BusinessRole.parseAll(user['roles'] as List<dynamic>?)
        .map((r) => r.label)
        .toList();

    final isCurrentUser =
        uid != null && FirebaseAuth.instance.currentUser?.uid == uid;
    final alreadyAdded = uid != null && linkedUids.contains(uid);

    return AppListTile(
      leadingText: name,
      leadingColor: AppColors.primary,
      title: name,
      subtitle: roles.isEmpty ? null : roles.join(' · '),
      trailing: isCurrentUser
          ? Text('You', style: AppTextStyles.badgeLabel.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ))
          : _AddContactAction(
              state: alreadyAdded
                  ? _AddState.added
                  : (_addingUid != null && _addingUid == uid
                      ? _AddState.busy
                      : _AddState.idle),
              onTap: () => _addContact(user),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<bool> _ensureCreateContactPermission(
      ScaffoldMessengerState messenger, WidgetRef ref) async {
    final canProcessSales =
        ref.read(hasPermissionProvider(TeamPermission.processSales));
    final canManagePurchases =
        ref.read(hasPermissionProvider(TeamPermission.managePurchases));
    if (canProcessSales || canManagePurchases) return true;

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

  Widget _buildVerificationBadge(ContactVerificationStatus status) {
    switch (status) {
      case ContactVerificationStatus.verified:
        return const Tooltip(
          message: 'Verified',
          child: Icon(Icons.verified_rounded, color: AppColors.info, size: 16),
        );
      case ContactVerificationStatus.pending:
        return AppStatusBadge.warning(label: 'PENDING', small: true);
      case ContactVerificationStatus.expired:
        return AppStatusBadge.danger(label: 'EXPIRED', small: true);
      case ContactVerificationStatus.unverified:
        return const SizedBox.shrink();
    }
  }
}

// ── Search scope ────────────────────────────────────────────────────────────

/// Scope selector docked inside the right edge of the search field.
///
/// It used to be a filled pill crammed into the field's `prefixIcon` slot,
/// which put a third background in front of the caret. Here it is part of the
/// field, behind a hairline, reading as "search *what*" — the label is always
/// visible, so the current scope is never a guess.
class _SearchScopeButton extends StatelessWidget {
  const _SearchScopeButton({required this.isGlobal, required this.onChanged});

  final bool isGlobal;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;

    return PopupMenuButton<bool>(
      initialValue: isGlobal,
      tooltip: 'Search scope',
      position: PopupMenuPosition.under,
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.hairlineDark : AppColors.hairline,
        ),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: false,
          child: _ScopeMenuRow(
            icon: Icons.contacts_rounded,
            label: 'My contacts',
            active: !isGlobal,
          ),
        ),
        PopupMenuItem(
          value: true,
          child: _ScopeMenuRow(
            icon: Icons.public_rounded,
            label: 'Network',
            active: isGlobal,
          ),
        ),
      ],
      child: SizedBox(
        height: 46,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGlobal ? Icons.public_rounded : Icons.contacts_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                isGlobal ? 'Network' : 'Local',
                style: AppTextStyles.badgeLabel.copyWith(
                  fontSize: 12.5,
                  color: accent,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeMenuRow extends StatelessWidget {
  const _ScopeMenuRow({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryBright : AppColors.primary;
    final tone = active ? accent : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (active) Icon(Icons.check_rounded, size: 16, color: accent),
      ],
    );
  }
}

// ── Add control ─────────────────────────────────────────────────────────────

enum _AddState { idle, busy, added }

/// The add control for a network result.
///
/// It replaces an `OutlinedButton.icon`, which at default Material metrics was
/// nearly as tall as the row it sat in and pulled more attention than the name
/// beside it. This is a tonal pill in the brand wash: clearly tappable, clearly
/// secondary to the person's name.
///
/// All three states occupy the same box, so the row does not resize while the
/// write is in flight or after it lands.
class _AddContactAction extends StatelessWidget {
  const _AddContactAction({required this.state, required this.onTap});

  final _AddState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdded = state == _AddState.added;

    final fill = isAdded
        ? Colors.transparent
        : (isDark
            ? AppColors.primaryBright.withValues(alpha: 0.16)
            : AppColors.primaryContainer);
    final tone = isAdded
        ? colorScheme.onSurfaceVariant
        : (isDark ? AppColors.primaryBright : AppColors.primary);

    final pill = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: isAdded
            ? Border.all(
                color: isDark ? AppColors.hairlineDark : AppColors.border)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: switch (state) {
              _AddState.busy => Padding(
                  padding: const EdgeInsets.all(1),
                  child: CircularProgressIndicator(strokeWidth: 2, color: tone),
                ),
              _AddState.added => Icon(Icons.check_rounded, size: 16, color: tone),
              _AddState.idle => Icon(Icons.add_rounded, size: 16, color: tone),
            },
          ),
          const SizedBox(width: 5),
          Text(
            isAdded ? 'Added' : 'Add',
            style: AppTextStyles.badgeLabel.copyWith(fontSize: 12.5, color: tone),
          ),
        ],
      ),
    );

    if (state != _AddState.idle) {
      return Semantics(
        label: isAdded ? 'Already in your contacts' : 'Adding contact',
        child: pill,
      );
    }

    return Semantics(
      button: true,
      label: 'Add contact',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        // Pads a 34pt pill out to a 44pt target without changing how it looks.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: pill,
        ),
      ),
    );
  }
}
