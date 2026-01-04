import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/sync/domain/entities/transaction_diff.dart';
import 'package:hisabet/features/sync/presentation/providers/sync_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/data/repositories/transactions_repository.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';

class ReconciliationScreen extends ConsumerWidget {
  final String contactId;
  final String contactName;
  final String contactPhone;

  const ReconciliationScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactPhone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffAsync = ref.watch(
      reconciliationProvider((
        contactId: contactId,
        contactPhone: contactPhone,
      )),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Chat background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contactName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Reconciling ledger...",
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.arrow_back, color: Colors.black),
          ), // Consistent with other screens
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: diffAsync.when(
        data: (result) {
          if (result.diffs.isEmpty) {
            return _buildEmptyState();
          }
          // Sort by date descending
          final sortedDiffs = List<TransactionDiff>.from(result.diffs)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: sortedDiffs.length,
            itemBuilder: (context, index) {
              final diff = sortedDiffs[index];
              return _TimelineItem(diff: diff, contactId: contactId, contactPhone: contactPhone);
            },
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 20),
              Text(
                "Analyzing Ledger...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Perfect Match!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your ledger matches theirs 100%.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final TransactionDiff diff;
  final String contactId;
  final String contactPhone;

  const _TimelineItem({required this.diff, required this.contactId, required this.contactPhone});

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

  // 1. MATCH: Green Card with Badge
  Widget _buildMatchItem(BuildContext context) {
    final amount = diff.local?.amount ?? diff.remote?.amount ?? '0';
    final description = diff.local?.description ?? diff.remote?.description ?? 'No description';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with green badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        "MATCH",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(diff.date),
                  style: TextStyle(color: Colors.green.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.handshake_outlined, color: Colors.green.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Both ledgers agree",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  "ETB $amount",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. CONFLICT: Red Card with Action Buttons
  Widget _buildConflictItem(BuildContext context, WidgetRef ref) {
    final local = diff.local!;
    final remote = diff.remote!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Dispute / Conflict",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.yMMMd().format(diff.date),
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // MY SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOU HAVE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${local.amount}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        local.description ?? "No Desc",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                // THEIR SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "THEY HAVE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${remote.amount}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        remote.description ?? "No Desc",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _keepMine(context, ref, local),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text("Keep Mine"),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                TextButton.icon(
                  onPressed: () => _acceptTheirs(context, ref, local, remote),
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text("Accept Theirs"),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. MISSING: Enhanced card with full transaction details
  Widget _buildMissingItem(BuildContext context, WidgetRef ref) {
    final isMissingLocal = diff.type == DiffType.missingLocal;
    final item = isMissingLocal ? diff.remote! : diff.local!;
    final color = isMissingLocal ? Colors.blue : Colors.orange;
    final bg = isMissingLocal ? Colors.white : const Color(0xFFFFF7ED);
    
    // Determine the type label and what it means for MY ledger
    // If remote recorded "give" -> for me it's "take" (they gave TO me)
    final isGiveType = item.type == TransactionType.goodsGiven || 
                       item.type == TransactionType.paymentGiven;
    final theirTypeLabel = isGiveType ? "GAVE" : "TOOK";
    final myTypeLabel = isGiveType ? "TOOK" : "GAVE"; // Inverted for my perspective
    final typeColor = isGiveType ? AppColors.take : AppColors.give; // For MY perspective
    
    // Calculator metadata
    final metadata = item.metadata;
    final hasCalculator = metadata != null && 
        (metadata['cartons'] != null || metadata['quantity'] != null);
    
    String? calculatorText;
    if (hasCalculator && metadata != null) {
      final cartons = metadata['cartons'];
      final qtyPerCarton = metadata['qtyPerCarton'];
      final quantity = metadata['quantity'];
      final unitPrice = metadata['unitPrice'];
      
      if (cartons != null && qtyPerCarton != null) {
        calculatorText = "$cartons × $qtyPerCarton × $unitPrice";
      } else if (quantity != null) {
        calculatorText = "$quantity × $unitPrice";
      }
    }

    return Align(
      alignment: isMissingLocal ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMissingLocal ? Radius.zero : const Radius.circular(16),
            bottomRight: isMissingLocal ? const Radius.circular(16) : Radius.zero,
          ),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(
                    isMissingLocal ? Icons.cloud_download_outlined : Icons.cloud_off,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMissingLocal ? "Missing from your ledger" : "Not on their ledger",
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isMissingLocal ? "They $theirTypeLabel" : "You $myTypeLabel",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ETB ${item.amount}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            if (calculatorText != null)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calculate, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      calculatorText,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM dd').format(diff.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            DateFormat('yyyy').format(diff.date),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Description
                  if (item.description != null && item.description!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notes, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.description!,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Reference Number
                  if (item.referenceId != null && item.referenceId!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          "Ref: ${item.referenceId}",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                  
                  // Add to Ledger Button
                  if (isMissingLocal) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addMissingTransaction(context, ref, item),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text("Add to My Ledger"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to invert transaction type (their "give" = my "take")
  TransactionType _invertType(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven:
        return TransactionType.goodsTaken;
      case TransactionType.goodsTaken:
        return TransactionType.goodsGiven;
      case TransactionType.paymentGiven:
        return TransactionType.paymentReceived;
      case TransactionType.paymentReceived:
        return TransactionType.paymentGiven;
    }
  }

  Future<void> _addMissingTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionModel remoteTx,
  ) async {
    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final invertedType = _invertType(remoteTx.type);
      
      await repo.addTransaction(
        contactId: contactId,
        type: invertedType,
        amount: remoteTx.amount,
        date: remoteTx.date,
        description: remoteTx.description,
        referenceId: remoteTx.id,
        metadata: remoteTx.metadata,
      );

      // CRITICAL: Check if mounted before using ref or context
      if (!context.mounted) return;

      // Invalidate ALL providers to refresh everything
      // Providers are now StreamProviders, so they auto-update!
      // No manual invalidation needed.
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Transaction added to your ledger"),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: "VIEW",
            textColor: Colors.white,
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Keep Mine: User confirms their version is correct.
  /// This does NOT change any data - it simply dismisses the conflict 
  /// from the UI. The idea is: "I'm confident my record is accurate,
  /// and they need to update theirs."
  /// 
  /// In a real P2P scenario, this could notify the other party.
  /// For now, we just show a confirmation message.
  Future<void> _keepMine(
    BuildContext context,
    WidgetRef ref,
    TransactionModel localTx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keep Your Version?"),
        content: const Text(
          "This means you believe YOUR record is correct.\n\n"
          "The conflict will be dismissed, but the other party may still "
          "have a different value on their ledger.\n\n"
          "Consider discussing with them to resolve the difference.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text("Keep Mine", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // For now, just show a message. In future, could mark as "reviewed"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conflict noted. Your record remains unchanged."),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  /// Accept Theirs: Update local transaction to match the remote version.
  /// This modifies the local database to have the same amount/description
  /// as what the other party has recorded.
  Future<void> _acceptTheirs(
    BuildContext context,
    WidgetRef ref,
    TransactionModel localTx,
    TransactionModel remoteTx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Their Version?"),
        content: Text(
          "This will update YOUR record to match theirs:\n\n"
          "• Amount: ETB ${localTx.amount} → ETB ${remoteTx.amount}\n"
          "• Description: ${localTx.description ?? 'None'} → ${remoteTx.description ?? 'None'}\n\n"
          "This change cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Accept Theirs", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(transactionsRepositoryProvider);
        
        // Update local transaction with remote values
        final updatedTx = localTx.copyWith(
          amount: remoteTx.amount,
          description: remoteTx.description,
          metadata: remoteTx.metadata,
          referenceId: remoteTx.referenceId ?? localTx.referenceId,
        );
        
        await repo.updateTransaction(updatedTx);
        ref.invalidate(contactTransactionsProvider(contactId));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Transaction updated to match their version"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
