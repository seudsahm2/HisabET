import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

class SupplierModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int termsDays;
  final Decimal openingBalance;
  final Decimal currentBalance;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.termsDays = 0,
    required this.openingBalance,
    required this.currentBalance,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromDb(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      name: supplier.name,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      termsDays: supplier.termsDays,
      openingBalance: Decimal.parse(supplier.openingBalance),
      currentBalance: Decimal.parse(supplier.currentBalance),
      notes: supplier.notes,
      isActive: supplier.isActive,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
    );
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? termsDays,
    Decimal? openingBalance,
    Decimal? currentBalance,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      termsDays: termsDays ?? this.termsDays,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  SuppliersCompanion toDbCompanion() {
    return SuppliersCompanion.insert(
      id: id,
      name: name,
      phone: drift.Value(phone),
      email: drift.Value(email),
      address: drift.Value(address),
      termsDays: drift.Value(termsDays),
      openingBalance: drift.Value(openingBalance.toString()),
      currentBalance: drift.Value(currentBalance.toString()),
      notes: drift.Value(notes),
      isActive: drift.Value(isActive),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isPayable => currentBalance < Decimal.zero;
}