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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Reconciling ledger...", style: TextStyle(color: AppColors.positive, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: diffAsync.when(
        data: (result) {
          if (result.diffs.isEmpty) {
            return const Center(child: AppEmptyState(icon: Icons.check_circle_outline_rounded, title: 'Perfect Match!', subtitle: 'Your ledger matches their isolated ledger 100%. No discrepancies detected.'));
          }
          final sortedDiffs = List<TransactionDiff>.from(result.diffs)..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
            itemCount: sortedDiffs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: _TimelineItem(diff: sortedDiffs[index], contactId: contactId, contactPhone: contactPhone),
              );
            },
          );
        },
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
      return _buildMatchItem();
    } else if (diff.type == DiffType.conflict) {
      return _buildConflictItem(context, ref);
    } else {
      return _buildMissingItem(context, ref);
    }
  }

  Widget _buildMatchItem() {
    final amount = diff.local?.amount ?? diff.remote?.amount ?? '0';
    final description = diff.local?.description ?? diff.remote?.description ?? 'No description';
    
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            decoration: BoxDecoration(color: AppColors.positive.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMd))),
            child: Row(
              children: [
                AppStatusBadge.success(label: 'MATCH', small: true),
                const Spacer(),
                Text(DateFormat('MMM dd, yyyy').format(diff.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(color: AppColors.positive.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                  child: const Icon(Icons.handshake_rounded, color: AppColors.positive, size: 24),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Text("Ledgers perfectly sync", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                AppAmountText(amount: amount.toString(), isPositive: true, fontSize: 18),
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

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            decoration: BoxDecoration(color: AppColors.negative.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMd))),
            child: Row(
              children: [
                AppStatusBadge.danger(label: 'DISPUTE DETECTED', small: true),
                const Spacer(),
                Text(DateFormat.yMMMd().format(diff.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("YOU HAVE", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("ETB ${local.amount}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(local.description ?? "No Desc", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("THEY HAVE", style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("ETB ${remote.amount}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(remote.description ?? "No Desc", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _keepMine(context, ref, local),
                  icon: const Icon(Icons.shield_rounded, size: 16),
                  label: const Text("Keep Mine"),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
                TextButton.icon(
                  onPressed: () => _acceptTheirs(context, ref, local, remote),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text("Accept Theirs"),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
    final item = isMissingLocal ? diff.remote! : diff.local!;
    final color = isMissingLocal ? AppColors.primary : AppColors.warning;
    
    final isGiveType = item.type == TransactionType.goodsGiven || item.type == TransactionType.paymentGiven;
    final theirTypeLabel = isGiveType ? "GAVE" : "TOOK";
    final myTypeLabel = isGiveType ? "TOOK" : "GAVE";
    final typeColor = isGiveType ? AppColors.take : AppColors.give;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMd))),
            child: Row(
              children: [
                Icon(isMissingLocal ? Icons.cloud_download_rounded : Icons.cloud_off_rounded, size: 18, color: color),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    isMissingLocal ? "Missing from your ledger" : "Missing from their ledger",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                AppStatusBadge(label: isMissingLocal ? "They $theirTypeLabel" : "You $myTypeLabel", color: typeColor, small: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text("ETB ${item.amount}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: typeColor)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         Text(DateFormat('MMM dd').format(diff.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                         Text(DateFormat('yyyy').format(diff.date), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                if (item.description != null && item.description!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(child: Text(item.description!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), maxLines: 2)),
                      ],
                    ),
                  ),
                if (isMissingLocal) ...[
                  const SizedBox(height: AppDimensions.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _addMissingTransaction(context, ref, item),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: const Text("Sync to My Ledger"),
                      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm))),
                    ),
                  ),
                ],
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
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction synced successfully")));
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
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondary, foregroundColor: Colors.white), child: const Text("Acknowledge Target")),
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
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Protocol synced.")));
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

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unauthorized action.')));
    return false;
  }
}
