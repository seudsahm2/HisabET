import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart'; // Added
import 'package:flutter/foundation.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/sync/domain/entities/transaction_diff.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

// Define family typedef
typedef ReconciliationParams = ({String contactId, String? contactPhone});

final unsyncedTransactionsCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.transactions)..where((t) => t.isSynced.equals(false)))
      .watch()
      .map((list) => list.length);
});

final reconciliationProvider =
    StreamProvider.family<ReconciliationResult, ReconciliationParams>((
      ref,
      params,
    ) async* {
      final contactId = params.contactId;
      final contactPhone = params.contactPhone;

      debugPrint('🧠 [SYNC PROVIDER] Starting reconciliation for contact: $contactId');
      
      // Fetch Contact to get linkedUid
      final contactsRepo = ref.watch(contactsRepositoryProvider);
      final contact = await contactsRepo.getContactById(contactId);
      final contactUid = contact?.linkedUserUid;
      
      debugPrint('🧠 [SYNC PROVIDER] Contact details - phone: $contactPhone, linkedUid: $contactUid');

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final myPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

      debugPrint('🧠 [SYNC PROVIDER] My details - uid: $myUid, phone: $myPhone');

      if (myUid == null) {
        debugPrint('🛑 [SYNC PROVIDER] FATAL: I am not logged in (myUid is null). Yielding empty.');
        yield ReconciliationResult([]);
        return;
      }

      final syncService = ref.watch(transactionSyncServiceProvider);
      debugPrint('🧠 [SYNC PROVIDER] Requesting remote stream...');
      final remoteStream = syncService.streamRemoteTransactions(
        myUid: myUid,
        myPhone: myPhone,
        contactPhone: contactPhone,
        contactUid: contactUid,
      );

      // Watch local transactions so the reconciliation reacts to local changes!
      debugPrint('🧠 [SYNC PROVIDER] Watching local transactions...');
      final localAsync = ref.watch(contactTransactionsProvider(contactId));
      final localList = localAsync.value ?? [];
      debugPrint('🧠 [SYNC PROVIDER] Local list fetched. Length: ${localList.length}');

      // Yield values from the stream
      try {
        await for (final remoteList in remoteStream) {
          debugPrint('🧠 [SYNC PROVIDER] Received new remote list! Length: ${remoteList.length}. Running _calculateDiff...');
          final result = _calculateDiff(localList, remoteList);
          debugPrint('🧠 [SYNC PROVIDER] Diff complete: ${result.matchCount} matched, ${result.conflictCount} conflicts, ${result.diffs.length} total rows.');
          yield result;
        }
      } catch (e) {
        debugPrint('🛑 [SYNC PROVIDER] FATAL STREAM ERROR: $e');
        yield _calculateDiff(localList, []);
      }
    });

