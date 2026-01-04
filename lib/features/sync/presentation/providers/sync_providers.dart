import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/sync/domain/entities/transaction_diff.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

// Define family typedef
typedef ReconciliationParams = ({String contactId, String contactPhone});

final reconciliationProvider =
    StreamProvider.family<ReconciliationResult, ReconciliationParams>((
      ref,
      params,
    ) async* {
      final contactId = params.contactId;
      final contactPhone = params.contactPhone;

      // Fetch Contact to get linkedUid
      final contactsRepo = ref.watch(contactsRepositoryProvider);
      final contact = await contactsRepo.getContactById(contactId);
      final contactUid = contact?.linkedUserUid;

      final myPhone = FirebaseAuth.instance.currentUser?.phoneNumber;

      if (myPhone == null) {
        yield ReconciliationResult([]);
        return;
      }

      final syncService = ref.watch(transactionSyncServiceProvider);
      final remoteStream = syncService.streamRemoteTransactions(
        myPhone: myPhone,
        contactPhone: contactPhone,
        contactUid: contactUid,
      );

      final transactionsRepo = ref.watch(transactionsRepositoryProvider);

      // Yield values from the stream
      await for (final remoteList in remoteStream) {
        final localList = await transactionsRepo.getTransactionsForContact(
          contactId,
        );
        yield _calculateDiff(localList, remoteList);
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
  // Decimal.== can be finicky with different representations (e.g., "100" vs "100.00")
  // Converting to double for comparison is safer for our use case
  bool amountsMatch(Decimal a, Decimal b) {
    // Use double comparison with a tiny epsilon for floating-point safety
    final diff = (a.toDouble() - b.toDouble()).abs();
    return diff < 0.01; // Within 1 cent = match
  }

  // --- Helper: Date Proximity Check ---
  bool datesAreClose(DateTime a, DateTime b, {int maxHours = 72}) {
    final diff = a.difference(b).inHours.abs();
    return diff <= maxHours;
  }

  // --- Helper: Calculate Similarity Score ---
  double calculateScore(TransactionModel l, TransactionModel r) {
    double score = 0;

    // 1. Reference ID (Golden Key) - Guarantees pairing
    final lRef = (l.referenceId ?? '').trim().toLowerCase();
    final rRef = (r.referenceId ?? '').trim().toLowerCase();
    if (lRef.isNotEmpty && rRef.isNotEmpty && lRef == rRef) {
      return 1000.0; // Guaranteed pair identification
    }

    // 2. Date Proximity (7-day window)
    final hoursDiff = l.date.difference(r.date).inHours.abs();
    if (hoursDiff > 168) return -50.0; // > 1 week = unlikely match

    if (hoursDiff <= 24) {
      score += 50 - hoursDiff;
    } else {
      score += 26 - (hoursDiff / 7);
    }

    // 3. Amount Match
    if (amountsMatch(l.amount, r.amount)) {
      score += 60;
    } else {
      final dL = l.amount.toDouble();
      final dR = r.amount.toDouble();
      if (dL > 0 && dR > 0) {
        final ratio = dL > dR ? dL / dR : dR / dL;
        if (ratio < 1.05) score += 40; // Within 5%
        if ((ratio - 10).abs() < 0.01 || (ratio - 0.1).abs() < 0.01) {
          score += 20; // Fat finger (missing zero)
        }
      }
    }

    // 4. Quantity Match (from metadata)
    if (l.metadata != null && r.metadata != null) {
      final qL = l.metadata!['quantity'];
      final qR = r.metadata!['quantity'];
      if (qL != null && qR != null) {
        // Convert both to double to avoid int/double type mismatch
        if ((qL as num).toDouble() == (qR as num).toDouble()) {
          score += 15;
        }
      }
    }

    // 5. Type Match (both scenarios are valid)
    if (r.type == invertType(l.type)) {
      score += 30; // Complementary types (expected in 2-party scenario)
    } else if (r.type == l.type) {
      score += 25; // Same types (both logged from their own view)
    }

    // 6. Description Similarity
    final lDesc = (l.description ?? '').toLowerCase();
    final rDesc = (r.description ?? '').toLowerCase();
    if (lDesc.isNotEmpty && rDesc.isNotEmpty) {
      final lTokens = lDesc.split(RegExp(r'[\s,\.]+'))
          .where((e) => e.length > 2).toSet();
      final rTokens = rDesc.split(RegExp(r'[\s,\.]+'))
          .where((e) => e.length > 2).toSet();

      for (final token in lTokens) {
        if (rTokens.contains(token)) {
          score += token.length * 2;
        }
      }
    }

    return score;
  }

  // --- Main Matching Loop ---
  final remoteMatched = <String>{};

  for (final l in local) {
    double bestScore = -1.0;
    TransactionModel? bestCandidate;

    for (final r in remote) {
      if (remoteMatched.contains(r.id)) continue;
      
      final score = calculateScore(l, r);
      if (score > bestScore) {
        bestScore = score;
        bestCandidate = r;
      }
    }

    // Threshold for considering a pair
    if (bestCandidate != null && bestScore > 10.0) {
      remoteMatched.add(bestCandidate.id);

      // --- Determine Match vs Conflict ---
      // A "Match" means the data is essentially identical
      // A "Conflict" means we identified the same transaction but data differs
      
      final amountOk = amountsMatch(l.amount, bestCandidate.amount);
      final dateOk = datesAreClose(l.date, bestCandidate.date, maxHours: 72);
      final typeOk = (bestCandidate.type == invertType(l.type)) ||
                     (bestCandidate.type == l.type);

      // Perfect match: All core fields agree
      final isPerfect = amountOk && dateOk && typeOk;

      diffs.add(TransactionDiff(
        local: l,
        remote: bestCandidate,
        type: isPerfect ? DiffType.match : DiffType.conflict,
      ));
    } else {
      diffs.add(TransactionDiff(local: l, type: DiffType.missingRemote));
    }
  }

  // Add unmatched remote transactions as "missing local"
  for (final r in remote) {
    if (!remoteMatched.contains(r.id)) {
      diffs.add(TransactionDiff(remote: r, type: DiffType.missingLocal));
    }
  }

  // Sort by date descending
  diffs.sort((a, b) => b.date.compareTo(a.date));

  return ReconciliationResult(diffs);
}

