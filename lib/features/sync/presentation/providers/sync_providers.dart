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

  // Matching Strategy:
  // 1. Exact Match: Amount + Date (within 1 min) + Type
  // But type is inverted. "I Gave" = "They Received".
  // Local.Type == GoodsGiven (0) <-> Remote.Type == GoodsTaken (1) ?
  // Remote sends "GoodsTaken" meaning "I (Remote User) took goods".
  // So if I Gave Goods, they Took Goods.
  // They store THEIR perspective.
  // So:
  // My 'GoodsGiven' should match Their 'GoodsTaken'.
  // My 'GoodsTaken' should match Their 'GoodsGiven'.
  // My 'PaymentGiven' should match Their 'PaymentReceived'.
  // My 'PaymentReceived' should match Their 'PaymentGiven'.

  // Helper to invert type
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

  final remoteMatched = <String>{};

  // Helper: Calculate Similarity Score (Higher is better)
  double calculateScore(TransactionModel l, TransactionModel r) {
    double score = 0;

    // 1. Reference ID (Highest Priority - The "Golden Key")
    if (l.referenceId != null &&
        r.referenceId != null &&
        l.referenceId!.isNotEmpty &&
        r.referenceId!.isNotEmpty) {
      if (l.referenceId!.trim().toLowerCase() ==
          r.referenceId!.trim().toLowerCase()) {
        return 1000.0; // Guaranteed Match
      }
    }

    // 2. Date Proximity (Expanded Window: 7 Days)
    // Many users log entries days later. We shouldn't punish them too hard.
    final hoursDiff = l.date.difference(r.date).inHours.abs();
    if (hoursDiff > 168) return -50.0; // > 1 week difference = Unlikely match

    // Decay: 0h diff = 50 pts, 24h = 40 pts, 7 days = 10 pts
    if (hoursDiff <= 24) {
      score += 50 - hoursDiff;
    } else {
      score += 26 - (hoursDiff / 7); // Slow decay for older days
    }

    // 3. Amount Match (Smart Price Logic)
    if (l.amount == r.amount) {
      score += 60; // Exact match is strong
    } else {
      final dL = l.amount.toDouble();
      final dR = r.amount.toDouble();

      // A) Small Variance (< 5% difference)
      // e.g. Tax diff or small mistake: 100 vs 105
      if (dL > 0 && dR > 0) {
        final ratio = dL > dR ? dL / dR : dR / dL;
        if (ratio < 1.05) score += 40;
      }

      // B) "Fat Finger" / Missing Zero check (e.g. 500 vs 5000)
      if (dL > 0 && dR > 0) {
        final ratio = dL / dR;
        if ((ratio - 10).abs() < 0.01 || (ratio - 0.1).abs() < 0.001) {
          score += 20; // Likely same transaction, just typo
        }
      }
    }

    // 4. Metadata Match (Quantity check)
    if (l.metadata != null && r.metadata != null) {
      final qL = l.metadata!['quantity'];
      final qR = r.metadata!['quantity'];
      if (qL != null && qR != null && qL == qR) {
        score += 15; // Same quantity is a good hint
      }
    }

    // 5. Type Match
    // Correct Inversion > Same Type > Random Type
    if (r.type == invertType(l.type)) {
      score += 30;
    } else if (r.type == l.type) {
      // Both users clicked "Given" (Conflict state), still implies correlation
      score += 15;
    }

    // 6. Description Similarity (Weighted Token Overlap)
    final lDesc = (l.description ?? '').toLowerCase();
    final rDesc = (r.description ?? '').toLowerCase();
    if (lDesc.isNotEmpty && rDesc.isNotEmpty) {
      // Split by space/punctuation
      final lTokens = lDesc
          .split(RegExp(r'[\s,\.]+'))
          .where((e) => e.length > 2)
          .toSet();
      final rTokens = rDesc
          .split(RegExp(r'[\s,\.]+'))
          .where((e) => e.length > 2)
          .toSet();

      double wordScore = 0;
      for (final token in lTokens) {
        if (rTokens.contains(token)) {
          // Longer words are more unique ("Refrigerator" > "The")
          wordScore += token.length * 2;
        }
      }
      score += wordScore;
    }

    return score;
  }

  for (final l in local) {
    // Score all available remote transactions
    var bestMatch = -1.0;
    TransactionModel? bestCandidate;

    for (final r in remote) {
      if (remoteMatched.contains(r.id)) continue;

      final score = calculateScore(l, r);
      if (score > bestMatch) {
        bestMatch = score;
        bestCandidate = r;
      }
    }

    // Thresholds
    // 1000 = Reference ID Match -> Match/Conflict depending on data
    // > 70 = Strong Match (Amount + Date + Type likely)
    // > 40 = Weak Match (Maybe Amount differs but Date/Desc strong)

    if (bestCandidate != null && bestMatch > 10.0) {
      // Determine if it's a cleaner Match or a Conflict
      final isPerfect =
          bestCandidate.amount == l.amount &&
          bestCandidate.type == invertType(l.type) &&
          l.date.difference(bestCandidate.date).inHours.abs() < 24;

      if (isPerfect) {
        diffs.add(
          TransactionDiff(
            local: l,
            remote: bestCandidate,
            type: DiffType.match,
          ),
        );
      } else {
        // Conflict (Price mismatch, Type mismatch, etc.)
        // But we are CONFIDENT they are the same pair due to Score or RefID
        diffs.add(
          TransactionDiff(
            local: l,
            remote: bestCandidate,
            type: DiffType.conflict,
          ),
        );
      }
      remoteMatched.add(bestCandidate.id);
    } else {
      diffs.add(TransactionDiff(local: l, type: DiffType.missingRemote));
    }
  }

  // Add remaining remote items as MissingLocal
  for (final r in remote) {
    if (!remoteMatched.contains(r.id)) {
      diffs.add(TransactionDiff(remote: r, type: DiffType.missingLocal));
    }
  }

  // Sort by date descending
  diffs.sort((a, b) => b.date.compareTo(a.date));

  return ReconciliationResult(diffs);
}
