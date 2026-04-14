import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class PurchaseOrderLineItemModel {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int? itemsPerCarton;
  final Decimal unitCost;
  final int quantity;
  final Decimal lineTotal;
  final DateTime createdAt;

  const PurchaseOrderLineItemModel({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    this.itemsPerCarton,
    required this.unitCost,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });

  factory PurchaseOrderLineItemModel.fromDb(PurchaseOrderLineItem row) {
    return PurchaseOrderLineItemModel(
      id: row.id,
      purchaseOrderId: row.purchaseOrderId,
      productId: row.productId,
      productName: row.productName,
      sku: row.sku,
      unit: row.unit,
      itemsPerCarton: row.itemsPerCarton,
      unitCost: Decimal.parse(row.unitCost),
      quantity: row.quantity,
      lineTotal: Decimal.parse(row.lineTotal),
      createdAt: row.createdAt,
    );
  }

  PurchaseOrderLineItemsCompanion toDbCompanion() {
    return PurchaseOrderLineItemsCompanion.insert(
      id: id,
      purchaseOrderId: purchaseOrderId,
      productId: productId,
      productName: productName,
      sku: drift.Value(sku),
      unit: drift.Value(unit),
      itemsPerCarton: drift.Value(itemsPerCarton),
      unitCost: unitCost.toString(),
      quantity: quantity,
      lineTotal: lineTotal.toString(),
      createdAt: createdAt,
    );
  }
}

class PurchaseOrderLineInput {
  final String productId;
  final String productName;
  final String? sku;
  final String? unit;
  final int? itemsPerCarton;
  final Decimal unitCost;
  final int quantity;
  final Decimal lineTotal;

  const PurchaseOrderLineInput({
    required this.productId,
    required this.productName,
    this.sku,
    this.unit,
    this.itemsPerCarton,
    required this.unitCost,
    required this.quantity,
    required this.lineTotal,
  });

  PurchaseOrderLineItemModel toModel({required String purchaseOrderId}) {
    return PurchaseOrderLineItemModel(
      id: const Uuid().v4(),
      purchaseOrderId: purchaseOrderId,
      productId: productId,
      productName: productName,
      sku: sku,
      unit: unit,
      itemsPerCarton: itemsPerCarton,
      unitCost: unitCost,
      quantity: quantity,
      lineTotal: lineTotal,
      createdAt: DateTime.now(),
    );
  }
}