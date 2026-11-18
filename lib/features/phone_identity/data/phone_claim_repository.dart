import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hisabet/features/phone_identity/domain/phone_verification_method.dart';

enum PhoneClaimFailure { notSignedIn, noPhoneOnAccount, inUse, offline, rejected }

class PhoneClaimException implements Exception {
  const PhoneClaimException(this.failure);

  final PhoneClaimFailure failure;

  String get message => switch (failure) {
        PhoneClaimFailure.notSignedIn => 'You are not signed in.',
        PhoneClaimFailure.noPhoneOnAccount =>
          'This account has no verified phone number yet.',
        PhoneClaimFailure.inUse =>
          'That number is already linked to another HisabET account.',
        PhoneClaimFailure.offline =>
          'No connection. Saving your number needs the internet.',
        PhoneClaimFailure.rejected =>
          'The server refused to save this number. Try verifying it again.',
      };

  @override
  String toString() => 'PhoneClaimException(${failure.name})';
}

/// Saves a number that **Firebase Auth** has proven (phone sign-in or an SMS
/// code) as the account's identity, and reserves it so no other account can
/// hold it.
///
/// Telegram-verified numbers do not come through here — the backend writes
/// those. Both paths end in the same place: `users/{uid}.phone` plus a
/// `phone_claims/{phone}` document owned by the user. `firestore.rules`
/// enforces the invariant for this path: the number must equal the
/// `phone_number` on the caller's ID token, and the claim must be written in
/// the same batch.
class PhoneClaimRepository {
  PhoneClaimRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    this.timeout = const Duration(seconds: 15),
  })  : _db = firestore,
        _auth = auth;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Duration timeout;

  /// Claims the phone number on the current Firebase Auth record.
  ///
  /// [method] is [PhoneVerificationMethod.firebaseAuth] for phone sign-in or
  /// [PhoneVerificationMethod.smsCode] for a number linked by code.
  /// Returns the saved E.164 number.
  Future<String> claimFirebaseAuthPhone(PhoneVerificationMethod method) async {
    assert(
      method == PhoneVerificationMethod.firebaseAuth ||
          method == PhoneVerificationMethod.smsCode,
      'Only Firebase-Auth-proven numbers are claimed from the client.',
    );

    final user = _auth.currentUser;
    if (user == null) throw const PhoneClaimException(PhoneClaimFailure.notSignedIn);
    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) {
      throw const PhoneClaimException(PhoneClaimFailure.noPhoneOnAccount);
    }

    try {
      // The rules read `phone_number` from the ID token, which a freshly
      // linked number only appears on after a refresh.
      await user.getIdToken(true).timeout(timeout);

      final claimRef = _db.collection('phone_claims').doc(phone);
      final userRef = _db.collection('users').doc(user.uid);
      const server = GetOptions(source: Source.server);

      // Readable only when free or already ours; any other holder is
      // reported by the rules as permission-denied.
      final claim = await claimRef.get(server).timeout(timeout);
      final profile = await userRef.get(server).timeout(timeout);

      final batch = _db.batch();
      if (!claim.exists) {
        batch.set(claimRef, {
          'uid': user.uid,
          'method': method.storageKey,
          'claimedAt': FieldValue.serverTimestamp(),
        });
      }

      // Changing number: release the old claim if we hold it.
      final previous = profile.data()?['phone'];
      if (previous is String && previous.isNotEmpty && previous != phone) {
        final previousRef = _db.collection('phone_claims').doc(previous);
        try {
          final previousClaim = await previousRef.get(server).timeout(timeout);
          if (previousClaim.exists) batch.delete(previousRef);
        } on FirebaseException catch (e) {
          // Held by someone else (legacy data) — not ours to release.
          if (e.code != 'permission-denied') rethrow;
        }
      }

      batch.set(
        userRef,
        {
          'phone': phone,
          'phoneVerified': true,
          'phoneVerificationMethod': method.storageKey,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
          'contactPhone': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
      await batch.commit().timeout(timeout);
      return phone;
    } on TimeoutException {
      throw const PhoneClaimException(PhoneClaimFailure.offline);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const PhoneClaimException(PhoneClaimFailure.inUse);
      }
      if (e.code == 'unavailable') {
        throw const PhoneClaimException(PhoneClaimFailure.offline);
      }
      throw const PhoneClaimException(PhoneClaimFailure.rejected);
    }
  }
}
