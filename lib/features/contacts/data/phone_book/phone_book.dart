import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/core/utils/phone_util.dart';

// ── Models ────────────────────────────────────────────────────────────────────

/// One person from the device phone book, numbers already normalised.
class PhoneBookContact extends Equatable {
  const PhoneBookContact({required this.id, required this.name, required this.phones});

  final String id;
  final String name;

  /// Distinct numbers, normalised with [PhoneUtil.normalize]; first is primary.
  final List<String> phones;

  @override
  List<Object?> get props => [id, name, phones];
}

/// A HisabET account found by its verified phone number.
class HisabetUser extends Equatable {
  const HisabetUser({required this.uid, required this.name, required this.phone, this.roles = const []});

  final String uid;
  final String name;
  final String phone;
  final List<BusinessRole> roles;

  @override
  List<Object?> get props => [uid, name, phone, roles];
}

enum PhoneBookAccess { granted, denied, permanentlyDenied }

// ── Phone book ────────────────────────────────────────────────────────────────

/// The device's contacts. Behind an interface so screens and matching logic
/// are testable without a phone.
abstract class PhoneBookSource {
  Future<PhoneBookAccess> requestAccess();
  Future<List<PhoneBookContact>> load();
  Future<void> openSettings();
}

class DevicePhoneBook implements PhoneBookSource {
  const DevicePhoneBook();

  @override
  Future<PhoneBookAccess> requestAccess() async {
    final status = await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
    return switch (status) {
      fc.PermissionStatus.granted || fc.PermissionStatus.limited => PhoneBookAccess.granted,
      fc.PermissionStatus.permanentlyDenied || fc.PermissionStatus.restricted => PhoneBookAccess.permanentlyDenied,
      _ => PhoneBookAccess.denied,
    };
  }

  @override
  Future<List<PhoneBookContact>> load() async {
    final contacts = await fc.FlutterContacts.getAll(
      properties: {fc.ContactProperty.name, fc.ContactProperty.phone},
    );
    return [
      for (final c in contacts)
        if (toPhoneBookContact(c.id, c.displayName, [for (final p in c.phones) p.normalizedNumber ?? p.number])
            case final contact?)
          contact,
    ];
  }

  @override
  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();

  /// Normalises and de-duplicates numbers; drops entries with no usable one.
  static PhoneBookContact? toPhoneBookContact(String? id, String? name, Iterable<String> rawPhones) {
    final phones = <String>[];
    for (final raw in rawPhones) {
      final normalized = PhoneUtil.normalize(raw.trim());
      if (normalized.replaceAll(RegExp(r'\D'), '').length < 6) continue;
      if (!phones.contains(normalized)) phones.add(normalized);
    }
    if (phones.isEmpty) return null;
    final display = (name ?? '').trim();
    return PhoneBookContact(
      id: id ?? phones.first,
      name: display.isEmpty ? phones.first : display,
      phones: phones,
    );
  }
}

// ── HisabET directory ─────────────────────────────────────────────────────────

/// Which phone numbers belong to HisabET accounts.
abstract class HisabetDirectory {
  /// Map of E.164 number → account, for the numbers that have one.
  Future<Map<String, HisabetUser>> findByPhones(Iterable<String> phones);
}

/// Looks numbers up in `users` by the verified `phone` field — the same field
/// the security rules make unforgeable and unique, so a match really is that
/// person. Numbers are only queried, never stored.
class FirestoreHisabetDirectory implements HisabetDirectory {
  FirestoreHisabetDirectory(this._db, {this.currentUid});

  final FirebaseFirestore _db;
  final String? currentUid;

  /// Firestore's limit for `whereIn`.
  static const chunkSize = 30;

  @override
  Future<Map<String, HisabetUser>> findByPhones(Iterable<String> phones) async {
    final candidates = phones.where(PhoneUtil.isValidE164).toSet().toList();
    final found = <String, HisabetUser>{};
    final queries = [
      for (var i = 0; i < candidates.length; i += chunkSize)
        _db
            .collection('users')
            .where('phone', whereIn: candidates.sublist(i, (i + chunkSize).clamp(0, candidates.length)))
            .get(),
    ];
    for (final snap in await Future.wait(queries)) {
      for (final doc in snap.docs) {
        if (doc.id == currentUid) continue;
        final data = doc.data();
        final phone = data['phone'];
        if (phone is! String || data['phoneVerified'] != true) continue;
        found[phone] = HisabetUser(
          uid: doc.id,
          name: (data['name'] as String?)?.trim().isNotEmpty == true ? data['name'] as String : phone,
          phone: phone,
          roles: BusinessRole.parseAll(data['roles'] as List<dynamic>?),
        );
      }
    }
    return found;
  }
}

// ── Matching ──────────────────────────────────────────────────────────────────

/// One row on the import screen.
class PhoneBookEntry extends Equatable {
  const PhoneBookEntry({required this.contact, required this.phone, this.user, this.alreadySaved = false});

  final PhoneBookContact contact;

  /// The number to save: the one with a HisabET account if any, else primary.
  final String phone;

  /// Set when [phone] belongs to a HisabET account.
  final HisabetUser? user;

  /// Already in the user's own ledger (by linked account or number).
  final bool alreadySaved;

  bool get onHisabet => user != null;

  @override
  List<Object?> get props => [contact, phone, user, alreadySaved];
}

class PhoneBookMatch {
  const PhoneBookMatch({required this.onHisabet, required this.notOnHisabet});

  final List<PhoneBookEntry> onHisabet;
  final List<PhoneBookEntry> notOnHisabet;

  int get total => onHisabet.length + notOnHisabet.length;
}

/// Pure: sorts the phone book into people on HisabET and everyone else.
///
/// - A contact with several numbers is matched on whichever has an account.
/// - The same HisabET account reached from two phone-book entries is listed
///   once, so it can't be saved twice.
/// - [savedUids] / [savedPhones] mark people already in the ledger.
PhoneBookMatch matchPhoneBook({
  required List<PhoneBookContact> contacts,
  required Map<String, HisabetUser> usersByPhone,
  Set<String> savedUids = const {},
  Set<String> savedPhones = const {},
}) {
  final onHisabet = <PhoneBookEntry>[];
  final notOnHisabet = <PhoneBookEntry>[];
  final seenUids = <String>{};
  final seenPhones = <String>{};

  for (final contact in contacts) {
    final matchedPhone = contact.phones.firstWhere(usersByPhone.containsKey, orElse: () => '');
    if (matchedPhone.isNotEmpty) {
      final user = usersByPhone[matchedPhone]!;
      if (!seenUids.add(user.uid)) continue;
      onHisabet.add(PhoneBookEntry(
        contact: contact,
        phone: matchedPhone,
        user: user,
        alreadySaved: savedUids.contains(user.uid) || savedPhones.contains(matchedPhone),
      ));
    } else {
      final phone = contact.phones.first;
      if (!seenPhones.add(phone)) continue;
      notOnHisabet.add(PhoneBookEntry(
        contact: contact,
        phone: phone,
        alreadySaved: contact.phones.any(savedPhones.contains),
      ));
    }
  }

  int byName(PhoneBookEntry a, PhoneBookEntry b) =>
      a.contact.name.toLowerCase().compareTo(b.contact.name.toLowerCase());
  onHisabet.sort(byName);
  notOnHisabet.sort(byName);
  return PhoneBookMatch(onHisabet: onHisabet, notOnHisabet: notOnHisabet);
}
