import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Why phone verification is or isn't usable right now.
///
/// The welcome screen renders from this instead of guessing, so the phone
/// option is never a dead button.
enum OtpAvailability {
  /// A real provider is configured; codes are really delivered.
  live,

  /// Firebase fictional test numbers. No SMS is dispatched and no billing is
  /// involved, so this works on the free Spark plan. Console-configured
  /// numbers only.
  testNumbers,

  /// No provider configured. Phone sign-in must be hidden or disabled.
  unavailable,
}

/// What a silent (no-SMS) verification should do when it resolves.
///
/// Android can verify the device's own number over the network via Google Play
/// services, without ever sending an SMS. When that happens Firebase hands back
/// a finished credential, and the *caller* decides what it means:
///
/// - [signIn] — the welcome screen: this credential is the account.
/// - [link] — profile setup: the user is already signed in with Google and is
///   only attaching a number. Signing in here would silently swap the session
///   to a different account halfway through onboarding.
enum OtpAutoResolveMode { signIn, link }

/// Outcome of starting a verification.
sealed class OtpStartOutcome {
  const OtpStartOutcome();
}

/// A code was dispatched; the user must now type it.
class OtpCodeSent extends OtpStartOutcome {
  const OtpCodeSent({required this.sessionId, this.resendToken});

  final String sessionId;
  final int? resendToken;
}

/// Verification completed without the user typing anything — either Play
/// services verified the number over the network with no SMS at all, or the
/// SMS arrived and was auto-read. The requested [OtpAutoResolveMode] has
/// already been carried out.
class OtpAutoResolved extends OtpStartOutcome {
  const OtpAutoResolved(this.credential);

  final UserCredential? credential;
}

/// A verification failure with a message already phrased for end users.
class OtpException implements Exception {
  const OtpException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'OtpException($code): $message';
}

/// Phone verification, abstracted away from any one provider.
///
/// Swapping to Telegram Gateway or a local Ethiopian SMS aggregator
/// (AfroMessage / GeezSMS / SMSEthiopia) means writing one new implementation
/// of this interface and changing the provider wiring — no screen changes.
/// Those providers would deliver the code themselves and then mint a Firebase
/// **custom token** for sign-in, which is why [verifyAndSignIn] returns a
/// [UserCredential] rather than exposing anything Firebase-phone-specific.
abstract class OtpService {
  OtpAvailability get availability;

  /// Short label describing the delivery channel, shown in the UI.
  String get channelLabel;

  bool get isUsable => availability != OtpAvailability.unavailable;

  /// Starts verification for [phoneE164] (must already be normalised).
  ///
  /// Resolves with [OtpCodeSent] when the user must type a code, or with
  /// [OtpAutoResolved] when the platform verified the number by itself.
  Future<OtpStartOutcome> start(
    String phoneE164, {
    int? resendToken,
    OtpAutoResolveMode mode = OtpAutoResolveMode.signIn,
  });

  /// Verifies [code] against [sessionId] and signs the user in.
  Future<UserCredential> verifyAndSignIn({
    required String sessionId,
    required String code,
  });

  /// Verifies [code] and attaches the phone number to the *already signed-in*
  /// account, instead of creating a new one. Used when a Google user adds a
  /// phone number during profile setup.
  Future<void> verifyAndLinkToCurrentUser({
    required String sessionId,
    required String code,
  });
}

/// Firebase-backed implementation.
///
/// Availability is driven by compile-time flags so the UI can be honest before
/// any network call:
///
/// ```powershell
/// # free dev mode — console-registered fictional numbers, no SMS, no billing
/// flutter run --dart-define=PHONE_AUTH_TESTING=true
///
/// # live mode — requires the Blaze plan with billing attached
/// flutter run --dart-define=PHONE_AUTH_ENABLED=true
/// ```
class FirebaseOtpService implements OtpService {
  FirebaseOtpService(this._auth);

  final FirebaseAuth _auth;

  static const bool _testingEnabled =
      bool.fromEnvironment('PHONE_AUTH_TESTING');

