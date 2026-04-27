import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    String? verificationMethod, // 'phone' or 'email'
    bool isRetailer = false,
    bool isWholesaler = false,
    bool isBroker = false,
    bool isSupplier = false,
    bool sendConnectionNotification = true, // Set false when accepting to prevent cycle
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
  Future<Map<String, dynamic>?> searchUserByEmail(String email);
  Future<List<Map<String, dynamic>>> searchNetwork(String query);
  Stream<ContactModel?> watchContact(String id);

  // Soft-delete extensions
  Future<List<ContactModel>> getDeletedContacts();
  Future<void> restoreContact(String id);
  Future<void> permanentlyDeleteExpiredContacts({int days = 30});
}

class ContactsRepositoryImpl implements ContactsRepository {
  final AppDatabase _db;

  ContactsRepositoryImpl(this._db);

  @override
  Future<List<ContactModel>> getAllContacts() async {
    final rows = await (_db.select(_db.contacts)
          ..where((tbl) => tbl.isDeleted.equals(false)))
        .get();
    return rows.map((e) => ContactModel.fromDb(e)).toList();
  }

  @override
  Future<List<ContactModel>> getCustomerContacts() async {
    final rows =
      await (_db.select(_db.contacts)
            ..where(
              (tbl) =>
                  tbl.isDeleted.equals(false) &
                  (tbl.isRetailer.equals(true) |
                  tbl.isWholesaler.equals(true) |
                  tbl.isBroker.equals(true) |
                  tbl.role.equals(ContactRole.both.index) |
                  tbl.role.equals(ContactRole.merchant.index)),
            ))
          .get();
    return rows.map(ContactModel.fromDb).toList();
  }

