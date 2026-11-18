import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/domain/business_role.dart';
import 'package:hisabet/features/contacts/data/phone_book/phone_book.dart';

PhoneBookContact contact(String id, String name, List<String> phones) =>
    PhoneBookContact(id: id, name: name, phones: phones);

const abebe = HisabetUser(uid: 'u-abebe', name: 'Abebe Shoes', phone: '+251911000001', roles: [BusinessRole.broker]);

void main() {
  group('DevicePhoneBook.toPhoneBookContact', () {
    test('normalises and de-duplicates the numbers of one person', () {
      final c = DevicePhoneBook.toPhoneBookContact('1', 'Abebe', ['0911 00 00 01', '+251911000001', '0711000002']);
      expect(c!.phones, ['+251911000001', '+251711000002']);
    });

    test('drops people without a usable number', () {
      expect(DevicePhoneBook.toPhoneBookContact('1', 'No number', ['', '12']), isNull);
    });

    test('falls back to the number when the name is empty', () {
      expect(DevicePhoneBook.toPhoneBookContact('1', '  ', ['0911000001'])!.name, '+251911000001');
    });
  });

  group('matchPhoneBook', () {
    test('splits people on HisabET from everyone else, sorted by name', () {
      final match = matchPhoneBook(
        contacts: [
          contact('2', 'zelalem', ['+251922000002']),
          contact('1', 'Abebe (Merkato)', ['+251911000001']),
          contact('3', 'Almaz', ['+251933000003']),
        ],
        usersByPhone: {abebe.phone: abebe},
      );
      expect(match.onHisabet.map((e) => e.user!.uid), ['u-abebe']);
      expect(match.notOnHisabet.map((e) => e.contact.name), ['Almaz', 'zelalem']);
      expect(match.total, 3);
    });

    test('matches on whichever of several numbers has an account', () {
      final match = matchPhoneBook(
        contacts: [
          contact('1', 'Abebe', ['+251700000000', abebe.phone]),
        ],
        usersByPhone: {abebe.phone: abebe},
      );
      expect(match.onHisabet.single.phone, abebe.phone);
    });

    test('lists one HisabET account once even if saved twice in the phone', () {
      final match = matchPhoneBook(
        contacts: [
          contact('1', 'Abebe', [abebe.phone]),
          contact('2', 'Abebe shop', [abebe.phone]),
        ],
        usersByPhone: {abebe.phone: abebe},
      );
      expect(match.onHisabet, hasLength(1));
    });

    test('marks people already in the ledger, by account or by number', () {
      final match = matchPhoneBook(
        contacts: [
          contact('1', 'Abebe', [abebe.phone]),
          contact('2', 'Almaz', ['+251933000003']),
          contact('3', 'Kebede', ['+251944000004']),
        ],
        usersByPhone: {abebe.phone: abebe},
        savedUids: {'u-abebe'},
        savedPhones: {'+251933000003'},
      );
      expect(match.onHisabet.single.alreadySaved, isTrue);
      final others = {for (final e in match.notOnHisabet) e.contact.name: e.alreadySaved};
      expect(others, {'Almaz': true, 'Kebede': false});
    });
  });
}