  /// Live by default. The flag exists to *switch it off* for a build that
  /// ships before the Firebase project is configured — it is no longer an
  /// opt-in, because leaving it off left a dead button on the welcome screen.
  static const bool _liveEnabled =
      bool.fromEnvironment('PHONE_AUTH_ENABLED', defaultValue: true);

  @override
  OtpAvailability get availability {
    if (_testingEnabled) return OtpAvailability.testNumbers;
    if (_liveEnabled) return OtpAvailability.live;
    return OtpAvailability.unavailable;
  }

  @override
  String get channelLabel => switch (availability) {
        OtpAvailability.testNumbers => 'Test numbers (no SMS sent)',
        OtpAvailability.live => 'SMS',
        OtpAvailability.unavailable => 'Not configured',
      };

  @override
  bool get isUsable => availability != OtpAvailability.unavailable;

  @override
  Future<OtpStartOutcome> start(
    String phoneE164, {
    int? resendToken,
    OtpAutoResolveMode mode = OtpAutoResolveMode.signIn,
  }) {
    if (!isUsable) {
      throw const OtpException(
        'Phone sign-in is not enabled for this build yet.',
      );
    }

    // Firebase's API is callback-based and may fire more than one callback for
    // a single request, so guard every completion path.
    final completer = Completer<OtpStartOutcome>();
    void complete(OtpStartOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
    }

    void fail(Object error, [StackTrace? stack]) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneE164,
          forceResendingToken: resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (credential) async {
            try {
              switch (mode) {
                case OtpAutoResolveMode.signIn:
                  final result = await _auth.signInWithCredential(credential);
                  complete(OtpAutoResolved(result));
                case OtpAutoResolveMode.link:
                  // Attach to the account that is already signed in. Calling
                  // signInWithCredential here would swap the session to the
                  // phone-only account and lose the Google identity.
                  final user = _auth.currentUser;
                  if (user == null) {
                    throw const OtpException('You are not signed in.');
                  }
                  await user.linkWithCredential(credential);
                  complete(const OtpAutoResolved(null));
              }
            } catch (e) {
              // Silent verification fired but the follow-up failed; fall back
              // to manual code entry rather than dead-ending the user.
              debugPrint('[OtpService] auto-resolve failed: $e');
            }
          },
          verificationFailed: (e) => fail(_toOtpException(e)),
          codeSent: (verificationId, token) => complete(
            OtpCodeSent(sessionId: verificationId, resendToken: token),
          ),
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError(fail);

    return completer.future;
  }

  @override
  Future<UserCredential> verifyAndSignIn({
    required String sessionId,
    required String code,
  }) async {
    try {
      return await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: sessionId,
          smsCode: code.trim(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw _toOtpException(e);
    }
  }

  @override
  Future<void> verifyAndLinkToCurrentUser({
    required String sessionId,
    required String code,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const OtpException('You are not signed in.');
    }
    try {
      await user.linkWithCredential(
        PhoneAuthProvider.credential(
          verificationId: sessionId,
          smsCode: code.trim(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw _toOtpException(e);
    }
  }

  OtpException _toOtpException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-phone-number' =>
        'That phone number looks wrong. Example: +251911223344',
      'invalid-verification-code' =>
        'That code is incorrect. Check it and try again.',
      'invalid-verification-id' || 'session-expired' =>
        'This code expired. Request a new one.',
      'quota-exceeded' =>
        'The SMS limit for today is used up. Try again tomorrow.',
      'too-many-requests' =>
        'Too many attempts. Please wait a few minutes and retry.',
      'app-not-authorized' =>
        'This app build is not authorised in Firebase. Check the SHA-1 and SHA-256 fingerprints.',
      'captcha-check-failed' =>
        'Device verification failed. Retry and complete the challenge.',
      'billing-not-enabled' =>
        'Phone sign-in needs billing enabled on the Firebase project.',
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        'That phone number is already linked to another HisabET account.',
      'provider-already-linked' =>
        'This account already has a phone number attached.',
      _ => e.message ?? 'Phone verification failed. Please try again.',
    };
    return OtpException(message, code: e.code);
  }
}
