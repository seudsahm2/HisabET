import 'package:drift/drift.dart';

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get contactId => text().nullable()(); // Optional link to a saved contact
  TextColumn get subtotal => text()();
  TextColumn get discount => text().withDefault(const Constant('0.0'))();
  TextColumn get tax => text().withDefault(const Constant('0.0'))();
  TextColumn get total => text()();
  TextColumn get paidAmount => text().withDefault(const Constant('0.0'))();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
