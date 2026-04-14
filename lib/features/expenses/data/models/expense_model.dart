import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

class ExpenseModel {
  final String id;
  final String categoryId;
  final String title;
  final String? vendor;
  final Decimal amount;
  final DateTime spentAt;
  final String paymentMethod;
  final String? description;
  final String? receiptPath;
  final bool isRecurring;
  final int? recurrenceDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.vendor,
    required this.amount,
    required this.spentAt,
    required this.paymentMethod,
    this.description,
    this.receiptPath,
    required this.isRecurring,
    this.recurrenceDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromDb(Expense row) {
    return ExpenseModel(
      id: row.id,
      categoryId: row.categoryId,
      title: row.title,
      vendor: row.vendor,
      amount: Decimal.parse(row.amount),
      spentAt: row.spentAt,
      paymentMethod: row.paymentMethod,
      description: row.description,
      receiptPath: row.receiptPath,
      isRecurring: row.isRecurring,
      recurrenceDays: row.recurrenceDays,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ExpensesCompanion toDbCompanion() {
    return ExpensesCompanion.insert(
      id: id,
      categoryId: categoryId,
      title: title,
      vendor: drift.Value(vendor),
      amount: amount.toString(),
      spentAt: spentAt,
      paymentMethod: drift.Value(paymentMethod),
      description: drift.Value(description),
      receiptPath: drift.Value(receiptPath),
      isRecurring: drift.Value(isRecurring),
      recurrenceDays: drift.Value(recurrenceDays),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? vendor,
    Decimal? amount,
    DateTime? spentAt,
    String? paymentMethod,
    String? description,
    String? receiptPath,
    bool? isRecurring,
    int? recurrenceDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      spentAt: spentAt ?? this.spentAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}