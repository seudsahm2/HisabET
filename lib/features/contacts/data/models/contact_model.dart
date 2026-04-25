import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

enum ContactRole { merchant, supplier, both }

enum ContactVerificationStatus { unverified, pending, verified, expired }

enum VerificationTimeoutPolicy { autoConfirm, autoExpire }

/// How the contact was matched to an app user
enum ContactVerificationMethod { phone, email }

/// Model class for Contact, maps between DB and Domain
class ContactModel {
  final String id;
  final String name;
  final ContactRole role; // legacy field
  final ContactVerificationStatus verificationStatus;
  final DateTime? verificationRequestedAt;
  final DateTime? verificationDeadlineAt;
  final VerificationTimeoutPolicy verificationTimeoutPolicy;
  final String? phoneNumber;
  final String? shopNumber;
  final Decimal netBalance;
  final Decimal creditLimit;
  final int loyaltyPoints;
  final DateTime lastTransactionDate;
  final String? linkedUserUid;
  final String? verificationMethod; // 'phone' or 'email'

  // New multi-role flags
  final bool isRetailer;
  final bool isWholesaler;
  final bool isBroker;
  final bool isSupplier;

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
    Decimal? creditLimit,
    this.loyaltyPoints = 0,
    required this.lastTransactionDate,
    this.linkedUserUid,
    this.verificationMethod,
    this.isRetailer = false,
    this.isWholesaler = false,
    this.isBroker = false,
    this.isSupplier = false,
  }) : creditLimit = creditLimit ?? Decimal.zero;

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
      creditLimit: Decimal.parse(dbContact.creditLimit),
      loyaltyPoints: dbContact.loyaltyPoints,
      lastTransactionDate: dbContact.lastTransactionDate,
      linkedUserUid: dbContact.linkedUserUid,
      verificationMethod: dbContact.verificationMethod,
      isRetailer: dbContact.isRetailer,
      isWholesaler: dbContact.isWholesaler,
      isBroker: dbContact.isBroker,
      isSupplier: dbContact.isSupplier,
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
      creditLimit: drift.Value(creditLimit.toString()),
      loyaltyPoints: drift.Value(loyaltyPoints),
      lastTransactionDate: lastTransactionDate,
      linkedUserUid: drift.Value(linkedUserUid),
      verificationMethod: drift.Value(verificationMethod),
      isRetailer: drift.Value(isRetailer),
      isWholesaler: drift.Value(isWholesaler),
      isBroker: drift.Value(isBroker),
      isSupplier: drift.Value(isSupplier),
    );
  }

  /// Returns labels of all active roles for display
  List<String> get roleLabels {
    final labels = <String>[];
    if (isRetailer) labels.add('Retailer');
    if (isWholesaler) labels.add('Wholesaler');
    if (isBroker) labels.add('Broker');
    if (isSupplier) labels.add('Supplier');
    if (labels.isEmpty) labels.add('Merchant');
    return labels;
  }

  bool get isVerified =>
      verificationStatus == ContactVerificationStatus.verified;
  bool get isPendingVerification =>
      verificationStatus == ContactVerificationStatus.pending;
  bool get isUnverified =>
      verificationStatus == ContactVerificationStatus.unverified;
  bool get isVerificationExpired =>
      verificationStatus == ContactVerificationStatus.expired;

  /// Human-readable verified-by label for UI display
  String get verificationLabel {
    if (verificationMethod == 'email') return 'VERIFIED BY EMAIL';
    if (verificationMethod == 'phone') return 'VERIFIED BY PHONE';
    return 'VERIFIED';
  }
}
