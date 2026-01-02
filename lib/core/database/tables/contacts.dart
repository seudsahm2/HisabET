import 'package:drift/drift.dart';

class Contacts extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get shopNumber => text().nullable()();
  // Using RealColumn for balance might have precision issues,
  // but SQLite doesn't have Decimal. We store as String or integer cents.
  // "Zero error" requirement -> Store as String (Text) and parse to Decimal in app.
  TextColumn get netBalance => text().withDefault(const Constant('0.0'))();
  DateTimeColumn get lastTransactionDate => dateTime()();

  /// Stores the Firestore UID if this contact is a real verified user.
  TextColumn get linkedUserUid => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
