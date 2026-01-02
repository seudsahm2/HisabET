import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/contacts.dart';

class Transactions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get contactId => text().references(Contacts, #id)();

  // Enum stored as int index or string. Int is faster.
  IntColumn get type => integer()();

  // Store amount as Text for Decimal precision
  TextColumn get amount => text()();

  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();

  // JSON string for metadata {quantity, unitPrice}
  TextColumn get metadata => text().nullable()();

  // Shared Reference ID (e.g. Bill #, Ticket #) for smart matching
  TextColumn get referenceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
