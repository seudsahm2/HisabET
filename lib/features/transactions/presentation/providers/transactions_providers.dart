import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/data/repositories/transactions_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hisabet/features/sync/data/services/transaction_sync_service.dart';

/// Provider for TransactionSyncService
final transactionSyncServiceProvider = Provider<TransactionSyncService>((ref) {
  return TransactionSyncService(FirebaseFirestore.instance);
});

/// Provider for the TransactionsRepository
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(transactionSyncServiceProvider);
  return TransactionsRepositoryImpl(db, syncService);
});

/// Provider for transactions of a specific contact (family of providers)
final contactTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((
      ref,
      contactId,
    ) async {
      final repo = ref.watch(transactionsRepositoryProvider);
      return repo.getTransactionsForContact(contactId);
    });