  @override
  Future<ContactModel?> getContactById(String id) async {
    var row = await (_db.select(
      _db.contacts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? ContactModel.fromDb(row) : null;
  }

  @override
  Future<String> addContact(
    String name,
    String? phone,
    String? shop, {
    String? linkedUserUid,
    ContactRole role = ContactRole.merchant,
    String? verificationMethod,
    bool isRetailer = false,
    bool isWholesaler = false,
    bool isBroker = false,
    bool isSupplier = false,
    bool sendConnectionNotification = true,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final hasLinkedUser =
        linkedUserUid != null && linkedUserUid.trim().isNotEmpty;
    final verificationStatus = hasLinkedUser
        ? ContactVerificationStatus.verified
        : ContactVerificationStatus.unverified;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (linkedUserUid != null && linkedUserUid == currentUid) {
      throw Exception("You cannot add yourself as a contact.");
    }

    if (linkedUserUid != null && linkedUserUid.trim().isNotEmpty) {
      final existingLinked = await (_db.select(_db.contacts)..where((t) => t.linkedUserUid.equals(linkedUserUid))).get();
      if (existingLinked.isNotEmpty) {
        throw Exception("Contact already exists in your directory!");
      }
    }

    if (phone != null && phone.trim().isNotEmpty) {
      final existingPhone = await (_db.select(_db.contacts)..where((t) => t.phoneNumber.equals(phone))).get();
      if (existingPhone.isNotEmpty) {
        throw Exception("Contact with this phone number already exists!");
      }
    }

    await _db
        .into(_db.contacts)
        .insert(
          ContactsCompanion.insert(
            id: id,
            name: name,
            role: Value(role.index),
            verificationStatus: Value(verificationStatus.index),
            verificationRequestedAt: Value(hasLinkedUser ? now : null),
            verificationDeadlineAt: const Value(null),
            verificationTimeoutPolicy: const Value(0),
            phoneNumber: Value(phone),
            shopNumber: Value(shop),
            lastTransactionDate: now,
            linkedUserUid: Value(linkedUserUid),
            verificationMethod: Value(hasLinkedUser ? verificationMethod : null),
            isRetailer: Value(isRetailer),
            isWholesaler: Value(isWholesaler),
            isBroker: Value(isBroker),
            isSupplier: Value(isSupplier),
          ),
        );

    // ── Cloud sync (fire-and-forget; offline-safe via Firestore cache) ──────
    if (hasLinkedUser && currentUid != null && sendConnectionNotification) {
      _syncContactToCloud(
        currentUid: currentUid,
        linkedUserUid: linkedUserUid,
      );
    } else if (hasLinkedUser && currentUid != null) {
      // Even when not sending a notification (accept flow), still record the
      // new contact in our own contacts_uids array for future graph features.
      _updateMyContactsUids(currentUid: currentUid, linkedUserUid: linkedUserUid);
    }

    return id;
  }

  /// Atomically adds [linkedUserUid] to the current user's `contacts_uids`
  /// array in Firestore (idempotent, offline-queued by Firestore SDK).
  void _updateMyContactsUids({
    required String currentUid,
    required String linkedUserUid,
  }) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .update({'contacts_uids': FieldValue.arrayUnion([linkedUserUid])})
        .catchError((e) => debugPrint('[ContactsRepo] contacts_uids update failed (will retry): $e'));
  }

  /// Handles the full cloud sync for a new verified contact:
  /// 1. Records the contact in MY `contacts_uids` array (graph data).
  /// 2. Checks if THEY already have ME in their `contacts_uids`.
  ///    - YES → they already know about me; no notification needed; mark any
  ///      pending request as accepted.
  ///    - NO  → send a fresh connection-request notification.
  Future<void> _syncContactToCloud({
    required String currentUid,
    required String linkedUserUid,
  }) async {
    try {
      // Step 1 – Update MY contacts_uids (atomic, idempotent).
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({'contacts_uids': FieldValue.arrayUnion([linkedUserUid])});

      // Step 2 – Check if I am already in THEIR contacts list.
      //          Single-document read → no composite index required.
      final theirDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(linkedUserUid)
          .get();

      final theirContactUids = List<String>.from(
        (theirDoc.data()?['contacts_uids'] as List<dynamic>?) ?? [],
      );
      final theyAlreadyHaveMe = theirContactUids.contains(currentUid);

      if (theyAlreadyHaveMe) {
        // ── Anti-cycle path ──────────────────────────────────────────────
        // They already saved me; mark any pending request as accepted
        // silently so their inbox clears up without a new ping to me.
        debugPrint('[ContactsRepo] 🛡️ Cycle prevented: $linkedUserUid already has me. Marking pending request accepted.');
        final pendingQuery = await FirebaseFirestore.instance
            .collection('connection_requests')
            .where('fromUid', isEqualTo: linkedUserUid)
            .where('toUid', isEqualTo: currentUid)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        for (final doc in pendingQuery.docs) {
          await doc.reference.update({'status': 'accepted'});
        }
      } else {
        // ── Normal path ──────────────────────────────────────────────────
        // They don't have me yet → send them a connection request.
        final myDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();

        if (myDoc.exists) {
          final me = myDoc.data()!;
          await FirebaseFirestore.instance.collection('connection_requests').add({
            'fromUid': currentUid,
            'toUid': linkedUserUid,
            'fromName': me['name'] ?? 'A HisabET User',
            'fromPhone': me['phone'],
            'fromEmail': me['email'],
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint('[ContactsRepo] ✅ Connection request sent to $linkedUserUid.');
        }
      }
    } catch (e) {
      debugPrint('[ContactsRepo] Cloud sync failed (will retry when online): $e');
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    // Soft delete
    await (_db.update(_db.contacts)..where((c) => c.id.equals(id))).write(
      ContactsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<ContactModel>> getDeletedContacts() async {
    final rows = await (_db.select(_db.contacts)
          ..where((tbl) => tbl.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
    return rows.map((e) => ContactModel.fromDb(e)).toList();
  }

  @override
  Future<void> restoreContact(String id) async {
    await (_db.update(_db.contacts)..where((c) => c.id.equals(id))).write(
      const ContactsCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteExpiredContacts({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final expiredContacts = await (_db.select(_db.contacts)
          ..where((tbl) =>
              tbl.isDeleted.equals(true) &
              tbl.deletedAt.isSmallerThanValue(cutoff)))
        .get();

    await _db.transaction(() async {
      for (final contact in expiredContacts) {
        await (_db.delete(_db.transactions)
              ..where((t) => t.contactId.equals(contact.id)))
            .go();
        await (_db.delete(_db.contacts)..where((c) => c.id.equals(contact.id))).go();
      }
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
      debugPrint('[ContactsRepo] Searching user by phone: $normalizedPhone');

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('[ContactsRepo] Error searching user by phone: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('[ContactsRepo] Searching user by email: $normalizedEmail');

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('[ContactsRepo] Error searching user by email: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchNetwork(String queryText) async {
    try {
      final normalized = queryText.trim();
      if (normalized.isEmpty) return [];

      debugPrint('[ContactsRepo] Searching network for: $normalized');

      final usersCollection = FirebaseFirestore.instance.collection('users');
      List<Map<String, dynamic>> results = [];

      // If it looks like an email, search by email
      if (normalized.contains('@')) {
        final emailQuery = await usersCollection
            .where('email', isEqualTo: normalized.toLowerCase())
            .limit(10)
            .get();
        results.addAll(emailQuery.docs.map((d) => d.data()..['uid'] = d.id));
      } 
      // If it looks like a phone number (starts with + or is numeric)
      else if (normalized.startsWith('+') || int.tryParse(normalized.replaceAll(RegExp(r'\s'), '')) != null) {
        final phoneQuery = await usersCollection
            .where('phone', isEqualTo: PhoneUtil.normalize(normalized))
            .limit(10)
            .get();
        results.addAll(phoneQuery.docs.map((d) => d.data()..['uid'] = d.id));
      } 
      // Otherwise search by name prefix
      else {
        final nameQuery = await usersCollection
            .where('name', isGreaterThanOrEqualTo: normalized)
            .where('name', isLessThan: '$normalized\uf8ff')
            .limit(20)
            .get();
        results.addAll(nameQuery.docs.map((d) => d.data()..['uid'] = d.id));
      }

      // Deduplicate by UID
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (final r in results) {
        uniqueResults[r['uid'] as String] = r;
      }
      
      return uniqueResults.values.toList();
    } catch (e) {
      debugPrint('[ContactsRepo] Error searching network: $e');
      return [];
    }
  }

  @override
  Stream<ContactModel?> watchContact(String id) {
    return (_db.select(_db.contacts)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) {
          if (row == null) return null;
          return ContactModel.fromDb(row);
        });
  }


}
