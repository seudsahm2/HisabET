import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A number confirmed by the carrier, plus the attestation that proves it.
class PnvResult {
  const PnvResult({required this.phoneNumber, required this.token});

  /// E.164, straight from the carrier. In test mode this is a valid country
  /// code followed by zeros, so it must not be rejected as malformed.
  final String phoneNumber;

  /// Signed attestation. Only a backend can check it — see the caveat on
  /// [PnvService].
  final String token;
}

class PnvException implements Exception {
  const PnvException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PnvException($code): $message';
}

/// Firebase Phone Number Verification — the carrier confirms the number of the
/// SIM in the device, so nothing is sent and nothing is typed.
///
/// ## Why this is a platform channel
///
/// Firebase ships PNV as an Android library only; there is no FlutterFire
/// plugin. The Kotlin side lives in `MainActivity.kt`.
///
/// ## Two limits worth knowing before relying on it
///
/// **Carrier coverage.** PNV works through direct carrier integrations, and at
/// the time of writing the supported list is Finland, France, Germany,
/// Indonesia, Malaysia and Spain. Ethio Telecom is not on it. So on a real
/// Ethiopian SIM [verify] will fail today — which is why this is offered as a
/// fast path with OTP behind it, never as the only route. Test mode works
/// everywhere, because it uses a mock number instead of a SIM.
///
/// **It is not a Firebase Auth credential.** Linking an OTP code puts the
/// number on the auth record itself, where the server owns it. PNV instead
/// returns a token that a backend has to exchange for a custom token. Until
/// that Cloud Function exists, a PNV result is a *client* claim: good enough to
/// fill the field and skip the SMS, not good enough to be treated as proof by
/// the other side of a ledger.
class PnvService {
  const PnvService();

  static const MethodChannel _channel = MethodChannel('hisabet/pnv');

  /// Dev-only token from Firebase Console → Security → Phone Verification →
  /// Testing. Expires after 7 days. Passed at run time so nothing is committed:
  ///
  /// ```powershell
  /// flutter run --dart-define=FIREBASE_PNV_TEST_TOKEN=<token>
  /// ```
  static const String testToken =
      String.fromEnvironment('FIREBASE_PNV_TEST_TOKEN');

  static bool get hasTestToken => testToken.isNotEmpty;

  /// Whether the platform can attempt PNV at all. True does **not** promise the
  /// carrier is supported — that is only known once [verify] runs.
  Future<bool> isAvailable() async {
    if (!defaultTargetPlatform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Arms test mode. Safe to call more than once — the native side keeps the
  /// single-call rule for the process. Returns false when there is nothing to
  /// arm, which is the normal production case.
  Future<bool> enableTestSession() async {
    if (!hasTestToken) return false;
    if (!defaultTargetPlatform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'enableTestSession',
            {'token': testToken},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('[PNV] test session refused: ${e.code} ${e.message}');
      return false;
    }
  }

  /// Asks the carrier to confirm the device's number.
  Future<PnvResult> verify() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('verify');
      final phone = raw?['phoneNumber']?.toString();
      final token = raw?['token']?.toString();
      if (phone == null || phone.isEmpty || token == null || token.isEmpty) {
        throw const PnvException('The carrier did not return a number.');
      }
      return PnvResult(phoneNumber: phone, token: token);
    } on MissingPluginException {
      throw const PnvException(
        'Network verification is not available in this build.',
        code: 'unsupported',
      );
    } on PlatformException catch (e) {
      throw PnvException(_message(e), code: e.code);
    }
  }

  String _message(PlatformException e) => switch (e.code) {
        'unsupported' =>
          'Network verification needs Android 8 or newer on this device.',
        'no-token' => 'No test token was supplied for this build.',
        _ =>
          'Your mobile network could not confirm this number. Use the code '
              'instead.',
      };
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
