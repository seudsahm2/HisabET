import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/features/phone_identity/data/phone_identity_config.dart';
import 'package:hisabet/features/phone_identity/data/session_id.dart';
import 'package:hisabet/features/phone_identity/data/telegram_launcher.dart';
import 'package:hisabet/features/phone_identity/domain/phone_verification_method.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';
import 'package:hisabet/features/phone_identity/domain/verified_phone.dart';

void main() {
  group('PhoneVerificationMethod', () {
    test('storage keys match firestore.rules and the backend', () {
      // Changing any of these breaks stored data and the security rules.
      expect(
        PhoneVerificationMethod.values.map((m) => m.storageKey),
        ['auth', 'otp', 'telegram', 'pnv'],
      );
    });

    test('only the carrier relay is not server-proven', () {
      expect(
        PhoneVerificationMethod.values.where((m) => !m.isServerProven),
        [PhoneVerificationMethod.carrier],
      );
    });

    test('tryParse rejects unknown values', () {
      expect(PhoneVerificationMethod.tryParse('telegram'),
          PhoneVerificationMethod.telegram);
      expect(PhoneVerificationMethod.tryParse('Telegram'), isNull);
      expect(PhoneVerificationMethod.tryParse(null), isNull);
      expect(PhoneVerificationMethod.tryParse(3), isNull);
    });
  });

  group('VerifiedPhone.fromProfile', () {
    const proven = {
      'phone': '+251911223344',
      'phoneVerified': true,
      'phoneVerificationMethod': 'telegram',
    };

    test('accepts a proven number', () {
      expect(
        VerifiedPhone.fromProfile(proven),
        const VerifiedPhone(
          e164: '+251911223344',
          method: PhoneVerificationMethod.telegram,
        ),
      );
    });

    test('rejects a number without phoneVerified (legacy profile-edit data)', () {
      expect(VerifiedPhone.fromProfile({...proven, 'phoneVerified': null}), isNull);
    });

    test('rejects a client-relayed PNV claim', () {
      expect(
        VerifiedPhone.fromProfile({...proven, 'phoneVerificationMethod': 'pnv'}),
        isNull,
      );
    });

    test('rejects a missing or unknown method', () {
      expect(
        VerifiedPhone.fromProfile({...proven, 'phoneVerificationMethod': null}),
        isNull,
      );
      expect(
        VerifiedPhone.fromProfile({...proven, 'phoneVerificationMethod': 'sms'}),
        isNull,
      );
    });

    test('rejects blank numbers and missing documents', () {
      expect(VerifiedPhone.fromProfile({...proven, 'phone': '  '}), isNull);
      expect(VerifiedPhone.fromProfile(null), isNull);
    });
  });

  group('TelegramVerificationSession.fromMap', () {
    test('reads a verified session', () {
      final s = TelegramVerificationSession.fromMap('id', {
        'status': 'verified',
        'phone': '+251911223344',
      });
      expect(s.status, TelegramVerificationStatus.verified);
      expect(s.phone, '+251911223344');
      expect(s.failure, isNull);
    });

    test('reads the failure reason only for failed sessions', () {
      final failed = TelegramVerificationSession.fromMap('id', {
        'status': 'failed',
        'failureReason': 'phone_in_use',
      });
      expect(failed.failure, TelegramVerificationFailure.phoneInUse);

      final pending = TelegramVerificationSession.fromMap('id', {
        'status': 'awaiting_contact',
        'failureReason': 'phone_in_use',
      });
      expect(pending.failure, isNull);
    });

    test('degrades unknown values safely', () {
      final s = TelegramVerificationSession.fromMap('id', {
        'status': 'something_new',
      });
      expect(s.status, TelegramVerificationStatus.pending);
      expect(
        TelegramVerificationSession.fromMap('id', {'status': 'failed'}).failure,
        TelegramVerificationFailure.unknown,
      );
    });
  });

  group('generateSessionId', () {
    test('matches the format firestore.rules and Telegram accept', () {
      final pattern = RegExp(r'^[A-Za-z0-9_-]{32,64}$');
      for (var i = 0; i < 200; i++) {
        final id = generateSessionId();
        expect(id, hasLength(43));
        expect(pattern.hasMatch(id), isTrue, reason: id);
      }
    });

    test('is unique across many draws', () {
      final ids = {for (var i = 0; i < 1000; i++) generateSessionId()};
      expect(ids, hasLength(1000));
    });

    test('is deterministic for a seeded source (testability only)', () {
      expect(generateSessionId(Random(1)), generateSessionId(Random(1)));
    });
  });

  group('PhoneIdentityConfig.parseBotUsername', () {
    test('accepts valid bot usernames, with or without @', () {
      expect(PhoneIdentityConfig.parseBotUsername('HisabETBot'), 'HisabETBot');
      expect(PhoneIdentityConfig.parseBotUsername('@hisabet_bot'), 'hisabet_bot');
    });

    test('rejects empty, non-bot and malformed names', () {
      for (final raw in ['', 'hisabet', 'bot', '1HisabETBot', 'hisab et bot', 'x&y_bot']) {
        expect(PhoneIdentityConfig.parseBotUsername(raw), isNull, reason: raw);
      }
    });
  });

  group('TelegramLauncher', () {
    final app = Uri.parse('tg://resolve?domain=HisabETBot&start=abc');
    final web = Uri.parse('https://t.me/HisabETBot?start=abc');

    test('opens the Telegram app when installed', () async {
      final opened = <Uri>[];
      final launcher = TelegramLauncher(open: (uri) async {
        opened.add(uri);
        return true;
      });
      expect(await launcher.open(appLink: app, webLink: web), isTrue);
      expect(opened, [app]);
    });

    test('falls back to t.me when tg:// is not handled', () async {
      final opened = <Uri>[];
      final launcher = TelegramLauncher(open: (uri) async {
        opened.add(uri);
        if (uri.scheme == 'tg') throw Exception('no handler');
        return true;
      });
      expect(await launcher.open(appLink: app, webLink: web), isTrue);
      expect(opened, [app, web]);
    });

    test('reports failure when nothing can open the link', () async {
      final launcher = TelegramLauncher(open: (_) async => false);
      expect(await launcher.open(appLink: app, webLink: web), isFalse);
    });
  });
}
