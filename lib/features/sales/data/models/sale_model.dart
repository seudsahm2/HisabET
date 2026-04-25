import 'package:decimal/decimal.dart';
import 'package:hisabet/core/database/app_database.dart';

class SaleModel {
  final String id;
  final String? contactId;
  final String? customerName;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal tax;
  final Decimal total;
  final Decimal paidAmount;
  final String paymentMethod;
  final String status;
  final String? note;
  final DateTime createdAt;

  const SaleModel({
    required this.id,
    this.contactId,
    this.customerName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.paymentMethod,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory SaleModel.fromDb(Sale dbSale) {
    return SaleModel(
      id: dbSale.id,
      contactId: dbSale.contactId,
      customerName: dbSale.customerName,
      subtotal: Decimal.parse(dbSale.subtotal),
      discount: Decimal.parse(dbSale.discount),
      tax: Decimal.parse(dbSale.tax),
      total: Decimal.parse(dbSale.total),
      paidAmount: Decimal.parse(dbSale.paidAmount),
      paymentMethod: dbSale.paymentMethod,
      status: dbSale.status,
      note: dbSale.note,
      createdAt: dbSale.createdAt,
    );
  }
}
