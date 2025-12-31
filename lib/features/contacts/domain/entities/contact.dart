import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String id;
  final String name; // "Mr. X"
  final String? phoneNumber;
  final String? shopNumber;
  final double netBalance; // +ve means they owe me, -ve means I owe them
  final DateTime lastTransactionDate;

  const ContactEntity({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.shopNumber,
    this.netBalance = 0.0,
    required this.lastTransactionDate,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    shopNumber,
    netBalance,
    lastTransactionDate,
  ];
}
