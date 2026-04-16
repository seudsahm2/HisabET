import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:hisabet/features/sync/presentation/screens/reconciliation_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ContactDetailScreen extends ConsumerWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(contact.id));
    final transactionsAsync = ref.watch(contactTransactionsProvider(contact.id));

    final currentContact = contactAsync.value ?? contact;
    final isPositive = currentContact.netBalance.toDouble() >= 0;
    final balanceColor = isPositive ? AppColors.give : AppColors.take;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _ContactHeaderTitle(
          contact: currentContact,
          badge: _buildVerificationBadge(currentContact.verificationStatus),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt_rounded),
            onPressed: () => _openReconciliation(context, currentContact),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.negative),
            onPressed: () => _confirmDelete(context, ref, currentContact),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: _HeroActionButton(
                  label: "I GAVE",
                  subLabel: "(Collect)",
                  color: AppColors.give,
                  icon: Icons.arrow_upward_rounded,
                  onTap: () => _addTransaction(context, ref, TransactionType.goodsGiven),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _HeroActionButton(
                  label: "I TOOK",
                  subLabel: "(Pay)",
                  color: AppColors.take,
                  icon: Icons.arrow_downward_rounded,
                  onTap: () => _addTransaction(context, ref, TransactionType.goodsTaken),
                ),
              ),
            ],
          ),
        ),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (transactions) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(contactTransactionsProvider(contact.id));
              ref.invalidate(contactProvider(contact.id));
              ref.invalidate(allContactsProvider);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.lg,
                AppDimensions.pagePaddingH,
                120,
              ),
              children: [
                _BalanceSummaryCard(
                  contact: currentContact,
                  isPositive: isPositive,
                  balanceColor: balanceColor,
                ),
                const SizedBox(height: AppDimensions.xl),
                const AppSectionHeader(title: 'Transaction History', uppercase: true),
                const SizedBox(height: AppDimensions.sm),
                if (transactions.isEmpty)
                  const AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No ledger history',
                    subtitle: 'Transact directly to populate the contact ledger log.',
                  )
                else
                  ...transactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _TransactionTile(transaction: transaction, ref: ref, contact: currentContact),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationBadge(ContactVerificationStatus status) {
    switch (status) {
      case ContactVerificationStatus.verified:
        return AppStatusBadge.success(label: 'Verified', small: true);
      case ContactVerificationStatus.pending:
        return AppStatusBadge.warning(label: 'Pending', small: true);
      case ContactVerificationStatus.expired:
        return AppStatusBadge.danger(label: 'Expired', small: true);
      case ContactVerificationStatus.unverified:
        return AppStatusBadge.neutral(label: 'Unverified', small: true);
    }
  }

  void _openReconciliation(BuildContext context, ContactModel contact) {
    if (contact.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact has no phone number')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReconciliationScreen(contactId: contact.id, contactName: contact.name, contactPhone: contact.phoneNumber!),
      ),
    );
  }

  Future<void> _addTransaction(BuildContext context, WidgetRef ref, TransactionType type) async {
    final allowed = await _ensureTransactionPermission(context, ref, attemptedAction: 'add_transaction', entityType: 'contact', entityId: contact.id);
    if (!allowed) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTransactionScreen(contactId: contact.id, type: type)),
    );
    ref.invalidate(contactTransactionsProvider(contact.id));
    ref.invalidate(contactProvider(contact.id));
    ref.invalidate(allContactsProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ContactModel contact) async {
    final allowed = await _ensureTransactionPermission(context, ref, attemptedAction: 'delete_contact', entityType: 'contact', entityId: contact.id);
    if (!allowed) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text('Are you sure you want to delete "${contact.name}" and ALL their transactions?\n\nThis cannot be undone.', style: const TextStyle(color: AppColors.negative)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(contactsRepositoryProvider);
        await repo.deleteContact(contact.id);
        final actorRole = ref.read(currentRoleProvider);
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'contact_deleted', entityType: 'contact', entityId: contact.id, message: 'Contact ${contact.name} was deleted with all transactions.');
        ref.invalidate(recentAuditLogsProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${contact.name}')));
        }
      } catch (e) {
        // Ignored
      }
    }
  }

  Future<bool> _ensureTransactionPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    required String entityType,
    required String entityId,
  }) async {
    final requiredPermission = attemptedAction == 'delete_contact' ? TeamPermission.manageTeam : TeamPermission.processSales;
    final allowed = ref.read(hasPermissionProvider(requiredPermission));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: entityType,
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission for this action.')));
    }
    return false;
  }
}

