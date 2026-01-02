import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

enum DiffType {
  match, // Green: Perfect match
  conflict, // Red: Same transaction but different values
  missingLocal, // Green (+): Only in remote
  missingRemote, // Grey (?): Only in local (they haven't synced)
}

class TransactionDiff {
  final TransactionModel? local;
  final TransactionModel? remote;
  final DiffType type;

  TransactionDiff({this.local, this.remote, required this.type});

  bool get isMatch => type == DiffType.match;

  DateTime get date => local?.date ?? remote!.date;
}

class ReconciliationResult {
  final List<TransactionDiff> diffs;
  final int matchCount;
  final int conflictCount;

  ReconciliationResult(this.diffs)
    : matchCount = diffs.where((d) => d.type == DiffType.match).length,
      conflictCount = diffs.where((d) => d.type == DiffType.conflict).length;
}
