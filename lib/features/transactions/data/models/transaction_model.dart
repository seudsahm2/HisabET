import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';
import 'dart:convert';

/// Transaction types matching the domain entity
enum TransactionType {
  goodsGiven, // Receivables (They owe me)
  goodsTaken, // Payables (I owe them)
  paymentGiven, // I paid them
  paymentReceived, // They paid me
}

/// Model class for Transaction, maps between DB and Domain
class TransactionModel {
  final String id;
  final String contactId;
  final TransactionType type;
  final Decimal amount;
  final DateTime date;
  final String? description;
  final Map<String, dynamic>? metadata; // {quantity, unitPrice, batchCount}
  final String? referenceId; // Shared Bill # / Ticket #

  TransactionModel({
    required this.id,
    required this.contactId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.metadata,
    this.referenceId,
  });

  TransactionModel copyWith({
    String? id,
    String? contactId,
    TransactionType? type,
    Decimal? amount,
    DateTime? date,
    String? description,
    Map<String, dynamic>? metadata,
    String? referenceId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      referenceId: referenceId ?? this.referenceId,
    );
  }

  /// From database row (Drift generated class)
  factory TransactionModel.fromDb(Transaction dbTransaction) {
    return TransactionModel(
      id: dbTransaction.id,
      contactId: dbTransaction.contactId,
      type: TransactionType.values[dbTransaction.type],
      amount: Decimal.parse(dbTransaction.amount),
      date: dbTransaction.date,
      description: dbTransaction.description,
      metadata: dbTransaction.metadata != null
          ? jsonDecode(dbTransaction.metadata!) as Map<String, dynamic>
          : null,
      referenceId: dbTransaction.referenceId,
    );
  }

  /// To database companion for insert
  TransactionsCompanion toDbCompanion() {
    return TransactionsCompanion.insert(
      id: id,
      contactId: contactId,
      type: type.index,
      amount: amount.toString(),
      date: date,
      description: drift.Value(description),
      metadata: drift.Value(metadata != null ? jsonEncode(metadata) : null),
      referenceId: drift.Value(referenceId),
    );
  }

  /// Calculate the effect on net balance
  /// Positive = they owe me more, Negative = I owe them more
  Decimal get balanceEffect {
    switch (type) {
      case TransactionType.goodsGiven:
        return amount; // They owe me this much
      case TransactionType.goodsTaken:
        return -amount; // I owe them this much
      case TransactionType.paymentReceived:
        return -amount; // They paid me, reducing what they owe
      case TransactionType.paymentGiven:
        return amount; // I paid them, reducing what I owe
    }
  }
}