ReconciliationResult _calculateDiff(
  List<TransactionModel> local,
  List<TransactionModel> remote,
) {
  final diffs = <TransactionDiff>[];

  // --- Helper: Invert Type (for complementary transactions) ---
  TransactionType invertType(TransactionType t) {
    switch (t) {
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

  // --- Helper: Robust Amount Comparison ---
  bool amountsMatch(Decimal a, Decimal b) {
    final diff = (a.toDouble() - b.toDouble()).abs();
    return diff < 0.01; // Within 1 cent = match
  }

  // --- Helper: Date Proximity Check ---
  bool datesAreClose(DateTime a, DateTime b, {int maxHours = 48}) {
    final diff = a.difference(b).inHours.abs();
    return diff <= maxHours;
  }

  // --- Helper: Similarity Score ---
  double calculateScore(TransactionModel l, TransactionModel r) {
    double score = 0;

    // Type matching (Must be complementary)
    if (l.type != invertType(r.type)) {
      return 0; // Not a complementary transaction, shouldn't be matched
    }
    
    // SKU Matching (Must not conflict)
    final lRef = (l.referenceId ?? '').trim().toLowerCase();
    final rRef = (r.referenceId ?? '').trim().toLowerCase();
    if (lRef.isNotEmpty && rRef.isNotEmpty && lRef != rRef) {
      return 0; // Explicitly different products, reject match
    }

    score += 50;

    if (lRef.isNotEmpty && lRef == rRef) {
      score += 50; // Huge boost for same product
    }

    // Quantity Match
    if (l.metadata != null && r.metadata != null) {
      final qL = l.metadata!['quantity'];
      final qR = r.metadata!['quantity'];
      if (qL != null && qR != null && (qL as num).toDouble() == (qR as num).toDouble()) {
        score += 30;
      }
    }

    // Unit Price Match
    if (l.unitPrice != null && r.unitPrice != null && amountsMatch(l.unitPrice!, r.unitPrice!)) {
      score += 30;
    }

    // Description Similarity (Jaccard-ish index of tokens > 3 chars)
    final lDesc = (l.description ?? '').toLowerCase();
    final rDesc = (r.description ?? '').toLowerCase();
    if (lDesc.isNotEmpty && rDesc.isNotEmpty) {
      final lTokens = lDesc.split(RegExp(r'[\s,\.]+')).where((e) => e.length > 2).toSet();
      final rTokens = rDesc.split(RegExp(r'[\s,\.]+')).where((e) => e.length > 2).toSet();

      int matchCount = 0;
      for (final token in lTokens) {
        if (rTokens.contains(token)) matchCount++;
      }
      
      if (lTokens.isNotEmpty || rTokens.isNotEmpty) {
        score += (matchCount * 20.0); // Boost for keyword overlaps
      }
    }

    return score;
  }

  final unmatchedRemote = List<TransactionModel>.from(remote);
  final unmatchedLocal = List<TransactionModel>.from(local);

  // === PASS 1: The Golden Key (Reference ID) ===
  for (var i = unmatchedLocal.length - 1; i >= 0; i--) {
    final l = unmatchedLocal[i];
    final lRef = (l.referenceId ?? '').trim().toLowerCase();
    final lId = l.id.toLowerCase();

    if (lRef.isNotEmpty) {
      final matchIdx = unmatchedRemote.indexWhere((r) {
        final rRef = (r.referenceId ?? '').trim().toLowerCase();
        final rId = r.id.toLowerCase();
        
        final isSyncIdMatch = (rRef == lId || lRef == rId) && lRef.isNotEmpty;
        final isManualRefMatch = rRef.isNotEmpty && rRef == lRef;

        // If it's a true Sync ID match (meaning one was synced from the other), it's a guaranteed match.
        // If it's a manual reference match (like a SKU), we ONLY consider it a Golden Key if the amounts ALSO match perfectly.
        if (isManualRefMatch && !isSyncIdMatch) {
           return l.type == invertType(r.type) && amountsMatch(l.amount, r.amount);
        }
        
        return isSyncIdMatch && l.type == invertType(r.type);
      });

      if (matchIdx != -1) {
        final r = unmatchedRemote[matchIdx];
        
        bool hasConflict = false;
        List<String> conflicts = [];
        
        if (!amountsMatch(l.amount, r.amount)) {
          hasConflict = true;
          conflicts.add('Amount mismatch: Your ${l.amount} vs Their ${r.amount}');
        }
        
        diffs.add(TransactionDiff(
          local: l,
          remote: r,
          type: hasConflict ? DiffType.conflict : DiffType.match,
        ));

        unmatchedLocal.removeAt(i);
        unmatchedRemote.removeAt(matchIdx);
      }
    }
  }

  // === PASS 2: The Perfect Doppelgänger (Amount + Time) ===
  for (var i = unmatchedLocal.length - 1; i >= 0; i--) {
    final l = unmatchedLocal[i];
    
    // Find all potential candidates
    final candidates = <int>[];
    for (var j = 0; j < unmatchedRemote.length; j++) {
      final r = unmatchedRemote[j];
      if (l.type == invertType(r.type) && amountsMatch(l.amount, r.amount) && datesAreClose(l.date, r.date, maxHours: 48)) {
        // Prevent matching different SKUs
        final lRef = (l.referenceId ?? '').trim().toLowerCase();
        final rRef = (r.referenceId ?? '').trim().toLowerCase();
        if (lRef.isNotEmpty && rRef.isNotEmpty && lRef != rRef) {
          continue; // Different SKUs, do not match!
        }
        candidates.add(j);
      }
    }

    if (candidates.isNotEmpty) {
      // Pick the closest date
      int bestIdx = candidates.first;
      int minHours = l.date.difference(unmatchedRemote[bestIdx].date).inHours.abs();
      
      for (final idx in candidates) {
        final hours = l.date.difference(unmatchedRemote[idx].date).inHours.abs();
        if (hours < minHours) {
          minHours = hours;
          bestIdx = idx;
        }
      }

      final r = unmatchedRemote[bestIdx];
      diffs.add(TransactionDiff(
        local: l,
        remote: r,
        type: DiffType.match,
      ));

      unmatchedLocal.removeAt(i);
      unmatchedRemote.removeAt(bestIdx);
    }
  }

  // === PASS 3: The Detective (Heuristic Scoring) ===
  for (var i = unmatchedLocal.length - 1; i >= 0; i--) {
    final l = unmatchedLocal[i];
    
    int bestMatchIdx = -1;
    double highestScore = 0;

    for (var j = 0; j < unmatchedRemote.length; j++) {
      final r = unmatchedRemote[j];
      
      if (!datesAreClose(l.date, r.date, maxHours: 72)) continue;

      final score = calculateScore(l, r);
      
      // Threshold for a valid heuristic match (Base 50 + at least Quantity or Description match)
      if (score >= 80 && score > highestScore) { 
        highestScore = score;
        bestMatchIdx = j;
      }
    }

    if (bestMatchIdx != -1) {
      final r = unmatchedRemote[bestMatchIdx];
      
      // By definition in Pass 3, the amounts differ (otherwise Pass 2 would have caught it)
      // So this is a Conflict where we are reasonably sure it's the same transaction
      diffs.add(TransactionDiff(
        local: l,
        remote: r,
        type: DiffType.conflict,
      ));

      unmatchedLocal.removeAt(i);
      unmatchedRemote.removeAt(bestMatchIdx);
    }
  }

  // === PASS 4: The Leftovers (Missing) ===
  for (final l in unmatchedLocal) {
    diffs.add(TransactionDiff(
      local: l,
      remote: null,
      type: DiffType.missingRemote,
    ));
  }

  for (final r in unmatchedRemote) {
    diffs.add(TransactionDiff(
      local: null,
      remote: r,
      type: DiffType.missingLocal,
    ));
  }

  // Sort diffs by date (most recent first)
  diffs.sort((a, b) {
    final dateA = (a.local?.date ?? a.remote?.date)!;
    final dateB = (b.local?.date ?? b.remote?.date)!;
    return dateB.compareTo(dateA);
  });

  return ReconciliationResult(diffs);
}

