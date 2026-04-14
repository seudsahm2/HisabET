import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:hisabet/core/database/tables/contacts.dart';
import 'package:hisabet/core/database/tables/products.dart';
import 'package:hisabet/core/database/tables/sale_line_items.dart';
import 'package:hisabet/core/database/tables/sales.dart';
import 'package:hisabet/core/database/tables/stock_movements.dart';
import 'package:hisabet/core/database/tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Contacts,
    Products,
    Sales,
    SaleLineItems,
    StockMovements,
    Transactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(contacts, contacts.linkedUserUid);
        }
        if (from < 3) {
          await m.addColumn(transactions, transactions.referenceId);
        }
        if (from < 4) {
          await m.createTable(products);
        }
        if (from < 5) {
          await m.createTable(stockMovements);
        }
        if (from < 6) {
          await m.createTable(sales);
          await m.createTable(saleLineItems);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hisabet_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
