import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/transactions/presentation/screens/contact_detail_screen.dart';

class ContactsListScreen extends ConsumerStatefulWidget {
  final int initialFilterIndex;

  const ContactsListScreen({
    super.key,
    this.initialFilterIndex = 0,
  });

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  late int _selectedFilterIndex;

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex;
  }

  List<ContactModel> _applyRoleFilter(List<ContactModel> contacts) {
    switch (_selectedFilterIndex) {
      case 1:
        return contacts
            .where(
              (contact) =>
                  contact.role == ContactRole.merchant ||
                  contact.role == ContactRole.both,
            )
            .toList();
      case 2:
        return contacts
            .where(
              (contact) =>
                  contact.role == ContactRole.supplier ||
                  contact.role == ContactRole.both,
            )
            .toList();
      default:
        return contacts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(allContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Sliver App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  String name = 'Merchant';
                  if (snapshot.hasData && snapshot.data?.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    if (data['name'] != null) name = data['name'];
                  }
                  return Text(
                    'Hello, $name',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilterIndex == 0,
                    onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Merchants'),
                    selected: _selectedFilterIndex == 1,
                    onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Suppliers'),
                    selected: _selectedFilterIndex == 2,
                    onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                  ),
                ],
              ),
            ),
          ),

          // 2. Contacts List
          contactsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            data: (contacts) {
              final filteredContacts = _applyRoleFilter(contacts);
              if (filteredContacts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No contacts yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final contact = filteredContacts[index];
                    final balance = contact.netBalance.toDouble();
                    final isPositive = balance >= 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ContactDetailScreen(contact: contact),
                              ),
                            );
                            ref.invalidate(allContactsProvider);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color:
                                        (isPositive
                                                ? AppColors.give
                                                : AppColors.take)
                                            .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    contact.name.isNotEmpty
                                        ? contact.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? AppColors.give
                                          : AppColors.take,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Name & Phone
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              contact.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildVerificationBadge(contact.verificationStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        contact.phoneNumber ?? 'No Phone',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Balance Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isPositive
                                                ? AppColors.give
                                                : AppColors.take)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isPositive ? "Collect" : "Pay",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPositive
                                              ? AppColors.give
                                              : AppColors.take,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        "${contact.netBalance}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isPositive
                                              ? AppColors.give
                                              : AppColors.take,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: filteredContacts.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Contact",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddContactScreen()));
          ref.invalidate(allContactsProvider);
        },
      ),
    );
  }

  Widget _buildVerificationBadge(ContactVerificationStatus status) {
    switch (status) {
      case ContactVerificationStatus.verified:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.give.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.verified, size: 13, color: AppColors.give),
        );
      case ContactVerificationStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.schedule, size: 13, color: Color(0xFFB26A00)),
        );
      case ContactVerificationStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.take.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.cancel_outlined, size: 13, color: AppColors.take),
        );
      case ContactVerificationStatus.unverified:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Unverified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
    }
  }
}
