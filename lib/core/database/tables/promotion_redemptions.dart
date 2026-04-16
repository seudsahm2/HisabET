import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/promotions.dart';
import 'package:hisabet/core/database/tables/sales.dart';

class PromotionRedemptions extends Table {
  TextColumn get id => text()();
  TextColumn get promotionId => text().references(Promotions, #id)();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get codeSnapshot => text()();
  TextColumn get discountApplied => text()();
  TextColumn get subtotal => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
