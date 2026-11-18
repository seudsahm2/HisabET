import 'dart:convert';
import 'dart:math';

/// A verification session id: 32 bytes from a cryptographically secure
/// source, base64url without padding — 43 characters of `[A-Za-z0-9_-]`.
///
/// That alphabet and length fit Telegram's `/start` payload limit (64 chars)
/// and the pattern enforced by `firestore.rules`. The id is the only secret
/// linking a Telegram account to a HisabET account, so it must never come
/// from `Random()`.
String generateSessionId([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => source.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
