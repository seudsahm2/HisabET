import 'package:equatable/equatable.dart';

import 'package:hisabet/features/phone_identity/domain/phone_verification_method.dart';

/// A phone number that is proven and uniquely held by the signed-in account.
///
/// A HisabET account is only usable once it has one: the phone number is how
/// trading partners find each other and how two ledgers are matched, so an
/// account without one would break reconciliation for everyone it trades with.
class VerifiedPhone extends Equatable {
  const VerifiedPhone({required this.e164, required this.method});

  final String e164;
  final PhoneVerificationMethod method;

  /// Reads the proven number from a `users/{uid}` document, or null.
  ///
  /// Returns null unless all three agree: a non-empty `phone`,
  /// `phoneVerified == true`, and a server-proven method. Firestore rules make
  /// sure clients cannot write that combination without proof; this check
  /// makes sure older documents written before those rules don't slip through.
  static VerifiedPhone? fromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final phone = profile['phone'];
    if (phone is! String || phone.trim().isEmpty) return null;
    if (profile['phoneVerified'] != true) return null;
    final method =
        PhoneVerificationMethod.tryParse(profile['phoneVerificationMethod']);
    if (method == null || !method.isServerProven) return null;
    return VerifiedPhone(e164: phone.trim(), method: method);
  }

  @override
  List<Object?> get props => [e164, method];
}
