import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/products.dart';
import 'package:hisabet/core/database/tables/sales.dart';

class SaleLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get itemsPerCarton => integer().nullable()();
  TextColumn get unitPrice => text()();
  IntColumn get quantity => integer()();
  TextColumn get lineTotal => text()();

  @override
  Set<Column> get primaryKey => {id};
}