class _ContactHeaderTitle extends StatelessWidget {
  final ContactModel contact;
  final Widget badge;

  const _ContactHeaderTitle({required this.contact, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: Text(
            contact.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  badge,
                ],
              ),
              if (contact.phoneNumber != null)
                Text(
                  contact.phoneNumber!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  final ContactModel contact;
  final bool isPositive;
  final Color balanceColor;

  const _BalanceSummaryCard({required this.contact, required this.isPositive, required this.balanceColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      color: balanceColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              isPositive ? "They Owe You" : "You Owe Them",
              style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            'ETB ${contact.netBalance.abs()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
          ),
        ],
      ),
    );
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
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: AppDimensions.sm),
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
                    height: 1.1,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final WidgetRef ref;
  final ContactModel contact;

  const _TransactionTile({required this.transaction, required this.ref, required this.contact});

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven:
        return "Items Given";
      case TransactionType.goodsTaken:
        return "Items Received";
      case TransactionType.paymentReceived:
        return "Payment In";
      case TransactionType.paymentGiven:
        return "Payment Out";
    }
  }

  Widget _buildMappedBadge(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return AppStatusBadge.warning(label: 'Pending', small: true);
      case TransactionStatus.confirmed:
        return AppStatusBadge.success(label: 'Confirmed', small: true);
      case TransactionStatus.disputed:
        return AppStatusBadge.danger(label: 'Disputed', small: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.balanceEffect.toDouble() >= 0;

    return AppListTile(
      leadingIcon: isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      leadingColor: isPositive ? AppColors.give : AppColors.take,
      title: _getTypeLabel(transaction.type),
      subtitle: '${DateFormat('MMM dd • hh:mm a').format(transaction.date)}${transaction.description != null ? '\n${transaction.description}' : ''}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMappedBadge(transaction.status),
              const SizedBox(height: 4),
              AppAmountText(amount: transaction.amount.toString(), fontSize: 16, isPositive: isPositive, showSign: true),
            ],
          ),
          const SizedBox(width: AppDimensions.sm),
          PopupMenuButton<String>(
            tooltip: 'Transaction options',
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionScreen(contactId: contact.id, type: transaction.type, transactionToEdit: transaction)));
              } else if (value == 'delete') {
                final repo = ref.read(transactionsRepositoryProvider);
                await repo.deleteTransaction(transaction.id);
                ref.invalidate(contactTransactionsProvider(contact.id));
                ref.invalidate(contactProvider(contact.id));
                ref.invalidate(allContactsProvider);
              } else if (value == 'pending') {
                final repo = ref.read(transactionsRepositoryProvider);
                await repo.updateTransaction(transaction.copyWith(status: TransactionStatus.pending));
                ref.invalidate(contactTransactionsProvider(contact.id));
              } else if (value == 'confirmed') {
                final repo = ref.read(transactionsRepositoryProvider);
                await repo.updateTransaction(transaction.copyWith(status: TransactionStatus.confirmed));
                ref.invalidate(contactTransactionsProvider(contact.id));
              } else if (value == 'disputed') {
                final repo = ref.read(transactionsRepositoryProvider);
                await repo.updateTransaction(transaction.copyWith(status: TransactionStatus.disputed));
                ref.invalidate(contactTransactionsProvider(contact.id));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
              const PopupMenuItem(value: 'confirmed', child: Text('Mark Confirmed')),
              const PopupMenuItem(value: 'disputed', child: Text('Mark Disputed')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.negative))),
            ],
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
