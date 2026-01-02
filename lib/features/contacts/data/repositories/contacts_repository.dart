import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

abstract class ContactsRepository {
  Future<List<ContactModel>> getAllContacts();
  Future<ContactModel?> getContactById(String id);
  Future<void> addContact(
    String name,
    String? phone,
    String? shop, {
    String? linkedUserUid,
  });
  Future<void> deleteContact(String id);
  Future<void> updateNetBalance(String id, Decimal newBalance);
  Future<Map<String, dynamic>?> searchUserByPhone(String phone);
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
  Future<void> addContact(
    String name,
    String? phone,
    String? shop, {
    String? linkedUserUid,
  }) async {
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
            linkedUserUid: Value(linkedUserUid),
          ),
        );
  }

  @override
  Future<void> deleteContact(String id) async {
    await _db.transaction(() async {
      // 1. Delete all transactions for this contact
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.contactId.equals(id))).go();
      // 2. Delete the contact
      await (_db.delete(_db.contacts)..where((c) => c.id.equals(id))).go();
    });
  }

  @override
  Future<void> updateNetBalance(String id, Decimal newBalance) async {
    await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(id))).write(
      ContactsCompanion(netBalance: Value(newBalance.toString())),
    );
  }

  @override
  Future<Map<String, dynamic>?> searchUserByPhone(String phone) async {
    try {
      final normalizedPhone = PhoneUtil.normalize(phone);
      print('Searching user with phone: $normalizedPhone');

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        data['uid'] = doc.id; // Inject ID into data map
        return data;
      }
      return null;
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }
}
