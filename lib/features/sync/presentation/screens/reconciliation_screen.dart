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
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
class ReconciliationScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger auto-sync for any pending transactions in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsRepositoryProvider).syncAllUnsyncedTransactionsToCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final diffAsync = ref.watch(reconciliationProvider((contactId: widget.contactId, contactPhone: widget.contactPhone)));
    final unsyncedCountAsync = ref.watch(unsyncedTransactionsCountProvider);
    final unsyncedCount = unsyncedCountAsync.value ?? 0;
    
    // Fetch the contact to know if it has a linkedUid even without a phone number
    final contactAsync = ref.watch(contactProvider(widget.contactId));
    final linkedUid = contactAsync.value?.linkedUserUid;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ledger Sync'),
        elevation: 0,
        actions: [
          if (diffAsync.isLoading || diffAsync.isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 6),
                    Text('Syncing...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else if (unsyncedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('$unsyncedCount Pending', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ],
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.positive),
                    SizedBox(width: 4),
                    Text('Synced', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.positive)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
               ref.read(transactionsRepositoryProvider).syncAllUnsyncedTransactionsToCloud();
               ref.refresh(reconciliationProvider((contactId: widget.contactId, contactPhone: widget.contactPhone)));
            },
            tooltip: 'Force Sync',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'resync_all') {
                final snackbar = ScaffoldMessenger.of(context);
                snackbar.showSnackBar(const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('Uploading all transactions to cloud...'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ));
                final count = await ref.read(transactionsRepositoryProvider).syncAllTransactionsToCloud();
                snackbar.hideCurrentSnackBar();
                snackbar.showSnackBar(SnackBar(
                  content: Text('✅ Synced $count transactions to cloud!'),
                  backgroundColor: AppColors.positive,
                ));
                // Refresh the reconciliation view
                ref.invalidate(reconciliationProvider((contactId: widget.contactId, contactPhone: widget.contactPhone)));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'resync_all',
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Re-sync All Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
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

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(transactionsRepositoryProvider).syncAllUnsyncedTransactionsToCloud();
              ref.invalidate(reconciliationProvider((contactId: widget.contactId, contactPhone: widget.contactPhone)));
            },
            child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.8)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF6B4EE6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.contactName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (widget.contactPhone != null || linkedUid != null)
                                      Icon(Icons.cloud_done_rounded, size: 14, color: AppColors.positive.withOpacity(0.8)),
                                    if (widget.contactPhone != null || linkedUid != null)
                                      const SizedBox(width: 4),
                                    Text(
                                      widget.contactPhone != null
                                          ? widget.contactPhone!
                                          : (linkedUid != null ? "Cloud Linked" : "Local Account"),
                                      style: TextStyle(
                                        color: (widget.contactPhone != null || linkedUid != null) ? AppColors.textSecondary : AppColors.warning, 
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: syncPercentage == 100 ? AppColors.positive.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: syncPercentage == 100 ? AppColors.positive.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  syncPercentage == 100 ? Icons.verified_rounded : Icons.info_outline_rounded,
                                  size: 16,
                                  color: syncPercentage == 100 ? AppColors.positive : AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$syncPercentage%',
                                  style: TextStyle(
                                    color: syncPercentage == 100 ? AppColors.positive : AppColors.warning,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _StatPill(label: 'Matched', count: matchCount, color: AppColors.positive, icon: Icons.check_circle_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatPill(label: 'Conflicts', count: conflictCount, color: AppColors.negative, icon: Icons.error_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatPill(label: 'Missing', count: missingCount, color: AppColors.warning, icon: Icons.help_rounded)),
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
                          child: _TimelineItem(diff: sortedDiffs[index], contactId: widget.contactId, contactPhone: widget.contactPhone),
                        );
                      },
                      childCount: sortedDiffs.length,
                    ),
                  ),
                ),
            ],
          ));
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatPill({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
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
    return _buildDiffCard(context, ref);
  }

  Widget _buildDiffCard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine badge color and label
    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeLabel;

    switch (diff.type) {
      case DiffType.match:
        badgeColor = AppColors.positive;
        badgeIcon = Icons.check_circle_rounded;
        badgeLabel = 'MATCHED';
        break;
      case DiffType.conflict:
        badgeColor = AppColors.negative;
        badgeIcon = Icons.warning_rounded;
        badgeLabel = 'CONFLICT';
        break;
      case DiffType.missingRemote:
        badgeColor = AppColors.warning;
        badgeIcon = Icons.cloud_off_rounded;
        badgeLabel = 'MISSING FROM THEM';
        break;
      case DiffType.missingLocal:
        badgeColor = AppColors.warning;
        badgeIcon = Icons.download_rounded;
        badgeLabel = 'MISSING FROM YOU';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Badge Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg - 1)),
            ),
            child: Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 15),
                const SizedBox(width: 6),
                Text(badgeLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8)),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(diff.date),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // ── Side-by-side transaction data ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // My Ledger (left)
                Expanded(
                  child: _SidePanel(
                    label: 'MY LEDGER',
                    tx: diff.local,
                    labelColor: AppColors.primary,
                    isDark: isDark,
                    isConflict: diff.type == DiffType.conflict,
                    otherTx: diff.remote,
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  color: badgeColor.withOpacity(0.2),
                ),
                // Their Ledger (right)
                Expanded(
                  child: _SidePanel(
                    label: 'THEIR LEDGER',
                    tx: diff.remote,
                    labelColor: AppColors.textSecondary,
                    isDark: isDark,
                    isConflict: diff.type == DiffType.conflict,
                    otherTx: diff.local,
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons for missing/conflict ──
          if (diff.type == DiffType.missingLocal || diff.type == DiffType.conflict)
            const Divider(height: 1, color: AppColors.divider),
          if (diff.type == DiffType.missingLocal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _addMissingTransaction(context, ref, diff.remote!),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 16),
                  label: const Text("Sync to My Ledger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  ),
                ),
              ),
            )
          else if (diff.type == DiffType.conflict)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _keepMine(context, ref, diff.local!),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      child: const Text("Keep Mine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptTheirs(context, ref, diff.local!, diff.remote!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                      ),
                      child: const Text("Accept Theirs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
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


class _SidePanel extends StatelessWidget {
  final String label;
  final TransactionModel? tx;
  final Color labelColor;
  final bool isDark;
  final bool isConflict;
  final TransactionModel? otherTx;

  const _SidePanel({
    required this.label,
    required this.tx,
    required this.labelColor,
    required this.isDark,
    required this.isConflict,
    this.otherTx,
  });

  String _typeName(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven: return 'I Gave';
      case TransactionType.goodsTaken: return 'I Took';
      case TransactionType.paymentGiven: return 'Paid';
      case TransactionType.paymentReceived: return 'Received';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tx == null) {
      // Missing side — show placeholder
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: labelColor, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Icon(Icons.do_not_disturb_alt_rounded, color: AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            const Text('Not recorded', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    final amountMismatch = isConflict && otherTx != null && (tx!.amount.toDouble() - otherTx!.amount.toDouble()).abs() >= 0.01;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Text(label, style: TextStyle(fontSize: 10, color: labelColor, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          // Amount — highlight if mismatched
          Container(
            padding: amountMismatch ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : EdgeInsets.zero,
            decoration: amountMismatch
                ? BoxDecoration(color: AppColors.negative.withOpacity(0.1), borderRadius: BorderRadius.circular(6))
                : null,
            child: Text(
              'ETB ${tx!.amount}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: amountMismatch ? AppColors.negative : labelColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            tx!.description ?? 'No description',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _typeName(tx!.type),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor),
            ),
          ),
          // Reference ID if exists
          if (tx!.referenceId != null && tx!.referenceId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Ref: ${tx!.referenceId}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
