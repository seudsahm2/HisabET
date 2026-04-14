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
    String unit = 'pcs',
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
}

class ProductsRepositoryImpl implements ProductsRepository {
  final AppDatabase _db;

  ProductsRepositoryImpl(this._db);

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final rows = await (_db.select(_db.products)
          ..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    return rows.map(ProductModel.fromDb).toList();
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.isLowStock).toList();
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
    String unit = 'pcs',
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
      unit: unit,
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
    await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(id))).go();
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
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(ProductModel.fromDb).toList());
  }
}
