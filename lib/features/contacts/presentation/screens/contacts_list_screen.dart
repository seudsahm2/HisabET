import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    final index = widget.initialFilterIndex.clamp(0, _kLedgerFilters.length - 1);
    _selectedFilter = _kLedgerFilters[index];
    _searchController.addListener(_syncSearchQuery);
  }

  @override
  void dispose() {
    _searchController.removeListener(_syncSearchQuery);
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearchQuery() {
    if (!_isGlobalSearch) {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    } else {
      setState(() {});
    }
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
    try {
      final repo = ref.read(contactsRepositoryProvider);
      
      final email = user['email']?.toString();
      final phone = user['phone']?.toString();
      final rolesList = (user['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      await repo.addContact(
        user['name']?.toString() ?? 'Unknown Business',
        phone,
        user['shop']?.toString(),
        linkedUserUid: user['uid']?.toString(),
        verificationMethod: email != null && email.isNotEmpty ? 'email' : 'phone',
        isRetailer: rolesList.contains('Retailer'),
        isWholesaler: rolesList.contains('Wholesaler'),
        isBroker: rolesList.contains('Broker'),
        isSupplier: rolesList.contains('Supplier'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
        ref.invalidate(allContactsProvider);
      }
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
    }
  }

  Widget _buildNetworkUserCard(Map<String, dynamic> user) {
    final uid = user['uid']?.toString();
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';
    final roles = (user['roles'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? '';

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = uid != null && currentUid == uid;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (roles.isNotEmpty)
                  Text(roles.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                if (email.isNotEmpty || phone.isNotEmpty)
                  Text(
                    email.isNotEmpty ? email : phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          if (isCurrentUser)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm),
              child: Text(
                'This is you',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint),
              ),
            )
          else
            OutlinedButton.icon(
              label: const Text('Add'),
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addContact(user),
            ),
        ],
      ),
    );
  }

  List<ContactModel> _applyFilters(List<ContactModel> contacts) {
    var list = contacts;

    switch (_selectedFilter) {
      case 'Retailers':
        list = list.where((contact) => contact.isRetailer).toList();
        break;
      case 'Wholesalers':
        list = list.where((contact) => contact.isWholesaler).toList();
        break;
      case 'Brokers':
        list = list.where((contact) => contact.isBroker).toList();
        break;
      case 'Suppliers':
        list = list.where((contact) => contact.isSupplier || contact.role == ContactRole.supplier).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((contact) {
        return contact.name.toLowerCase().contains(_searchQuery) ||
            (contact.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final requestsCount = ref.watch(connectionRequestsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppMissionHeader(
              eyebrow: 'LEDGER',
              title: 'Contacts',
              trailing: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConnectionInboxScreen()),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded),
                    tooltip: 'Requests',
                  ),
                  if (requestsCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: AppStatusBadge.danger(
                        label: requestsCount.toString(),
                        small: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.md,
              AppDimensions.pagePaddingH,
              AppDimensions.md,
            ),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                style: AppCardStyle.glass,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _isGlobalSearch ? (_) => _performNetworkSearch() : null,
                        decoration: InputDecoration(
                          hintText: _isGlobalSearch ? 'Search global network...' : 'Search contacts...',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: PopupMenuButton<bool>(
                              initialValue: _isGlobalSearch,
                              tooltip: 'Select search scope',
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              offset: const Offset(0, 40),
                              onSelected: (val) {
                                if (val != _isGlobalSearch) {
                                  setState(() {
                                    _isGlobalSearch = val;
                                    _searchController.clear();
                                    if (_isGlobalSearch) {
                                      _searchQuery = '';
                                    } else {
                                      _hasNetworkSearched = false;
                                      _networkResults.clear();
                                    }
                                  });
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: false,
                                  child: Row(
                                    children: [
                                      Icon(Icons.contacts_rounded, size: 20, color: !_isGlobalSearch ? AppColors.primary : AppColors.textHint),
                                      const SizedBox(width: AppDimensions.md),
                                      Text('Local Contacts', style: TextStyle(fontWeight: !_isGlobalSearch ? FontWeight.bold : FontWeight.normal)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: true,
                                  child: Row(
                                    children: [
                                      Icon(Icons.public_rounded, size: 20, color: _isGlobalSearch ? AppColors.primary : AppColors.textHint),
                                      const SizedBox(width: AppDimensions.md),
                                      Text('Global Network', style: TextStyle(fontWeight: _isGlobalSearch ? FontWeight.bold : FontWeight.normal)),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_isGlobalSearch ? Icons.public_rounded : Icons.contacts_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(_isGlobalSearch ? 'Network' : 'Local', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_drop_down_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    if (_isGlobalSearch) {
                                      setState(() {
                                        _hasNetworkSearched = false;
                                        _networkResults.clear();
                                      });
                                    }
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isGlobalSearch)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                0,
                AppDimensions.pagePaddingH,
                AppDimensions.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _kLedgerFilters.map((filter) {
                    final selected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppDimensions.sm),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedFilter = filter),
                        labelStyle: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        side: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (!_isGlobalSearch)
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sm)),
          // ── Contact List ──────────────────────────────────────────────
          if (_isGlobalSearch) ...[
            if (_isNetworkLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_hasNetworkSearched && _networkResults.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
                      SizedBox(height: AppDimensions.md),
                      Text('No users found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      SizedBox(height: AppDimensions.sm),
                      Text('Try searching by an exact email or phone number.', style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                ),
              )
            else if (!_hasNetworkSearched)
              ref.watch(networkSuggestionsProvider).when(
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => const SliverFillRemaining(child: Center(child: Text('Failed to load suggestions'))),
                data: (suggestions) {
                  if (suggestions.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_alt_outlined, size: 64, color: AppColors.primaryLight),
                            SizedBox(height: AppDimensions.md),
                            Text('Discover Network', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            SizedBox(height: AppDimensions.sm),
                            Text('Find businesses instantly to add as verified contacts.', style: TextStyle(color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: AppDimensions.md),
                            child: Text(
                              'People You May Know',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return _buildNetworkUserCard(suggestions[index - 1]);
                      }, childCount: suggestions.length + 1),
                    ),
                  );
                },
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildNetworkUserCard(_networkResults[index]);
                  }, childCount: _networkResults.length),
                ),
              ),
          ] else ...[
            contactsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            data: (contacts) {
              final filteredContacts = _applyFilters(contacts);

              if (filteredContacts.isEmpty) {
                return SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: _searchQuery.isNotEmpty ? 'No Matches Found' : 'No Contacts',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No contacts match "$_searchQuery".'
                        : 'Add contacts manually to start the ledger.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final contact = filteredContacts[index];
                    final balance = contact.netBalance.toDouble();
                    final isPositive = balance >= 0;

                    return AppListTile(
                      leadingIcon: Icons.badge_rounded,
                      leadingColor: isPositive ? AppColors.positive : AppColors.negative,
                      title: contact.name,
                      subtitle: _buildContactSubtitle(contact),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: contact)));
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
                  }, childCount: filteredContacts.length),
                ),
              );
            },
          ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("Add Contact"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final allowed = await _ensureCreateContactPermission(messenger, ref);
          if (!allowed) return;
          await navigator.push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
          ref.invalidate(allContactsProvider);
        },
      ),
    );
  }

  String _buildContactSubtitle(ContactModel contact) {
    final roles = contact.roleLabels;
    final roleStr = roles.join(' · ');
    final identifier = contact.phoneNumber?.isNotEmpty == true
        ? contact.phoneNumber!
        : (contact.verificationMethod == 'email' ? 'via email' : 'No Phone');
    return '$identifier  |  $roleStr';
  }

  Future<bool> _ensureCreateContactPermission(ScaffoldMessengerState messenger, WidgetRef ref) async {
    final canProcessSales = ref.read(hasPermissionProvider(TeamPermission.processSales));
    final canManagePurchases = ref.read(hasPermissionProvider(TeamPermission.managePurchases));
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
          child: Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
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
