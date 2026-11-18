import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/features/phone_identity/data/phone_identity_config.dart';
import 'package:hisabet/features/phone_identity/domain/phone_verification_method.dart';
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

  group('PhoneIdentityConfig.parseBackendUrl', () {
    test('accepts a bare host or a full https URL, trailing slash or not', () {
      for (final raw in [
        'hisabet-backend.netlify.app',
        'https://hisabet-backend.netlify.app',
        'https://hisabet-backend.netlify.app/',
        '  https://hisabet-backend.netlify.app//  ',
      ]) {
        expect(
          PhoneIdentityConfig.parseBackendUrl(raw).toString(),
          'https://hisabet-backend.netlify.app',
          reason: raw,
        );
      }
    });

    test('keeps a base path', () {
      expect(
        PhoneIdentityConfig.parseBackendUrl('https://x.example.com/api/').toString(),
        'https://x.example.com/api',
      );
    });

    test('refuses plain http and junk, because an ID token is sent there', () {
      for (final raw in ['', 'http://x.netlify.app', 'ftp://x', 'https://']) {
        expect(PhoneIdentityConfig.parseBackendUrl(raw), isNull, reason: raw);
      }
    });
  });

  group('PhoneIdentityConfig.parseClientId', () {
    test('accepts the numeric bot id', () {
      expect(PhoneIdentityConfig.parseClientId('7123456789'), '7123456789');
    });

    test('keeps only the id when a whole bot token is pasted, so the secret never ships', () {
      expect(PhoneIdentityConfig.parseClientId('7123456789:AAHsecretPart'), '7123456789');
    });

    test('rejects empty and non-numeric values', () {
      for (final raw in ['', 'hisabetbot', '12ab', '123']) {
        expect(PhoneIdentityConfig.parseClientId(raw), isNull, reason: raw);
      }
    });
  });
}
