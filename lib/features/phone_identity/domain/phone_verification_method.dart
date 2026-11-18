/// How a user's phone number was proven.
///
/// Stored as [storageKey] in `users/{uid}.phoneVerificationMethod` and
/// `phone_claims/{phone}.method`. The keys are also checked by
/// `firestore.rules` and written by the backend in `functions/`, so they are
/// part of a contract — never rename one.
enum PhoneVerificationMethod {
  /// The user signed in with their phone number (Firebase Auth).
  firebaseAuth('auth', 'Phone sign-in'),

  /// A Firebase SMS code linked the number to the account.
  smsCode('otp', 'SMS code'),

  /// The user shared their own number from Telegram to the HisabET bot.
  telegram('telegram', 'Telegram'),

  /// Firebase PNV (carrier check). The result is relayed by the client and is
  /// not proof until a backend verifies the attestation token, so it can never
  /// satisfy [isServerProven].
  carrier('pnv', 'Mobile network');

  const PhoneVerificationMethod(this.storageKey, this.label);

  final String storageKey;
  final String label;

  /// True when a server — Firebase Auth or the HisabET backend — vouches for
  /// the number, rather than the app on the user's phone.
  bool get isServerProven => this != carrier;

  static PhoneVerificationMethod? tryParse(Object? raw) {
    if (raw is! String) return null;
    for (final method in values) {
      if (method.storageKey == raw) return method;
    }
    return null;
  }
}
