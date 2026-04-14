import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

enum ContactRole {
  merchant,
  supplier,
  both,
}

enum ContactVerificationStatus {
  unverified,
  pending,
  verified,
  expired,
}

enum VerificationTimeoutPolicy {
  autoConfirm,
  autoExpire,
}

/// Model class for Contact, maps between DB and Domain
class ContactModel {
  final String id;
  final String name;
  final ContactRole role;
  final ContactVerificationStatus verificationStatus;
  final DateTime? verificationRequestedAt;
  final DateTime? verificationDeadlineAt;
  final VerificationTimeoutPolicy verificationTimeoutPolicy;
  final String? phoneNumber;
  final String? shopNumber;
  final Decimal netBalance;
  final DateTime lastTransactionDate;
  final String? linkedUserUid;

  ContactModel({
    required this.id,
    required this.name,
    this.role = ContactRole.merchant,
    this.verificationStatus = ContactVerificationStatus.unverified,
    this.verificationRequestedAt,
    this.verificationDeadlineAt,
    this.verificationTimeoutPolicy = VerificationTimeoutPolicy.autoConfirm,
    this.phoneNumber,
    this.shopNumber,
    required this.netBalance,
    required this.lastTransactionDate,
    this.linkedUserUid,
  });

  /// From database row (Drift generated class)
  factory ContactModel.fromDb(Contact dbContact) {
    return ContactModel(
      id: dbContact.id,
      name: dbContact.name,
      role: ContactRole.values[dbContact.role],
        verificationStatus:
          ContactVerificationStatus.values[dbContact.verificationStatus],
        verificationRequestedAt: dbContact.verificationRequestedAt,
        verificationDeadlineAt: dbContact.verificationDeadlineAt,
        verificationTimeoutPolicy:
          VerificationTimeoutPolicy.values[dbContact.verificationTimeoutPolicy],
      phoneNumber: dbContact.phoneNumber,
      shopNumber: dbContact.shopNumber,
      netBalance: Decimal.parse(dbContact.netBalance),
      lastTransactionDate: dbContact.lastTransactionDate,
      linkedUserUid: dbContact.linkedUserUid,
    );
  }

  /// To database companion for insert/update
  ContactsCompanion toDbCompanion() {
    return ContactsCompanion.insert(
      id: id,
      name: name,
      role: drift.Value(role.index),
      verificationStatus: drift.Value(verificationStatus.index),
      verificationRequestedAt: drift.Value(verificationRequestedAt),
      verificationDeadlineAt: drift.Value(verificationDeadlineAt),
      verificationTimeoutPolicy: drift.Value(verificationTimeoutPolicy.index),
      phoneNumber: drift.Value(phoneNumber),
      shopNumber: drift.Value(shopNumber),
      netBalance: drift.Value(netBalance.toString()),
      lastTransactionDate: lastTransactionDate,
      linkedUserUid: drift.Value(linkedUserUid),
    );
  }

  bool get isVerified => verificationStatus == ContactVerificationStatus.verified;
  bool get isPendingVerification => verificationStatus == ContactVerificationStatus.pending;
  bool get isUnverified => verificationStatus == ContactVerificationStatus.unverified;
  bool get isVerificationExpired =>
      verificationStatus == ContactVerificationStatus.expired;
}
