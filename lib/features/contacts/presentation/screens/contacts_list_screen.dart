import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/contact_detail_screen.dart';

class ContactsListScreen extends ConsumerStatefulWidget {
  final int initialFilterIndex;

  const ContactsListScreen({super.key, this.initialFilterIndex = 0});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  static const _filterOptions = ['All Contacts', 'Merchants', 'Suppliers'];
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    final idx = widget.initialFilterIndex.clamp(0, _filterOptions.length - 1);
    _selectedFilter = _filterOptions[idx];
  }

  List<ContactModel> _applyRoleFilter(List<ContactModel> contacts) {
    if (_selectedFilter == 'Merchants') return contacts.where((c) => c.role == ContactRole.merchant || c.role == ContactRole.both).toList();
    if (_selectedFilter == 'Suppliers') return contacts.where((c) => c.role == ContactRole.supplier || c.role == ContactRole.both).toList();
    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);

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
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AppFilterChips<String>(
              options: _filterOptions,
              selected: _selectedFilter,
              labelBuilder: (s) => s,
              onSelected: (s) => setState(() => _selectedFilter = s),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.lg)),
          contactsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            data: (contacts) {
              final filteredContacts = _applyRoleFilter(contacts);
              if (filteredContacts.isEmpty) {
                return const SliverFillRemaining(
                  child: AppEmptyState(icon: Icons.people_outline_rounded, title: 'No Local Contacts', subtitle: 'You have not added any local address profiles yet.'),
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
                      subtitle: contact.phoneNumber ?? 'No Phone',
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
        icon: const Icon(Icons.add),
        label: const Text("New Contact"),
        onPressed: () async {
          final allowed = await _ensureCreateContactPermission(context, ref);
          if (!allowed) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
          ref.invalidate(allContactsProvider);
        },
      ),
    );
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
        return AppStatusBadge.success(label: 'VERIFIED', small: true);
      case ContactVerificationStatus.pending:
        return AppStatusBadge.warning(label: 'PENDING', small: true);
      case ContactVerificationStatus.expired:
        return AppStatusBadge.danger(label: 'EXPIRED', small: true);
      case ContactVerificationStatus.unverified:
        return AppStatusBadge.neutral(label: 'UNVERIFIED', small: true);
    }
  }
}
