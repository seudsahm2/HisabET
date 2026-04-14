import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

class ExpenseCategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseCategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseCategoryModel.fromDb(ExpenseCategory row) {
    return ExpenseCategoryModel(
      id: row.id,
      name: row.name,
      colorHex: row.colorHex,
      notes: row.notes,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ExpenseCategoriesCompanion toDbCompanion() {
    return ExpenseCategoriesCompanion.insert(
      id: id,
      name: name,
      colorHex: drift.Value(colorHex),
      notes: drift.Value(notes),
      isActive: drift.Value(isActive),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ExpenseCategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}