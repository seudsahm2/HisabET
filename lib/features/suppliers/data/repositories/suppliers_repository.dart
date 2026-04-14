import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:uuid/uuid.dart';

abstract class SuppliersRepository {
  Future<List<SupplierModel>> getAllSuppliers();
  Future<SupplierModel?> getSupplierById(String id);
  Future<void> addSupplier({
    required String name,
    String? phone,
    String? email,
    String? address,
    int termsDays = 0,
    Decimal? openingBalance,
    Decimal? currentBalance,
    String? notes,
    bool isActive = true,
  });
  Future<void> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
  Future<void> updateSupplierBalance({
    required String supplierId,
    required Decimal balanceDelta,
  });
  Future<void> upsertSupplierProfile({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    int termsDays,
    Decimal openingBalance,
    Decimal currentBalance,
    String? notes,
    bool isActive,
  });
}

class SuppliersRepositoryImpl implements SuppliersRepository {
  final AppDatabase _db;

  SuppliersRepositoryImpl(this._db);

  @override
  Future<List<SupplierModel>> getAllSuppliers() async {
    final rows = await (_db.select(_db.suppliers)
          ..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    return rows.map(SupplierModel.fromDb).toList();
  }

  @override
  Future<SupplierModel?> getSupplierById(String id) async {
    final row = await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : SupplierModel.fromDb(row);
  }

  @override
  Future<void> addSupplier({
    required String name,
    String? phone,
    String? email,
    String? address,
    int termsDays = 0,
    Decimal? openingBalance,
    Decimal? currentBalance,
    String? notes,
    bool isActive = true,
  }) async {
    final openingBalanceValue = openingBalance ?? Decimal.zero;
    final currentBalanceValue = currentBalance ?? Decimal.zero;
    final now = DateTime.now();
    final supplier = SupplierModel(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      email: email,
      address: address,
      termsDays: termsDays,
      openingBalance: openingBalanceValue,
      currentBalance: currentBalanceValue,
      notes: notes,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.suppliers).insert(supplier.toDbCompanion());
  }

  @override
  Future<void> updateSupplier(SupplierModel supplier) async {
    final updated = supplier.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.suppliers)..where((tbl) => tbl.id.equals(supplier.id)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await (_db.delete(_db.suppliers)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updateSupplierBalance({
    required String supplierId,
    required Decimal balanceDelta,
  }) async {
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) return;

    final updated = supplier.copyWith(
      currentBalance: supplier.currentBalance + balanceDelta,
      updatedAt: DateTime.now(),
    );

    await (_db.update(_db.suppliers)..where((tbl) => tbl.id.equals(supplierId)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> upsertSupplierProfile({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    int termsDays = 0,
    Decimal? openingBalance,
    Decimal? currentBalance,
    String? notes,
    bool isActive = true,
  }) async {
    final existing = await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    final now = DateTime.now();
    final openingBalanceValue = openingBalance ?? Decimal.zero;
    final currentBalanceValue = currentBalance ?? Decimal.zero;

    if (existing == null) {
      await _db.into(_db.suppliers).insert(
            SuppliersCompanion.insert(
              id: id,
              name: name,
              phone: Value(phone),
              email: Value(email),
              address: Value(address),
              termsDays: Value(termsDays),
              openingBalance: Value(openingBalanceValue.toString()),
              currentBalance: Value(currentBalanceValue.toString()),
              notes: Value(notes),
              isActive: Value(isActive),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return;
    }

    await (_db.update(_db.suppliers)..where((tbl) => tbl.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(name),
        phone: Value(phone),
        email: Value(email),
        address: Value(address),
        termsDays: Value(termsDays),
        openingBalance: Value(openingBalanceValue.toString()),
        currentBalance: Value(currentBalanceValue.toString()),
        notes: Value(notes),
        isActive: Value(isActive),
        updatedAt: Value(now),
      ),
    );
  }
}