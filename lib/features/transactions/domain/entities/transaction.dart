import 'package:equatable/equatable.dart';

enum TransactionType {
  goodsGiven, // Receivables (They owe me)
  goodsTaken, // Payables (I owe them)
  paymentGiven, // I paid them
  paymentReceived, // They paid me
}

class TransactionEntity extends Equatable {
  final String id;
  final String counterpartyId;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description; // "2 x 36 x 1250"
  final Map<String, dynamic>? metadata; // {quantity: 72, unitPrice: 1250}

  const TransactionEntity({
    required this.id,
    required this.counterpartyId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    counterpartyId,
    type,
    amount,
    date,
    description,
    metadata,
  ];
}
