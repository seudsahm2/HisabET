import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:hisabet/core/database/tables/contacts.dart';
import 'package:hisabet/core/database/tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Contacts, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hisabet_v1.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
