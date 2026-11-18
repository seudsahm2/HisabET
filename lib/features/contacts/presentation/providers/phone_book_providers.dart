import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/features/contacts/data/phone_book/phone_book.dart';

final phoneBookSourceProvider = Provider<PhoneBookSource>((ref) => const DevicePhoneBook());

final hisabetDirectoryProvider = Provider<HisabetDirectory>((ref) {
  return FirestoreHisabetDirectory(
    FirebaseFirestore.instance,
    currentUid: FirebaseAuth.instance.currentUser?.uid,
  );
});

/// Result of opening "Import from phone contacts".
sealed class PhoneBookImport {
  const PhoneBookImport();
}

/// The user hasn't allowed contacts access. [permanently] means Android's
/// "Don't ask again": only the system settings can grant it now.
class PhoneBookNeedsAccess extends PhoneBookImport {
  const PhoneBookNeedsAccess({required this.permanently});
  final bool permanently;
}

class PhoneBookLoaded extends PhoneBookImport {
  const PhoneBookLoaded({
    required this.contacts,
    required this.usersByPhone,
    this.directoryUnavailable = false,
  });

  final List<PhoneBookContact> contacts;
  final Map<String, HisabetUser> usersByPhone;

  /// The HisabET lookup failed (usually offline). The phone book still shows,
  /// but nobody can be marked as being on HisabET.
  final bool directoryUnavailable;
}

/// Asks for access, reads the phone book, and checks once which numbers
/// belong to HisabET accounts. "Already saved" is worked out live in the
/// screen from the ledger, so saving someone doesn't re-read everything.
final phoneBookImportProvider = FutureProvider.autoDispose<PhoneBookImport>((ref) async {
  final source = ref.watch(phoneBookSourceProvider);
  final access = await source.requestAccess();
  if (access != PhoneBookAccess.granted) {
    return PhoneBookNeedsAccess(permanently: access == PhoneBookAccess.permanentlyDenied);
  }

  final contacts = await source.load();
  try {
    final users = await ref
        .watch(hisabetDirectoryProvider)
        .findByPhones(contacts.expand((c) => c.phones));
    return PhoneBookLoaded(contacts: contacts, usersByPhone: users);
  } catch (e) {
    debugPrint('[PhoneBook] HisabET lookup failed: $e');
    return PhoneBookLoaded(contacts: contacts, usersByPhone: const {}, directoryUnavailable: true);
  }
});
