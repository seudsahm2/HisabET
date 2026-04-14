import 'package:hisabet/core/database/app_database.dart';

class StockMovementModel {
  final String id;
  final String productId;
  final String movementType;
  final int quantityChange;
  final String? note;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantityChange,
    this.note,
    required this.createdAt,
  });

  factory StockMovementModel.fromDb(StockMovement dbMovement) {
    return StockMovementModel(
      id: dbMovement.id,
      productId: dbMovement.productId,
      movementType: dbMovement.movementType,
      quantityChange: dbMovement.quantityChange,
      note: dbMovement.note,
      createdAt: dbMovement.createdAt,
    );
  }

  String get movementLabel {
    switch (movementType) {
      case 'increase':
        return 'Stock in';
      case 'decrease':
        return 'Stock out';
      default:
        return 'Adjustment';
    }
  }
}