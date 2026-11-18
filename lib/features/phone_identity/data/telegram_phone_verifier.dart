import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hisabet/features/phone_identity/data/session_id.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';

/// A failure starting Telegram verification, phrased for end users.
class TelegramVerificationException implements Exception {
  const TelegramVerificationException(this.message);
  final String message;

  @override
  String toString() => 'TelegramVerificationException: $message';
}

/// Verifies the signed-in user's phone number through the HisabET Telegram bot.
///
/// The flow, end to end:
/// 1. [start] creates a `phone_verifications/{id}` document with a secret id.
/// 2. The app opens [appLink] / [webLink]; Telegram starts the bot with that id.
/// 3. The user taps "Share my phone number" in Telegram.
/// 4. The backend checks the contact is the sender's own, claims the number
///    and writes it to `users/{uid}` — the app never writes the number itself.
/// 5. [watch] reports `verified` (or why it failed).
///
/// Backend: `functions/src/telegram/`. Setup: TELEGRAM_PHONE_VERIFICATION.md.
abstract class TelegramPhoneVerifier {
  String get botUsername;

  Future<TelegramVerificationSession> start();

  Stream<TelegramVerificationSession> watch(String sessionId);

  /// Opens the Telegram app directly.
  Uri appLink(String sessionId) =>
      Uri.parse('tg://resolve?domain=$botUsername&start=$sessionId');

  /// Fallback when the app is not installed: t.me offers to install it.
  Uri webLink(String sessionId) =>
      Uri.parse('https://t.me/$botUsername?start=$sessionId');
}

class FirestoreTelegramPhoneVerifier extends TelegramPhoneVerifier {
  FirestoreTelegramPhoneVerifier({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required this.botUsername,
    Random? random,
    this.createTimeout = const Duration(seconds: 15),
  })  : _db = firestore,
        _auth = auth,
        _random = random;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Random? _random;
  final Duration createTimeout;

  @override
  final String botUsername;

  static const collection = 'phone_verifications';

  @override
  Future<TelegramVerificationSession> start() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const TelegramVerificationException('You are not signed in.');
    }

    final id = generateSessionId(_random);
    try {
      // Must reach the server before the bot can see it, so wait for the
      // write to be acknowledged instead of trusting the offline cache.
      await _db.collection(collection).doc(id).set({
        'uid': uid,
        'status': TelegramVerificationStatus.pending.storageKey,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(createTimeout);
    } on TimeoutException {
      throw const TelegramVerificationException(
        'No connection. Telegram verification needs the internet — try again when you are online.',
      );
    } on FirebaseException catch (e) {
      throw TelegramVerificationException(
        e.code == 'permission-denied'
            ? 'Verification was blocked by the server. Update the app and try again.'
            : 'Could not start verification (${e.code}). Try again.',
      );
    }

    return TelegramVerificationSession(
      id: id,
      status: TelegramVerificationStatus.pending,
    );
  }

  @override
  Stream<TelegramVerificationSession> watch(String sessionId) {
    return _db
        .collection(collection)
        .doc(sessionId)
        .snapshots()
        .map((snap) => TelegramVerificationSession.fromMap(snap.id, snap.data()));
  }
}
