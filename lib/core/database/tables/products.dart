import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get itemsPerCarton => integer().nullable()();
  TextColumn get itemNumber => text().nullable()();
  IntColumn get sizeFrom => integer().nullable()();
  IntColumn get sizeTo => integer().nullable()();
  IntColumn get seriesSize => integer().withDefault(const Constant(6))();
  TextColumn get colorDistribution => text().nullable()();
  TextColumn get containerRef => text().nullable()();
  TextColumn get supplierContactId => text().nullable()();
  TextColumn get businessRole => text().withDefault(const Constant('retailer'))();
  TextColumn get costPrice => text().withDefault(const Constant('0.0'))();
  TextColumn get sellingPrice => text().withDefault(const Constant('0.0'))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get reorderLevel => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Soft-delete tracking
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
