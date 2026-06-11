import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/data/models/stock_movement_model.dart';
import 'package:uuid/uuid.dart';

abstract class ProductsRepository {
  Future<List<ProductModel>> getAllProducts();
  Future<List<ProductModel>> getLowStockProducts();
  Future<ProductModel?> getProductById(String id);
  Future<void> addProduct({
    required String name,
    String? sku,
    String? barcode,
    String? category,
    String? brand,
    String? photoUrl,
    String unit = 'pcs',
    int? itemsPerCarton,
    String? itemNumber,
    int? sizeFrom,
    int? sizeTo,
    int seriesSize = 6,
    String? colorDistribution,
    String? containerRef,
    String? supplierContactId,
    String businessRole = 'retailer',
    Decimal? costPrice,
    Decimal? sellingPrice,
    int stockQuantity = 0,
    int reorderLevel = 0,
    bool isActive = true,
  });
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock({required String productId, required int stockDelta});
  Future<void> recordStockMovement({
    required String productId,
    required int quantityChange,
    String movementType,
    String? note,
  });
  Future<List<StockMovementModel>> getMovementsForProduct(String productId);
  Stream<List<ProductModel>> watchAllProducts();

  // Soft-delete extensions
  Future<List<ProductModel>> getDeletedProducts();
  Future<void> restoreProduct(String id);
  Future<void> permanentlyDeleteExpiredProducts({int days = 30});
}

class ProductsRepositoryImpl implements ProductsRepository {
  final AppDatabase _db;

  ProductsRepositoryImpl(this._db);

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map((e) => ProductModel.fromDb(e)).toList();
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) =>
              tbl.isDeleted.equals(false) &
              tbl.stockQuantity.isSmallerOrEqual(tbl.reorderLevel))
          ..orderBy([(t) => OrderingTerm.asc(t.stockQuantity)]))
        .get();
    return rows.map((e) => ProductModel.fromDb(e)).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final row = await (_db.select(_db.products)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ProductModel.fromDb(row);
  }

  @override
  Future<void> addProduct({
    required String name,
    String? sku,
    String? barcode,
    String? category,
    String? brand,
    String? photoUrl,
    String unit = 'pcs',
    int? itemsPerCarton,
    String? itemNumber,
    int? sizeFrom,
    int? sizeTo,
    int seriesSize = 6,
    String? colorDistribution,
    String? containerRef,
    String? supplierContactId,
    String businessRole = 'retailer',
    Decimal? costPrice,
    Decimal? sellingPrice,
    int stockQuantity = 0,
    int reorderLevel = 0,
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final model = ProductModel(
      id: const Uuid().v4(),
      name: name,
      sku: sku,
      barcode: barcode,
      category: category,
      brand: brand,
      photoUrl: photoUrl,
      unit: unit,
      itemsPerCarton: itemsPerCarton,
      itemNumber: itemNumber,
      sizeFrom: sizeFrom,
      sizeTo: sizeTo,
      seriesSize: seriesSize,
      colorDistribution: colorDistribution,
      containerRef: containerRef,
      supplierContactId: supplierContactId,
      businessRole: businessRole,
      costPrice: costPrice ?? Decimal.zero,
      sellingPrice: sellingPrice ?? Decimal.zero,
      stockQuantity: stockQuantity,
      reorderLevel: reorderLevel,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.products).insert(model.toDbCompanion());
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(product.id)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> deleteProduct(String id) async {
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<ProductModel>> getDeletedProducts() async {
    final rows = await (_db.select(_db.products)
          ..where((tbl) => tbl.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
    return rows.map((e) => ProductModel.fromDb(e)).toList();
  }

  @override
  Future<void> restoreProduct(String id) async {
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
      const ProductsCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteExpiredProducts({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final expiredProducts = await (_db.select(_db.products)
          ..where((tbl) =>
              tbl.isDeleted.equals(true) &
              tbl.deletedAt.isSmallerThanValue(cutoff)))
        .get();

    await _db.transaction(() async {
      for (final product in expiredProducts) {
        await (_db.delete(_db.stockMovements)
              ..where((tbl) => tbl.productId.equals(product.id)))
            .go();
        await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(product.id))).go();
      }
    });
  }

  @override
  Future<void> updateStock({
    required String productId,
    required int stockDelta,
  }) async {
    await recordStockMovement(
      productId: productId,
      quantityChange: stockDelta,
      movementType: stockDelta >= 0 ? 'increase' : 'decrease',
    );
  }

  @override
  Future<void> recordStockMovement({
    required String productId,
    required int quantityChange,
    String movementType = 'adjustment',
    String? note,
  }) async {
    final product = await getProductById(productId);
    if (product == null) return;

    final now = DateTime.now();
    final appliedChange = quantityChange < 0
        ? -quantityChange > product.stockQuantity
            ? -product.stockQuantity
            : quantityChange
        : quantityChange;
    final normalizedStock = product.stockQuantity + appliedChange;

    await _db.transaction(() async {
      final updatedProduct = product.copyWith(
        stockQuantity: normalizedStock,
        updatedAt: now,
      );

      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
          .write(updatedProduct.toDbCompanion());

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: const Uuid().v4(),
              productId: productId,
              movementType: movementType,
              quantityChange: appliedChange,
              note: Value(note),
              createdAt: now,
            ),
          );
    });
  }

  @override
  Future<List<StockMovementModel>> getMovementsForProduct(String productId) async {
    final rows = await (_db.select(_db.stockMovements)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(StockMovementModel.fromDb).toList();
  }

  @override
  Stream<List<ProductModel>> watchAllProducts() {
    return (_db.select(_db.products)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map((e) => ProductModel.fromDb(e)).toList());
  }
}
