import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/data/repositories/contacts_repository.dart';

/// `ensureLinkedContact` is what lets a tender win reference the importer by
/// a *local* contact id. These cover the matching paths; creating a brand-new
/// contact goes through `addContact`, which needs Firebase Auth.
void main() {
  late AppDatabase db;
  late ContactsRepositoryImpl repo;
  final now = DateTime(2026, 1, 1);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ContactsRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<void> insert(String id, {String? uid, String? phone, bool deleted = false}) {
    return db.into(db.contacts).insert(ContactsCompanion.insert(
          id: id,
          name: 'Contact $id',
          lastTransactionDate: now,
          linkedUserUid: Value(uid),
          phoneNumber: Value(phone),
          isDeleted: Value(deleted),
        ));
  }

  test('returns the contact already linked to the user', () async {
    await insert('c1', uid: 'importer-uid');
    final id = await repo.ensureLinkedContact(
      linkedUserUid: 'importer-uid',
      name: 'Importer',
    );
    expect(id, 'c1');
  });

  test('links a hand-saved contact with the same number instead of duplicating it', () async {
    await insert('c2', phone: '+251911223344');
    final id = await repo.ensureLinkedContact(
      linkedUserUid: 'importer-uid',
      name: 'Importer',
      phone: '0911223344', // national format, normalised before matching
      isSupplier: true,
    );
    expect(id, 'c2');

    final row = await (db.select(db.contacts)..where((t) => t.id.equals('c2'))).getSingle();
    expect(row.linkedUserUid, 'importer-uid');
    expect(row.isSupplier, isTrue);
    expect(await db.select(db.contacts).get(), hasLength(1));
  });

  test('ignores soft-deleted contacts when matching', () async {
    await insert('gone', uid: 'importer-uid', deleted: true);
    await insert('live', phone: '+251911223344');
    final id = await repo.ensureLinkedContact(
      linkedUserUid: 'importer-uid',
      name: 'Importer',
      phone: '+251911223344',
    );
    expect(id, 'live');
  });
}
