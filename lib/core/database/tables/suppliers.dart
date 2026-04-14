import 'package:drift/drift.dart';

class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get termsDays => integer().withDefault(const Constant(0))();
  TextColumn get openingBalance => text().withDefault(const Constant('0'))();
  TextColumn get currentBalance => text().withDefault(const Constant('0'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}