import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Where "Log In with Telegram" talks to.
class TelegramLoginConfig {
  const TelegramLoginConfig({
    required this.clientId,
    required this.redirectUri,
    required this.exchangeUrl,
  });

  /// The bot's numeric id (public).
  final String clientId;

  /// `https://<backend>/telegram-callback` — must be registered in BotFather.
  final Uri redirectUri;

  /// `https://<backend>/telegram-oidc`.
  final Uri exchangeUrl;
}

/// User-facing failure. [cancelled] means the user backed out — not an error
/// to show.
class TelegramLoginException implements Exception {
  const TelegramLoginException(this.message, {this.cancelled = false});

  const TelegramLoginException.cancelled()
      : message = 'Cancelled.',
        cancelled = true;

  final String message;
  final bool cancelled;

  @override
  String toString() => 'TelegramLoginException: $message';
}

/// Opens [url] in a browser tab and resolves with the redirect URL once the
/// browser navigates to [callbackScheme]. Injectable for tests.
typedef BrowserAuth = Future<String> Function(Uri url, String callbackScheme);

typedef JsonPost = Future<({int status, String body})> Function(
  Uri url,
  Map<String, String> headers,
  String body,
);

/// "Log In with Telegram" — Telegram's official OpenID Connect login.
/// https://core.telegram.org/bots/telegram-login
///
/// Telegram shows its own screens ("Log in to … — Allow access to your phone
/// number?") and afterwards sends the user a "You have successfully logged
/// in" service message, exactly as for any website using Telegram login.
///
/// Flow (authorization code + PKCE):
/// 1. Open `oauth.telegram.org/auth` with scopes `openid profile phone`, a
///    fresh PKCE challenge and a random `state`.
/// 2. Telegram redirects to the backend's `/telegram-callback`, which hands
///    `code` + `state` back to the app via `hisabet://telegram-auth`.
/// 3. The app checks `state` and posts `code` + PKCE verifier to the
///    backend's `/telegram-oidc`, which exchanges it with Telegram using the
///    bot's client secret and verifies Telegram's signed ID token.
/// 4. [signIn] receives a Firebase custom token for the account that owns the
///    phone number; [verifyCurrentUser] has the number attached to the
///    signed-in account instead.
class TelegramLoginService {
  TelegramLoginService({
    required FirebaseAuth auth,
    required TelegramLoginConfig config,
    BrowserAuth? browser,
    JsonPost? post,
    Random? random,
  })  : _auth = auth,
        _config = config,
        _browser = browser ?? _openBrowser,
        _post = post ?? _httpPost,
        _random = random ?? Random.secure();

  static const callbackScheme = 'hisabet';

  final FirebaseAuth _auth;
  final TelegramLoginConfig _config;
  final BrowserAuth _browser;
  final JsonPost _post;
  final Random _random;

  /// "Continue with Telegram" on the sign-in screen.
  Future<void> signIn() async {
    final grant = await _authorize();
    final body = await _exchange(grant, idToken: null);
    final token = body['token'];
    if (token is! String) {
      throw const TelegramLoginException('Sign-in failed on the server. Try again.');
    }
    try {
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw TelegramLoginException('Could not open your account (${e.code}). Try again.');
    }
  }

  /// "Verify with Telegram" for a user who is already signed in (e.g. with
  /// Google). Returns the verified number, which the backend has saved.
  Future<String> verifyCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const TelegramLoginException('You are not signed in.');
    }
    final grant = await _authorize();
    final body = await _exchange(grant, idToken: await user.getIdToken());
    final phone = body['phone'];
    if (phone is! String) {
      throw const TelegramLoginException('Verification failed on the server. Try again.');
    }
    return phone;
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  @visibleForTesting
  Uri authorizationUrl({required String state, required String codeChallenge}) {
    return Uri.https('oauth.telegram.org', '/auth', {
      'client_id': _config.clientId,
      'redirect_uri': _config.redirectUri.toString(),
      'response_type': 'code',
      'scope': 'openid profile phone',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
  }

  Future<({String code, String verifier})> _authorize() async {
    final verifier = _randomToken(32); // 43 chars, RFC 7636
    final state = _randomToken(16);
    final url = authorizationUrl(state: state, codeChallenge: pkceChallenge(verifier));

    final String redirect;
    try {
      redirect = await _browser(url, callbackScheme);
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw const TelegramLoginException.cancelled();
      throw TelegramLoginException('Could not open Telegram login (${e.code}).');
    }

    final params = Uri.parse(redirect).queryParameters;
    if (params['state'] != state) {
      // Not the answer to our request: refuse it.
      throw const TelegramLoginException('Telegram login could not be confirmed. Try again.');
    }
    final error = params['error'];
    if (error != null) {
      if (error == 'access_denied') throw const TelegramLoginException.cancelled();
      throw TelegramLoginException('Telegram login failed ($error).');
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw const TelegramLoginException('Telegram did not complete the login. Try again.');
    }
    return (code: code, verifier: verifier);
  }

  Future<Map<String, dynamic>> _exchange(
    ({String code, String verifier}) grant, {
    required String? idToken,
  }) async {
    final ({int status, String body}) response;
    try {
      response = await _post(
        _config.exchangeUrl,
        {
          'content-type': 'application/json',
          if (idToken != null) 'authorization': 'Bearer $idToken',
        },
        jsonEncode({'code': grant.code, 'codeVerifier': grant.verifier}),
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const TelegramLoginException('No connection. Check your internet and try again.');
    } catch (e) {
      debugPrint('[TelegramLogin] exchange request failed: $e');
      throw const TelegramLoginException('Could not reach HisabET. Check your internet and try again.');
    }

    Map<String, dynamic> body = const {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {/* status decides below */}

    if (response.status == 200) return body;
    throw TelegramLoginException(messageForError(body['error']));
  }

  /// What to tell the user for a backend error code.
  @visibleForTesting
  static String messageForError(Object? error) => switch (error) {
        'phone_missing' =>
          'HisabET needs your phone number. Try again and tap "Allow" when Telegram asks.',
        'phone_invalid' => 'This Telegram number cannot be used. Anonymous +888 numbers are not accepted.',
        'phone_in_use' =>
          'That number already belongs to another HisabET account. Sign in with Telegram instead.',
        'exchange_failed' => 'The Telegram login expired. Please try again.',
        'account_error' => 'Your account could not be created. Please try again in a minute.',
        'telegram_unavailable' => 'Telegram is not responding right now. Please try again.',
        _ => 'Telegram login failed. Please try again.',
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _randomToken(int bytes) => base64Url
      .encode(List<int>.generate(bytes, (_) => _random.nextInt(256)))
      .replaceAll('=', '');

  /// RFC 7636 S256: base64url(sha256(verifier)) without padding.
  @visibleForTesting
  static String pkceChallenge(String verifier) =>
      base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  static Future<String> _openBrowser(Uri url, String callbackScheme) {
    // A normal (non-private) browser tab: Telegram's page waits there while
    // the user confirms in the Telegram app, then redirects back to us.
    return FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: callbackScheme);
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
      return (status: response.statusCode, body: await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  }
}
