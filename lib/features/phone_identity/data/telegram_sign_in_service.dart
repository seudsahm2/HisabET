import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:hisabet/features/phone_identity/data/telegram_phone_verifier.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';

/// A minimal JSON POST, injectable so the service can be tested without a network.
typedef JsonPost = Future<({int status, String body})> Function(
  Uri url,
  Map<String, String> headers,
  String body,
);

class TelegramSignInException implements Exception {
  const TelegramSignInException(this.message);
  final String message;

  @override
  String toString() => 'TelegramSignInException: $message';
}

/// "Continue with Telegram" — signing in with the phone number on the user's
/// Telegram account. The number becomes the account: a returning user gets
/// their existing account back, a new number gets a new account, and either
/// way the profile already has a verified, unique phone.
///
/// 1. [begin] signs in **anonymously** (a temporary Firebase account that
///    only exists so Firestore rules can tie the session to this device) and
///    creates a sign-in session.
/// 2. The caller opens Telegram; the user shares their number with the bot.
/// 3. When the session reads `verified`, [finish] sends this device's ID
///    token to the backend, receives a custom token for the real account and
///    signs into it. The backend then deletes the temporary account.
///
/// Backend: `functions/src/telegram/signin-exchange.ts`.
class TelegramSignInService {
  TelegramSignInService({
    required FirebaseAuth auth,
    required TelegramPhoneVerifier verifier,
    required Uri exchangeUrl,
    JsonPost? post,
    this.notReadyRetryDelay = const Duration(seconds: 1),
  })  : _auth = auth,
        _verifier = verifier,
        _exchangeUrl = exchangeUrl,
        _post = post ?? _httpPost;

  final FirebaseAuth _auth;
  final TelegramPhoneVerifier _verifier;
  final Uri _exchangeUrl;
  final JsonPost _post;
  final Duration notReadyRetryDelay;

  TelegramPhoneVerifier get verifier => _verifier;

  Future<TelegramVerificationSession> begin() async {
    final current = _auth.currentUser;
    if (current != null && !current.isAnonymous) {
      throw const TelegramSignInException('You are already signed in.');
    }
    if (current == null) {
      try {
        await _auth.signInAnonymously();
      } on FirebaseAuthException catch (e) {
        throw TelegramSignInException(
          e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation'
              ? 'Telegram sign-in is not switched on yet (enable Anonymous sign-in in the Firebase console).'
              : 'Could not start Telegram sign-in (${e.code}). Check your connection.',
        );
      }
    }
    try {
      return await _verifier.start(purpose: TelegramSessionPurpose.signIn);
    } on TelegramVerificationException catch (e) {
      throw TelegramSignInException(e.message);
    }
  }

  Future<void> finish(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw const TelegramSignInException('This sign-in expired. Start again.');
    }

    final token = await _exchange(user, sessionId);
    try {
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw TelegramSignInException('Could not open your account (${e.code}). Try again.');
    }
  }

  /// Leaves the temporary account so the sign-in screen starts clean.
  Future<void> cancel() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  Future<String> _exchange(User user, String sessionId, {bool retried = false}) async {
    final idToken = await user.getIdToken();
    final ({int status, String body}) response;
    try {
      response = await _post(
        _exchangeUrl,
        {'authorization': 'Bearer $idToken', 'content-type': 'application/json'},
        jsonEncode({'sessionId': sessionId}),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const TelegramSignInException('No connection. Check your internet and try again.');
    } catch (e) {
      debugPrint('[TelegramSignIn] exchange request failed: $e');
      throw const TelegramSignInException('Could not reach HisabET. Check your internet and try again.');
    }

    Map<String, dynamic> body = const {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {/* handled by status below */}

    if (response.status == 200 && body['token'] is String) {
      return body['token'] as String;
    }
    // The session document can reach the app a moment before the exchange
    // sees it as committed; one short retry covers that.
    if (response.status == 409 && body['error'] == 'not_ready' && !retried) {
      await Future<void>.delayed(notReadyRetryDelay);
      return _exchange(user, sessionId, retried: true);
    }
    throw TelegramSignInException(switch (response.status) {
      409 || 410 => 'This sign-in link was already used or expired. Start again.',
      401 || 403 || 404 => 'This sign-in is no longer valid. Start again.',
      _ => 'Sign-in failed on the server (${response.status}). Try again.',
    });
  }

  static Future<({int status, String body})> _httpPost(
    Uri url,
    Map<String, String> headers,
    String body,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      headers.forEach(request.headers.set);
      request.write(body);
      final response = await request.close();
      return (
        status: response.statusCode,
        body: await response.transform(utf8.decoder).join(),
      );
    } finally {
      client.close();
    }
  }
}
