import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/sync/domain/entities/transaction_diff.dart';
import 'package:hisabet/features/sync/presentation/providers/sync_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ReconciliationScreen extends ConsumerWidget {
  final String contactId;
  final String contactName;
  final String? contactPhone;

  const ReconciliationScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.contactPhone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffAsync = ref.watch(reconciliationProvider((contactId: contactId, contactPhone: contactPhone)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ledger Sync'),
        elevation: 0,
      ),
      body: diffAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppDimensions.md),
              Text("Analyzing Ledger Synchronization..."),
            ],
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err', textAlign: TextAlign.center)),
        data: (result) {
          final sortedDiffs = List<TransactionDiff>.from(result.diffs)..sort((a, b) => b.date.compareTo(a.date));
          
          final matchCount = sortedDiffs.where((d) => d.type == DiffType.match).length;
          final conflictCount = sortedDiffs.where((d) => d.type == DiffType.conflict).length;
          final missingCount = sortedDiffs.where((d) => d.type != DiffType.match && d.type != DiffType.conflict).length;
          
          final syncPercentage = sortedDiffs.isEmpty ? 100 : ((matchCount / sortedDiffs.length) * 100).round();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadowMedium, blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contactName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  contactPhone ?? "No Linked Account",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: syncPercentage == 100 ? AppColors.positive.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$syncPercentage% Sync',
                              style: TextStyle(
                                color: syncPercentage == 100 ? AppColors.positive : AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      Row(
                        children: [
                          Expanded(child: _StatPill(label: 'Matched', count: matchCount, color: AppColors.positive)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatPill(label: 'Conflicts', count: conflictCount, color: AppColors.negative)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatPill(label: 'Missing', count: missingCount, color: AppColors.warning)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.lg)),
              
              if (sortedDiffs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.xxxl),
                    child: AppEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Perfect Match!',
                      subtitle: 'Your ledger matches their isolated ledger 100%. No discrepancies detected.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                          child: _TimelineItem(diff: sortedDiffs[index], contactId: contactId, contactPhone: contactPhone),
                        );
                      },
                      childCount: sortedDiffs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final TransactionDiff diff;
  final String contactId;
  final String? contactPhone;

  const _TimelineItem({required this.diff, required this.contactId, this.contactPhone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (diff.type == DiffType.match) {
      return _buildMatchItem(context);
    } else if (diff.type == DiffType.conflict) {
      return _buildConflictItem(context, ref);
    } else {
      return _buildMissingItem(context, ref);
    }
  }

  Widget _buildMatchItem(BuildContext context) {
    final amount = diff.local?.amount ?? diff.remote?.amount ?? '0';
    final description = diff.local?.description ?? diff.remote?.description ?? 'No description';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.positive.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.positive.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg - 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.positive, size: 16),
                const SizedBox(width: 6),
                const Text('MATCHED', style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text(DateFormat('MMM dd, yyyy').format(diff.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Text("Ledgers perfectly sync", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('ETB $amount', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictItem(BuildContext context, WidgetRef ref) {
    final local = diff.local!;
    final remote = diff.remote!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.negative),
        boxShadow: [BoxShadow(color: AppColors.negative.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.negative,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg - 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text('DATA CONFLICT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text(DateFormat.yMMMd().format(diff.date), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Expanded(
                  child: _ConflictSidePanel(
                    title: 'YOUR LEDGER',
                    amount: local.amount.toString(),
                    description: local.description,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(width: 1, height: 60, color: AppColors.divider),
                Expanded(
                  child: _ConflictSidePanel(
                    title: 'THEIR LEDGER',
                    amount: remote.amount.toString(),
                    description: remote.description,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _keepMine(context, ref, local),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text("Keep Mine", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptTheirs(context, ref, local, remote),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                    child: const Text("Accept Theirs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem(BuildContext context, WidgetRef ref) {
    final isMissingLocal = diff.type == DiffType.missingLocal;
    final tx = isMissingLocal ? diff.remote! : diff.local!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.warning.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg - 1)),
            ),
            child: Row(
              children: [
                Icon(isMissingLocal ? Icons.download_rounded : Icons.cloud_off_rounded, color: AppColors.warning, size: 16),
                const SizedBox(width: 6),
                Text(isMissingLocal ? 'MISSING FROM YOU' : 'MISSING FROM THEM', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                const Spacer(),
                Text(DateFormat.yMMMd().format(diff.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(tx.description ?? "Unlabeled Transaction", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('ETB ${tx.amount}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                if (isMissingLocal)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _addMissingTransaction(context, ref, tx),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                      label: const Text("Sync to My Ledger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                      ),
                    ),
                  )
                else
                  const Text("Wait for the contact to sync their app, or ask them to add this transaction.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TransactionType _invertType(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven: return TransactionType.goodsTaken;
      case TransactionType.goodsTaken: return TransactionType.goodsGiven;
      case TransactionType.paymentGiven: return TransactionType.paymentReceived;
      case TransactionType.paymentReceived: return TransactionType.paymentGiven;
    }
  }

  Future<void> _addMissingTransaction(BuildContext context, WidgetRef ref, TransactionModel remoteTx) async {
    try {
      final allowed = await _ensureProcessSalesPermission(context, ref, attemptedAction: 'add_missing_transaction', entityId: remoteTx.id);
      if (!allowed) return;

      final repo = ref.read(transactionsRepositoryProvider);
      final invertedType = _invertType(remoteTx.type);
      
      await repo.addTransaction(contactId: contactId, type: invertedType, amount: remoteTx.amount, date: remoteTx.date, description: remoteTx.description, referenceId: remoteTx.id, metadata: remoteTx.metadata);

      if (!context.mounted) return;
      final actorRole = ref.read(currentRoleProvider);
      await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'transaction_created', entityType: 'transaction', entityId: remoteTx.id, message: 'Missing reconciliation transaction synced.');
      ref.invalidate(recentAuditLogsProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction synced successfully", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.positive));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.negative));
    }
  }

  Future<void> _keepMine(BuildContext context, WidgetRef ref, TransactionModel localTx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keep Your Version?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("The conflict will be dismissed locally. The counterpart may still display a disjointed ledger value."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondary, foregroundColor: Colors.white), child: const Text("Acknowledge Target", style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conflict deferred temporarily.")));
    }
  }

  Future<void> _acceptTheirs(BuildContext context, WidgetRef ref, TransactionModel localTx, TransactionModel remoteTx) async {
    final allowed = await _ensureProcessSalesPermission(context, ref, attemptedAction: 'accept_theirs_reconciliation', entityId: localTx.id);
    if (!allowed) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sync Counterpart Target?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("This overwrites local metrics to match external data:\n\n• ETB ${localTx.amount} → ETB ${remoteTx.amount}\n• ${localTx.description ?? 'None'} → ${remoteTx.description ?? 'None'}\n\nOperation irrevocable."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text("Confirm Sync", style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(transactionsRepositoryProvider);
        final updatedTx = localTx.copyWith(amount: remoteTx.amount, description: remoteTx.description, metadata: remoteTx.metadata, referenceId: remoteTx.referenceId ?? localTx.referenceId);
        await repo.updateTransaction(updatedTx);
        final actorRole = ref.read(currentRoleProvider);
        await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'transaction_updated', entityType: 'transaction', entityId: localTx.id, message: 'Local transaction synced to external ledger properties.');
        ref.invalidate(recentAuditLogsProvider);
        ref.invalidate(contactTransactionsProvider(contactId));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Protocol synced.", style: TextStyle(color: Colors.white)), backgroundColor: AppColors.positive));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.negative));
      }
    }
  }

  Future<bool> _ensureProcessSalesPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'transaction', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unauthorized action.'), backgroundColor: AppColors.negative));
    return false;
  }
}

class _ConflictSidePanel extends StatelessWidget {
  final String title;
  final String amount;
  final String? description;
  final Color color;

  const _ConflictSidePanel({required this.title, required this.amount, this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text("ETB $amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
          Text(description ?? "No Desc", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
