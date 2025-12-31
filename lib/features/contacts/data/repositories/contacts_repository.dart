import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

abstract class ContactsRepository {
  Future<List<ContactModel>> getAllContacts();
  Future<ContactModel?> getContactById(String id);
  Future<void> addContact(String name, String? phone, String? shop);
  Future<void> deleteContact(String id);
  Future<void> updateNetBalance(String id, Decimal newBalance);
}

class ContactsRepositoryImpl implements ContactsRepository {
  final AppDatabase _db;

  ContactsRepositoryImpl(this._db);

  @override
  Future<List<ContactModel>> getAllContacts() async {
    final rows = await _db.select(_db.contacts).get();
    return rows.map((e) => ContactModel.fromDb(e)).toList();
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    final row = await (_db.select(
      _db.contacts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? ContactModel.fromDb(row) : null;
  }

  @override
  Future<void> addContact(String name, String? phone, String? shop) async {
    final id = const Uuid().v4();
    await _db
        .into(_db.contacts)
        .insert(
          ContactsCompanion.insert(
            id: id,
            name: name,
            phoneNumber: Value(phone),
            shopNumber: Value(shop),
            lastTransactionDate: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> deleteContact(String id) async {
    await (_db.delete(_db.contacts)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updateNetBalance(String id, Decimal newBalance) async {
    await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(id))).write(
      ContactsCompanion(netBalance: Value(newBalance.toString())),
    );
  }
}
