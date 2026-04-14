import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/products.dart';
import 'package:hisabet/core/database/tables/purchase_orders.dart';

class PurchaseOrderLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseOrderId => text().references(PurchaseOrders, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get itemsPerCarton => integer().nullable()();
  TextColumn get unitCost => text()();
  IntColumn get quantity => integer()();
  TextColumn get lineTotal => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}