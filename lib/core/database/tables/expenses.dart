import 'package:drift/drift.dart';
import 'package:hisabet/core/database/tables/expense_categories.dart';

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  TextColumn get title => text()();
  TextColumn get vendor => text().nullable()();
  TextColumn get amount => text()();
  DateTimeColumn get spentAt => dateTime()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get description => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get recurrenceDays => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}