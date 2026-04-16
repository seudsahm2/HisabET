import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

abstract class ContactsRepository {
  Future<List<ContactModel>> getAllContacts();
  Future<List<ContactModel>> getCustomerContacts();
  Future<ContactModel?> getContactById(String id);
  Future<String> addContact(
    String name,
    String? phone,
    String? shop, {
    String? linkedUserUid,
    ContactRole role = ContactRole.merchant,
    VerificationTimeoutPolicy verificationTimeoutPolicy =
        VerificationTimeoutPolicy.autoConfirm,
  });
  Future<void> deleteContact(String id);
  Future<void> updateCustomerProfile({
    required String id,
    required String name,
    String? phone,
    String? shop,
    required Decimal creditLimit,
    required int loyaltyPoints,
  });
  Future<void> updateNetBalance(String id, Decimal newBalance);
  Future<Map<String, dynamic>?> searchUserByPhone(String phone);
  Stream<ContactModel?> watchContact(String id);
}

class ContactsRepositoryImpl implements ContactsRepository {
  static const Duration _verificationTimeout = Duration(hours: 48);

  final AppDatabase _db;

  ContactsRepositoryImpl(this._db);

  @override
  Future<List<ContactModel>> getAllContacts() async {
    await _resolvePendingVerificationTimeouts();
    final rows = await _db.select(_db.contacts).get();
    return rows.map((e) => ContactModel.fromDb(e)).toList();
  }

  @override
  Future<List<ContactModel>> getCustomerContacts() async {
    await _resolvePendingVerificationTimeouts();
    final rows =
        await (_db.select(_db.contacts)
              ..where(
                (tbl) =>
                    tbl.role.equals(ContactRole.merchant.index) |
                    tbl.role.equals(ContactRole.both.index),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();
    return rows.map(ContactModel.fromDb).toList();
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    var row = await (_db.select(
      _db.contacts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row != null) {
      row = await _resolveVerificationTimeoutIfNeeded(row);
    }
    return row != null ? ContactModel.fromDb(row) : null;
  }

  @override
  Future<String> addContact(
    String name,
    String? phone,
    String? shop, {
    String? linkedUserUid,
    ContactRole role = ContactRole.merchant,
    VerificationTimeoutPolicy verificationTimeoutPolicy =
        VerificationTimeoutPolicy.autoConfirm,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final hasLinkedUser =
        linkedUserUid != null && linkedUserUid.trim().isNotEmpty;
    final verificationStatus = hasLinkedUser
        ? ContactVerificationStatus.pending
        : ContactVerificationStatus.unverified;
    final verificationDeadlineAt = hasLinkedUser
        ? now.add(_verificationTimeout)
        : null;

    await _db
        .into(_db.contacts)
        .insert(
          ContactsCompanion.insert(
            id: id,
            name: name,
            role: Value(role.index),
            verificationStatus: Value(verificationStatus.index),
            verificationRequestedAt: Value(hasLinkedUser ? now : null),
            verificationDeadlineAt: Value(verificationDeadlineAt),
            verificationTimeoutPolicy: Value(verificationTimeoutPolicy.index),
            phoneNumber: Value(phone),
            shopNumber: Value(shop),
            lastTransactionDate: now,
            linkedUserUid: Value(linkedUserUid),
          ),
        );
    return id;
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
  Future<void> updateCustomerProfile({
    required String id,
    required String name,
    String? phone,
    String? shop,
    required Decimal creditLimit,
    required int loyaltyPoints,
  }) async {
    await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(id))).write(
      ContactsCompanion(
        name: Value(name),
        phoneNumber: Value(phone),
        shopNumber: Value(shop),
        creditLimit: Value(creditLimit.toString()),
        loyaltyPoints: Value(loyaltyPoints),
      ),
    );
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
      debugPrint('Searching user with phone: $normalizedPhone');

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
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  @override
  Stream<ContactModel?> watchContact(String id) {
    return (_db.select(_db.contacts)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((row) async {
          if (row == null) return null;
          final resolved = await _resolveVerificationTimeoutIfNeeded(row);
          return ContactModel.fromDb(resolved);
        });
  }

  Future<void> _resolvePendingVerificationTimeouts() async {
    final now = DateTime.now();
    final pendingRows =
        await (_db.select(_db.contacts)..where(
              (tbl) => tbl.verificationStatus.equals(
                ContactVerificationStatus.pending.index,
              ),
            ))
            .get();

    for (final row in pendingRows) {
      if (row.verificationDeadlineAt == null) continue;
      if (now.isBefore(row.verificationDeadlineAt!)) continue;
      await _resolveVerificationTimeoutIfNeeded(row);
    }
  }

  Future<Contact> _resolveVerificationTimeoutIfNeeded(Contact row) async {
    if (row.verificationStatus != ContactVerificationStatus.pending.index) {
      return row;
    }
    final deadline = row.verificationDeadlineAt;
    if (deadline == null || DateTime.now().isBefore(deadline)) {
      return row;
    }

    final nextStatus =
        row.verificationTimeoutPolicy ==
            VerificationTimeoutPolicy.autoExpire.index
        ? ContactVerificationStatus.expired
        : ContactVerificationStatus.verified;

    await (_db.update(_db.contacts)..where((tbl) => tbl.id.equals(row.id)))
        .write(ContactsCompanion(verificationStatus: Value(nextStatus.index)));

    final updated = await (_db.select(
      _db.contacts,
    )..where((tbl) => tbl.id.equals(row.id))).getSingleOrNull();
    return updated ?? row;
  }
}
