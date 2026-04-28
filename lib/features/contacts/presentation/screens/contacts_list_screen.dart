import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/network_search_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/connection_inbox_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/contact_detail_screen.dart';

// Filter options
const _kRoleFilters = ['All', 'Retailers', 'Wholesalers', 'Brokers', 'Suppliers'];

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

  @override
  void initState() {
    super.initState();
    final idx = widget.initialFilterIndex.clamp(0, _kRoleFilters.length - 1);
    _selectedFilter = _kRoleFilters[idx];
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactModel> _applyFilters(List<ContactModel> contacts) {
    var list = contacts;
    // Role filter
    switch (_selectedFilter) {
      case 'Retailers':
        list = list.where((c) => c.isRetailer).toList();
        break;
      case 'Wholesalers':
        list = list.where((c) => c.isWholesaler).toList();
        break;
      case 'Brokers':
        list = list.where((c) => c.isBroker).toList();
        break;
      case 'Suppliers':
        list = list.where((c) => c.isSupplier || c.role == ContactRole.supplier).toList();
        break;
    }
    // Local search
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) {
        return c.name.toLowerCase().contains(_searchQuery) ||
            (c.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
          builder: (context, snapshot) {
            String name = 'Merchant';
            if (snapshot.hasData && snapshot.data?.data() != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (data['name'] != null) name = data['name'];
            }
            return Text('Hello, $name');
          },
        ),
        actions: [
          // Network / Global search — clearly labeled
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: 'Search HisabET Network',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetworkSearchScreen()));
              ref.invalidate(allContactsProvider);
            },
          ),
          // Notification bell with badge
          Consumer(
            builder: (context, ref, child) {
              final requestsAsync = ref.watch(connectionRequestsProvider);
              final pendingCount = requestsAsync.valueOrNull?.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    tooltip: 'Connection Requests',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectionInboxScreen()));
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: AppStatusBadge.danger(
                        label: pendingCount.toString(),
                        small: true,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search your contacts…',
              margin: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.md,
                AppDimensions.pagePaddingH,
                0,
              ),
            ),
          ),
          // ── Role Filter Chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimensions.sm),
              child: AppFilterChips<String>(
                options: _kRoleFilters,
                selected: _selectedFilter,
                labelBuilder: (s) => s,
                onSelected: (s) => setState(() => _selectedFilter = s),
              ),
            ),
          ),
          // ── Network Search Hint Banner ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, AppDimensions.sm, AppDimensions.pagePaddingH, 0),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetworkSearchScreen()));
                  ref.invalidate(allContactsProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.travel_explore_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.sm),
                      const Expanded(
                        child: Text(
                          'Find & add contacts from the HisabET network',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
          // ── Contact List ──────────────────────────────────────────────
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
                        : 'Add contacts manually or search the HisabET network.',
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("Add Contact"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final allowed = await _ensureCreateContactPermission(context, ref);
          if (!allowed) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
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

  Future<bool> _ensureCreateContactPermission(BuildContext context, WidgetRef ref) async {
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

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
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
