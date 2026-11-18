import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/utils/phone_util.dart';

void main() {
  group('PhoneUtil.normalize', () {
    test('Ethio Telecom numbers in every common phone-book format', () {
      for (final raw in [
        '0911223344',
        '0911 22 33 44',
        '091-122-3344',
        '911223344',
        '251911223344',
        '+251911223344',
        '+251 91 122 3344',
        '00251911223344',
      ]) {
        expect(PhoneUtil.normalize(raw), '+251911223344', reason: raw);
      }
    });

    test('Safaricom Ethiopia (07) numbers', () {
      for (final raw in ['0711223344', '711223344', '+251 711 223 344']) {
        expect(PhoneUtil.normalize(raw), '+251711223344', reason: raw);
      }
    });

    test('foreign numbers written with + pass through', () {
      expect(PhoneUtil.normalize('+49 151 1234 5678'), '+4915112345678');
    });

    test('does not invent a country code for other local formats', () {
      expect(PhoneUtil.normalize('0111223344'), '0111223344'); // Addis landline
      expect(PhoneUtil.normalize('12345'), '12345');
    });
  });

  test('isValidE164', () {
    expect(PhoneUtil.isValidE164('+251911223344'), isTrue);
    expect(PhoneUtil.isValidE164('0911223344'), isFalse);
    expect(PhoneUtil.isValidE164('+12'), isFalse);
  });
}
