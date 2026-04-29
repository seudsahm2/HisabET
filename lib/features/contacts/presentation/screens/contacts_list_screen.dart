import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/connection_inbox_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/network_search_screen.dart';
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
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
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
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () => _searchController.clear(),
                                ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NetworkSearchScreen()),
                        );
                        ref.invalidate(allContactsProvider);
                      },
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      label: const Text('Network'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sm)),
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
