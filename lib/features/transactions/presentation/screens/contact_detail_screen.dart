import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:hisabet/features/sync/presentation/screens/reconciliation_screen.dart';
import 'package:hisabet/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class ContactDetailScreen extends ConsumerWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(contact.id));
    final transactionsAsync = ref.watch(
      contactTransactionsProvider(contact.id),
    );
    final theme = Theme.of(context);

    final currentContact = contactAsync.value ?? contact;
    final isPositive = currentContact.netBalance.toDouble() >= 0;
    final balanceColor = isPositive ? AppColors.give : AppColors.take;

    return Scaffold(
      backgroundColor: Colors.white,
      // FIXED AppBar - does not scroll
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFF5F5F5),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                currentContact.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentContact.name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (currentContact.linkedUserUid != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ],
                  ),
                  if (currentContact.phoneNumber != null)
                    Text(
                      currentContact.phoneNumber!,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.sync_alt, color: Colors.black, size: 18),
            ),
            onPressed: () => _openReconciliation(context, currentContact),
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            ),
            onPressed: () => _confirmDelete(context, ref, currentContact),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Main scrollable content with sticky header
          NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Sticky Balance Card
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyBalanceCardDelegate(
                  contact: currentContact,
                  isPositive: isPositive,
                  balanceColor: balanceColor,
                ),
              ),
              // History Label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    "TRANSACTION HISTORY",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            body: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text("No transactions yet", style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _TransactionTile(transaction: transactions[index]);
                  },
                );
              },
            ),
          ),

          // Floating Action Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: _HeroActionButton(
                    label: "I GAVE",
                    subLabel: "(Collect)",
                    color: AppColors.give,
                    icon: Icons.arrow_upward_rounded,
                    onTap: () => _addTransaction(
                      context,
                      ref,
                      TransactionType.goodsGiven,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HeroActionButton(
                    label: "I TOOK",
                    subLabel: "(Pay)",
                    color: AppColors.take,
                    icon: Icons.arrow_downward_rounded,
                    onTap: () => _addTransaction(
                      context,
                      ref,
                      TransactionType.goodsTaken,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReconciliation(BuildContext context, ContactModel contact) {
    if (contact.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact has no phone number')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReconciliationScreen(
          contactId: contact.id,
          contactName: contact.name,
          contactPhone: contact.phoneNumber!,
        ),
      ),
    );
  }

  Future<void> _addTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionType type,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(contactId: contact.id, type: type),
      ),
    );
    // Force refresh
    ref.invalidate(contactTransactionsProvider(contact.id));
    ref.invalidate(contactProvider(contact.id));
    ref.invalidate(allContactsProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ContactModel contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete "${contact.name}" and ALL their transactions?\n\nThis cannot be undone.',
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(contactsRepositoryProvider);
        await repo.deleteContact(contact.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Deleted ${contact.name}')));
        }
      } catch (e) {
        // Handle error
      }
    }
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.label,
    required this.subLabel,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky Delegate for the Balance Card - Premium Design
class _StickyBalanceCardDelegate extends SliverPersistentHeaderDelegate {
  final ContactModel contact;
  final bool isPositive;
  final Color balanceColor;

  _StickyBalanceCardDelegate({
    required this.contact,
    required this.isPositive,
    required this.balanceColor,
  });

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: balanceColor.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Icon
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Middle: Label
            Expanded(
              child: Text(
                isPositive ? "They Owe You" : "You Owe Them",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Right: Amount
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'ETB ${contact.netBalance.abs()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyBalanceCardDelegate oldDelegate) {
    return oldDelegate.contact.netBalance != contact.netBalance ||
        oldDelegate.balanceColor != balanceColor;
  }
}

class _TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPositive = transaction.balanceEffect.toDouble() >= 0;
    final color = isPositive ? AppColors.give : AppColors.take;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(transaction.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd • hh:mm a').format(transaction.date),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      if (transaction.description != null &&
                          transaction.description!.isNotEmpty)
                        Text(
                          transaction.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isPositive ? '+' : ''}${transaction.amount}",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.grey,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editTransaction(context, ref);
                        } else if (value == 'delete') {
                          _deleteTransaction(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text("Edit"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven:
        return "Gave Goods";
      case TransactionType.goodsTaken:
        return "Took Goods";
      case TransactionType.paymentGiven:
        return "Payment Made";
      case TransactionType.paymentReceived:
        return "Payment Received";
    }
  }

  void _editTransaction(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(
              contactId: transaction.contactId,
              type: transaction.type,
              transactionToEdit: transaction,
            ),
          ),
        )
        .then((_) {
          ref.invalidate(contactTransactionsProvider(transaction.contactId));
          ref.invalidate(contactProvider(transaction.contactId));
          ref.invalidate(allContactsProvider);
        });
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: const Text(
          "This will permanently remove this record from the balance.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(transactionsRepositoryProvider)
          .deleteTransaction(transaction.id);
      ref.invalidate(contactTransactionsProvider(transaction.contactId));
      ref.invalidate(contactProvider(transaction.contactId));
      ref.invalidate(allContactsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Transaction deleted")));
      }
    }
  }
}
