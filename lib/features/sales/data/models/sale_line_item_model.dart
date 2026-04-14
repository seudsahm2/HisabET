import 'package:decimal/decimal.dart';
import 'package:hisabet/core/database/app_database.dart';

class SaleLineItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String? sku;
  final Decimal unitPrice;
  final int quantity;
  final Decimal lineTotal;

  const SaleLineItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory SaleLineItemModel.fromDb(SaleLineItem dbItem) {
    return SaleLineItemModel(
      id: dbItem.id,
      saleId: dbItem.saleId,
      productId: dbItem.productId,
      productName: dbItem.productName,
      sku: dbItem.sku,
      unitPrice: Decimal.parse(dbItem.unitPrice),
      quantity: dbItem.quantity,
      lineTotal: Decimal.parse(dbItem.lineTotal),
    );
  }
}
