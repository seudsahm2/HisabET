import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/suppliers.dart';

class PurchaseOrders extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get subtotal => text().withDefault(const Constant('0'))();
  DateTimeColumn get orderDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}