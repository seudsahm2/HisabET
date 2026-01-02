import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/sync/domain/entities/transaction_diff.dart';
import 'package:hisabet/features/sync/presentation/providers/sync_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/data/repositories/transactions_repository.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart'; // Added
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
              return _TimelineItem(diff: diff, contactId: contactId);
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

  const _TimelineItem({required this.diff, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (diff.type == DiffType.match) {
      return _buildMatchItem(context);
    } else if (diff.type == DiffType.conflict) {
      return _buildConflictItem(context);
    } else {
      return _buildMissingItem(context, ref);
    }
  }

  // 1. MATCH: Simple central pill
  Widget _buildMatchItem(BuildContext context) {
    final amount = diff.local?.amount ?? diff.remote?.amount ?? '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Match: $amount",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat.MMMd().format(diff.date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. CONFLICT: Red Card
  Widget _buildConflictItem(BuildContext context) {
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
                  onPressed: () {}, // Future: Keep Mine
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text("Keep Mine"),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                TextButton.icon(
                  onPressed: () {}, // Future: Accept Theirs
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

  // 3. MISSING: Bubble on one side
  Widget _buildMissingItem(BuildContext context, WidgetRef ref) {
    final isMissingLocal = diff.type == DiffType.missingLocal;
    final item = isMissingLocal ? diff.remote! : diff.local!;
    final color = isMissingLocal ? Colors.blue : Colors.orange;
    final bg = isMissingLocal ? Colors.white : const Color(0xFFFFF7ED);

    return Align(
      alignment: isMissingLocal ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMissingLocal
                ? Radius.zero
                : const Radius.circular(16),
            bottomRight: isMissingLocal
                ? const Radius.circular(16)
                : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMissingLocal
                            ? Icons.cloud_download_outlined
                            : Icons.cloud_off,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMissingLocal
                            ? "Missing from your ledger"
                            : "Not on their ledger",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM dd').format(diff.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "ETB ${item.amount}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description ?? "No description",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),

              if (isMissingLocal) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addMissingTransaction(context, ref, item),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text("Add to Ledger"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
      ),
    );
  }

  Future<void> _addMissingTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionModel remoteTx,
  ) async {
    try {
      final repo = ref.read(transactionsRepositoryProvider);
      await repo.addTransaction(
        contactId: contactId,
        type: remoteTx.type,
        amount: remoteTx.amount,
        date: remoteTx.date,
        description: remoteTx.description,
        referenceId: remoteTx.referenceId,
        metadata: remoteTx.metadata,
      );

      ref.invalidate(contactTransactionsProvider(contactId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction added to your ledger")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
