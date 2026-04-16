import 'package:drift/drift.dart';

class Promotions extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get discountType => text().withDefault(const Constant('fixed'))();
  TextColumn get discountValue => text()();
  TextColumn get minOrderTotal => text().withDefault(const Constant('0.0'))();
  TextColumn get maxDiscountAmount => text().nullable()();
  DateTimeColumn get startsAt => dateTime().nullable()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get usageLimit => integer().nullable()();
  IntColumn get usedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
