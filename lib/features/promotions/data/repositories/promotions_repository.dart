import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/promotions/data/models/promotion_model.dart';
import 'package:uuid/uuid.dart';

abstract class PromotionsRepository {
  Future<List<PromotionModel>> getAllPromotions();
  Future<void> addPromotion({
    required String code,
    required String title,
    String? description,
    required PromotionDiscountType discountType,
    required Decimal discountValue,
    Decimal? minOrderTotal,
    Decimal? maxDiscountAmount,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive = true,
    int? usageLimit,
  });
  Future<void> updatePromotion(PromotionModel promotion);
  Future<void> setPromotionActive(String id, bool isActive);
  Future<PromotionApplyResult> evaluatePromotion({
    required String code,
    required Decimal subtotal,
    DateTime? now,
  });
}

class PromotionsRepositoryImpl implements PromotionsRepository {
  final AppDatabase _db;

  PromotionsRepositoryImpl(this._db);

  @override
  Future<List<PromotionModel>> getAllPromotions() async {
    final rows =
        await (_db.select(_db.promotions)..orderBy([
              (t) => OrderingTerm.desc(t.isActive),
              (t) => OrderingTerm.desc(t.updatedAt),
            ]))
            .get();
    return rows.map(PromotionModel.fromDb).toList();
  }

  @override
  Future<void> addPromotion({
    required String code,
    required String title,
    String? description,
    required PromotionDiscountType discountType,
    required Decimal discountValue,
    Decimal? minOrderTotal,
    Decimal? maxDiscountAmount,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive = true,
    int? usageLimit,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.promotions)
        .insert(
          PromotionsCompanion.insert(
            id: const Uuid().v4(),
            code: code.trim().toUpperCase(),
            title: title.trim(),
            description: Value(
              description?.trim().isEmpty == true ? null : description?.trim(),
            ),
            discountType: Value(discountType.name),
            discountValue: discountValue.toString(),
            minOrderTotal: Value((minOrderTotal ?? Decimal.zero).toString()),
            maxDiscountAmount: Value(maxDiscountAmount?.toString()),
            startsAt: Value(startsAt),
            endsAt: Value(endsAt),
            isActive: Value(isActive),
            usageLimit: Value(usageLimit),
            usedCount: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updatePromotion(PromotionModel promotion) async {
    await (_db.update(
      _db.promotions,
    )..where((t) => t.id.equals(promotion.id))).write(
      PromotionsCompanion(
        code: Value(promotion.code.trim().toUpperCase()),
        title: Value(promotion.title.trim()),
        description: Value(promotion.description),
        discountType: Value(promotion.discountType.name),
        discountValue: Value(promotion.discountValue.toString()),
        minOrderTotal: Value(promotion.minOrderTotal.toString()),
        maxDiscountAmount: Value(promotion.maxDiscountAmount?.toString()),
        startsAt: Value(promotion.startsAt),
        endsAt: Value(promotion.endsAt),
        isActive: Value(promotion.isActive),
        usageLimit: Value(promotion.usageLimit),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setPromotionActive(String id, bool isActive) async {
    await (_db.update(_db.promotions)..where((t) => t.id.equals(id))).write(
      PromotionsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<PromotionApplyResult> evaluatePromotion({
    required String code,
    required Decimal subtotal,
    DateTime? now,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return PromotionApplyResult.invalid('Enter a promo code.');
    }

    final row = await (_db.select(
      _db.promotions,
    )..where((t) => t.code.equals(normalized))).getSingleOrNull();
    if (row == null) {
      return PromotionApplyResult.invalid('Promo code not found.');
    }

    final promotion = PromotionModel.fromDb(row);
    final at = now ?? DateTime.now();

    if (!promotion.isActive) {
      return PromotionApplyResult.invalid('This promo is inactive.');
    }
    if (promotion.startsAt != null && at.isBefore(promotion.startsAt!)) {
      return PromotionApplyResult.invalid('This promo is not active yet.');
    }
    if (promotion.endsAt != null && at.isAfter(promotion.endsAt!)) {
      return PromotionApplyResult.invalid('This promo has expired.');
    }
    if (promotion.usageLimit != null &&
        promotion.usedCount >= promotion.usageLimit!) {
      return PromotionApplyResult.invalid('Promo usage limit reached.');
    }
    if (subtotal < promotion.minOrderTotal) {
      return PromotionApplyResult.invalid(
        'Minimum order is ETB ${promotion.minOrderTotal}.',
      );
    }

    Decimal discount;
    if (promotion.discountType == PromotionDiscountType.percent) {
      final asDouble =
          subtotal.toDouble() * promotion.discountValue.toDouble() / 100;
      discount = Decimal.parse(asDouble.toStringAsFixed(2));
    } else {
      discount = promotion.discountValue;
    }

    if (promotion.maxDiscountAmount != null &&
        discount > promotion.maxDiscountAmount!) {
      discount = promotion.maxDiscountAmount!;
    }

    if (discount > subtotal) {
      discount = subtotal;
    }

    return PromotionApplyResult.valid(promotion, discount);
  }
}
