import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

/// Model class for Contact, maps between DB and Domain
class ContactModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? shopNumber;
  final Decimal netBalance;
  final DateTime lastTransactionDate;

  ContactModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.shopNumber,
    required this.netBalance,
    required this.lastTransactionDate,
  });

  /// From database row (Drift generated class)
  factory ContactModel.fromDb(Contact dbContact) {
    return ContactModel(
      id: dbContact.id,
      name: dbContact.name,
      phoneNumber: dbContact.phoneNumber,
      shopNumber: dbContact.shopNumber,
      netBalance: Decimal.parse(dbContact.netBalance),
      lastTransactionDate: dbContact.lastTransactionDate,
    );
  }

  /// To database companion for insert/update
  ContactsCompanion toDbCompanion() {
    return ContactsCompanion.insert(
      id: id,
      name: name,
      phoneNumber: drift.Value(phoneNumber),
      shopNumber: drift.Value(shopNumber),
      netBalance: drift.Value(netBalance.toString()),
      lastTransactionDate: lastTransactionDate,
    );
  }
}
