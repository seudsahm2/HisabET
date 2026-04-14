import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

enum PurchaseOrderStatus {
  draft,
  ordered,
  received,
  cancelled,
}

class PurchaseOrderModel {
  final String id;
  final String supplierId;
  final PurchaseOrderStatus status;
  final Decimal subtotal;
  final DateTime orderDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseOrderModel({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.subtotal,
    required this.orderDate,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrderModel.fromDb(PurchaseOrder dbOrder) {
    return PurchaseOrderModel(
      id: dbOrder.id,
      supplierId: dbOrder.supplierId,
      status: PurchaseOrderStatus.values[dbOrder.status],
      subtotal: Decimal.parse(dbOrder.subtotal),
      orderDate: dbOrder.orderDate,
      dueDate: dbOrder.dueDate,
      notes: dbOrder.notes,
      createdAt: dbOrder.createdAt,
      updatedAt: dbOrder.updatedAt,
    );
  }

  PurchaseOrderModel copyWith({
    String? id,
    String? supplierId,
    PurchaseOrderStatus? status,
    Decimal? subtotal,
    DateTime? orderDate,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      orderDate: orderDate ?? this.orderDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  PurchaseOrdersCompanion toDbCompanion() {
    return PurchaseOrdersCompanion.insert(
      id: id,
      supplierId: supplierId,
      status: drift.Value(status.index),
      subtotal: drift.Value(subtotal.toString()),
      orderDate: orderDate,
      dueDate: drift.Value(dueDate),
      notes: drift.Value(notes),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}