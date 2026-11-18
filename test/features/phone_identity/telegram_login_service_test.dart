import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/features/phone_identity/data/telegram_login_service.dart';

class _FakeCredential extends Fake implements UserCredential {}

class _FakeUser extends Fake implements User {
  @override
  bool get isAnonymous => false;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'firebase-id-token';
}

class _FakeAuth extends Fake implements FirebaseAuth {
  String? customToken;
  User? user;

  @override
  User? get currentUser => user;

  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    customToken = token;
    return _FakeCredential();
  }
}

final _config = TelegramLoginConfig(
  clientId: '7123456789',
  redirectUri: Uri.parse('https://hisabet.netlify.app/telegram-callback'),
  exchangeUrl: Uri.parse('https://hisabet.netlify.app/telegram-oidc'),
);

void main() {
  late _FakeAuth auth;
  late Uri openedUrl;
  late Map<String, String> sentHeaders;
  late Map<String, dynamic> sentBody;

  /// A browser that approves the login, echoing [state] unless told otherwise.
  BrowserAuth browserReturning({String? code = 'one-time-code', String? state, String? error}) {
    return (url, scheme) async {
      openedUrl = url;
      expect(scheme, 'hisabet');
      final params = <String, String>{
        'state': state ?? url.queryParameters['state']!,
        if (code != null) 'code': code,
        if (error != null) 'error': error,
      };
      return Uri(scheme: 'hisabet', host: 'telegram-auth', queryParameters: params).toString();
    };
  }

  JsonPost serverReturning(int status, Map<String, dynamic> body) {
    return (url, headers, payload) async {
      expect(url, _config.exchangeUrl);
      sentHeaders = headers;
      sentBody = jsonDecode(payload) as Map<String, dynamic>;
      return (status: status, body: jsonEncode(body));
    };
  }

  setUp(() => auth = _FakeAuth());

  TelegramLoginService service({required BrowserAuth browser, required JsonPost post}) =>
      TelegramLoginService(auth: auth, config: _config, browser: browser, post: post);

  test('PKCE challenge matches the RFC 7636 test vector', () {
    expect(
      TelegramLoginService.pkceChallenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  group('signIn', () {
    test('runs the official flow and signs into the returned account', () async {
      await service(
        browser: browserReturning(),
        post: serverReturning(200, {'token': 'custom-token', 'created': true}),
      ).signIn();

      // Telegram's authorize URL, with phone scope and PKCE.
      expect(openedUrl.host, 'oauth.telegram.org');
      expect(openedUrl.path, '/auth');
      final q = openedUrl.queryParameters;
      expect(q['client_id'], '7123456789');
      expect(q['redirect_uri'], 'https://hisabet.netlify.app/telegram-callback');
      expect(q['response_type'], 'code');
      expect(q['scope'], 'openid profile phone');
      expect(q['code_challenge_method'], 'S256');

      // The backend got the code and the verifier that matches the challenge.
      expect(sentBody['code'], 'one-time-code');
      final verifier = sentBody['codeVerifier'] as String;
      expect(verifier.length, greaterThanOrEqualTo(43));
      expect(
        base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', ''),
        q['code_challenge'],
      );
      // Sign-in sends no Firebase identity.
      expect(sentHeaders.containsKey('authorization'), isFalse);

      expect(auth.customToken, 'custom-token');
    });

    test('refuses a redirect whose state does not match (forged or stale)', () async {
      final s = service(browser: browserReturning(state: 'someone-elses'), post: serverReturning(200, {'token': 't'}));
      await expectLater(s.signIn(), throwsA(isA<TelegramLoginException>().having((e) => e.cancelled, 'cancelled', false)));
      expect(auth.customToken, isNull);
    });

    test('treats closing the browser as a quiet cancel', () async {
      final s = service(
        browser: (_, _) async => throw PlatformException(code: 'CANCELED'),
        post: serverReturning(200, {}),
      );
      await expectLater(s.signIn(), throwsA(isA<TelegramLoginException>().having((e) => e.cancelled, 'cancelled', true)));
    });

    test('treats "Decline" in Telegram as a quiet cancel', () async {
      final s = service(browser: browserReturning(code: null, error: 'access_denied'), post: serverReturning(200, {}));
      await expectLater(s.signIn(), throwsA(isA<TelegramLoginException>().having((e) => e.cancelled, 'cancelled', true)));
    });

    test('explains a denied phone permission', () async {
      final s = service(browser: browserReturning(), post: serverReturning(422, {'error': 'phone_missing'}));
      await expectLater(
        s.signIn(),
        throwsA(isA<TelegramLoginException>().having((e) => e.message, 'message', contains('Allow'))),
      );
    });

    test('reports a network failure plainly', () async {
      final s = service(browser: browserReturning(), post: (_, _, _) async => throw const SocketExceptionLike());
      await expectLater(s.signIn(), throwsA(isA<TelegramLoginException>()));
    });
  });

  group('verifyCurrentUser', () {
    test('sends the Firebase ID token and returns the saved number', () async {
      auth.user = _FakeUser();
      final phone = await service(
        browser: browserReturning(),
        post: serverReturning(200, {'phone': '+251966143454'}),
      ).verifyCurrentUser();

      expect(phone, '+251966143454');
      expect(sentHeaders['authorization'], 'Bearer firebase-id-token');
      expect(auth.customToken, isNull);
    });

    test('explains a number that belongs to another account', () async {
      auth.user = _FakeUser();
      final s = service(browser: browserReturning(), post: serverReturning(409, {'error': 'phone_in_use'}));
      await expectLater(
        s.verifyCurrentUser(),
        throwsA(isA<TelegramLoginException>().having((e) => e.message, 'message', contains('another HisabET account'))),
      );
    });

    test('requires a signed-in user', () async {
      final s = service(browser: browserReturning(), post: serverReturning(200, {}));
      await expectLater(s.verifyCurrentUser(), throwsA(isA<TelegramLoginException>()));
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
