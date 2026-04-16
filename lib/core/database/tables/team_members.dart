import 'package:drift/drift.dart';

class TeamMembers extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get phoneNumber => text().nullable()();
  IntColumn get role => integer().withDefault(const Constant(3))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}