import 'package:drift/drift.dart';

class AuditLogs extends Table {
  TextColumn get id => text()();
  IntColumn get actorRole => integer().withDefault(const Constant(0))();
  TextColumn get action => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}