import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

enum PromotionDiscountType { fixed, percent }

class PromotionModel {
  final String id;
  final String code;
  final String title;
  final String? description;
  final PromotionDiscountType discountType;
  final Decimal discountValue;
  final Decimal minOrderTotal;
  final Decimal? maxDiscountAmount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int? usageLimit;
  final int usedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromotionModel({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderTotal,
    this.maxDiscountAmount,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    this.usageLimit,
    required this.usedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromotionModel.fromDb(Promotion row) {
    return PromotionModel(
      id: row.id,
      code: row.code,
      title: row.title,
      description: row.description,
      discountType: row.discountType == 'percent'
          ? PromotionDiscountType.percent
          : PromotionDiscountType.fixed,
      discountValue: Decimal.parse(row.discountValue),
      minOrderTotal: Decimal.parse(row.minOrderTotal),
      maxDiscountAmount: row.maxDiscountAmount == null
          ? null
          : Decimal.parse(row.maxDiscountAmount!),
      startsAt: row.startsAt,
      endsAt: row.endsAt,
      isActive: row.isActive,
      usageLimit: row.usageLimit,
      usedCount: row.usedCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PromotionsCompanion toCompanion() {
    return PromotionsCompanion.insert(
      id: id,
      code: code,
      title: title,
      description: drift.Value(description),
      discountType: drift.Value(discountType.name),
      discountValue: discountValue.toString(),
      minOrderTotal: drift.Value(minOrderTotal.toString()),
      maxDiscountAmount: drift.Value(maxDiscountAmount?.toString()),
      startsAt: drift.Value(startsAt),
      endsAt: drift.Value(endsAt),
      isActive: drift.Value(isActive),
      usageLimit: drift.Value(usageLimit),
      usedCount: drift.Value(usedCount),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PromotionApplyResult {
  final bool isValid;
  final String? message;
  final PromotionModel? promotion;
  final Decimal discountAmount;

  const PromotionApplyResult({
    required this.isValid,
    this.message,
    this.promotion,
    required this.discountAmount,
  });

  factory PromotionApplyResult.invalid(String message) {
    return PromotionApplyResult(
      isValid: false,
      message: message,
      promotion: null,
      discountAmount: Decimal.zero,
    );
  }

  factory PromotionApplyResult.valid(
    PromotionModel promotion,
    Decimal discountAmount,
  ) {
    return PromotionApplyResult(
      isValid: true,
      promotion: promotion,
      discountAmount: discountAmount,
    );
  }
}
