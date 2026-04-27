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

enum TransactionStatus {
  pending,
  confirmed,
  disputed,
}

/// Model class for Transaction, maps between DB and Domain
class TransactionModel {
  final String id;
  final String contactId;
  final TransactionType type;
  final TransactionStatus status;
  final Decimal amount;
  final DateTime date;
  final String? description;
  final int? cartons;
  final int? qtyPerCarton;
  final Decimal? unitPrice;
  final Map<String, dynamic>? metadata; // {quantity, unitPrice, batchCount}
  final String? referenceId; // Shared Bill # / Ticket #
  final String? saleId; // Originating sale if auto-generated
  final bool isSynced; // Whether it has been pushed to the cloud
  final bool isDeleted; // Soft-delete flag
  final DateTime? deletedAt; // When it was soft-deleted

  TransactionModel({
    required this.id,
    required this.contactId,
    required this.type,
    this.status = TransactionStatus.pending,
    required this.amount,
    required this.date,
    this.description,
    this.cartons,
    this.qtyPerCarton,
    this.unitPrice,
    this.metadata,
    this.referenceId,
    this.saleId,
    this.isSynced = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  TransactionModel copyWith({
    String? id,
    String? contactId,
    TransactionType? type,
    TransactionStatus? status,
    Decimal? amount,
    DateTime? date,
    String? description,
    int? cartons,
    int? qtyPerCarton,
    Decimal? unitPrice,
    Map<String, dynamic>? metadata,
    String? referenceId,
    String? saleId,
    bool? isSynced,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      cartons: cartons ?? this.cartons,
      qtyPerCarton: qtyPerCarton ?? this.qtyPerCarton,
      unitPrice: unitPrice ?? this.unitPrice,
      metadata: metadata ?? this.metadata,
      referenceId: referenceId ?? this.referenceId,
      saleId: saleId ?? this.saleId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static Decimal? _tryParseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is Decimal) return value;
    final parsed = Decimal.tryParse(value.toString());
    return parsed;
  }

  /// From database row (Drift generated class)
  factory TransactionModel.fromDb(Transaction dbTransaction) {
    return TransactionModel(
      id: dbTransaction.id,
      contactId: dbTransaction.contactId,
      type: TransactionType.values[dbTransaction.type],
      status: TransactionStatus.values[dbTransaction.status],
      amount: Decimal.parse(dbTransaction.amount),
      date: dbTransaction.date,
      description: dbTransaction.description,
        cartons: dbTransaction.cartons ??
          _tryParseInt(dbTransaction.metadata != null
            ? (jsonDecode(dbTransaction.metadata!) as Map<String, dynamic>)['cartons']
            : null),
        qtyPerCarton: dbTransaction.qtyPerCarton ??
          _tryParseInt(dbTransaction.metadata != null
            ? (jsonDecode(dbTransaction.metadata!) as Map<String, dynamic>)['qtyPerCarton']
            : null),
        unitPrice: dbTransaction.unitPrice != null
          ? Decimal.tryParse(dbTransaction.unitPrice!)
          : _tryParseDecimal(dbTransaction.metadata != null
            ? (jsonDecode(dbTransaction.metadata!) as Map<String, dynamic>)['unitPrice']
            : null),
      metadata: dbTransaction.metadata != null
          ? jsonDecode(dbTransaction.metadata!) as Map<String, dynamic>
          : null,
      referenceId: dbTransaction.referenceId,
      saleId: dbTransaction.saleId,
      isSynced: dbTransaction.isSynced,
      isDeleted: dbTransaction.isDeleted,
      deletedAt: dbTransaction.deletedAt,
    );
  }

  /// To database companion for insert
  TransactionsCompanion toDbCompanion() {
    return TransactionsCompanion.insert(
      id: id,
      contactId: contactId,
      type: type.index,
      status: drift.Value(status.index),
      amount: amount.toString(),
      date: date,
      description: drift.Value(description),
      cartons: drift.Value(cartons),
      qtyPerCarton: drift.Value(qtyPerCarton),
      unitPrice: drift.Value(unitPrice?.toString()),
      metadata: drift.Value(metadata != null ? jsonEncode(metadata) : null),
      referenceId: drift.Value(referenceId),
      saleId: drift.Value(saleId),
      isSynced: drift.Value(isSynced),
      isDeleted: drift.Value(isDeleted),
      deletedAt: drift.Value(deletedAt),
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
