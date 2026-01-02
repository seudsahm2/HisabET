import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

// --- Models ---

class DashboardStats {
  final Decimal totalReceivable; // Positive balances (Money others owe me)
  final Decimal totalPayable; // Negative balances (Money I owe others)
  final Decimal netBalance; // receivables + payables

  DashboardStats({
    required this.totalReceivable,
    required this.totalPayable,
    required this.netBalance,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalReceivable: Decimal.zero,
      totalPayable: Decimal.zero,
      netBalance: Decimal.zero,
    );
  }
}

// --- Providers ---

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final contacts = await ref.watch(allContactsProvider.future);

  Decimal totalReceivable = Decimal.zero;
  Decimal totalPayable = Decimal.zero;

  for (final contact in contacts) {
    if (contact.netBalance >= Decimal.zero) {
      totalReceivable += contact.netBalance;
    } else {
      totalPayable += contact.netBalance; // This will be negative
    }
  }

  return DashboardStats(
    totalReceivable: totalReceivable,
    totalPayable: totalPayable,
    netBalance: totalReceivable + totalPayable,
  );
});

final recentActivityProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getRecentTransactions(limit: 5);
});
