import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

class ProductModel {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? category;
  final String? brand;
  final String unit;
  final int? itemsPerCarton;
  final Decimal costPrice;
  final Decimal sellingPrice;
  final int stockQuantity;
  final int reorderLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Soft-delete tracking
  final bool isDeleted;
  final DateTime? deletedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.category,
    this.brand,
    this.unit = 'pcs',
    this.itemsPerCarton,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.reorderLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory ProductModel.fromDb(Product dbProduct) {
    return ProductModel(
      id: dbProduct.id,
      name: dbProduct.name,
      sku: dbProduct.sku,
      barcode: dbProduct.barcode,
      category: dbProduct.category,
      brand: dbProduct.brand,
      unit: dbProduct.unit,
      itemsPerCarton: dbProduct.itemsPerCarton,
      costPrice: Decimal.parse(dbProduct.costPrice),
      sellingPrice: Decimal.parse(dbProduct.sellingPrice),
      stockQuantity: dbProduct.stockQuantity,
      reorderLevel: dbProduct.reorderLevel,
      isActive: dbProduct.isActive,
      createdAt: dbProduct.createdAt,
      updatedAt: dbProduct.updatedAt,
      isDeleted: dbProduct.isDeleted,
      deletedAt: dbProduct.deletedAt,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? brand,
    String? unit,
    int? itemsPerCarton,
    Decimal? costPrice,
    Decimal? sellingPrice,
    int? stockQuantity,
    int? reorderLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      itemsPerCarton: itemsPerCarton ?? this.itemsPerCarton,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  ProductsCompanion toDbCompanion() {
    return ProductsCompanion.insert(
      id: id,
      name: name,
      sku: drift.Value(sku),
      barcode: drift.Value(barcode),
      category: drift.Value(category),
      brand: drift.Value(brand),
      unit: drift.Value(unit),
      itemsPerCarton: drift.Value(itemsPerCarton),
      costPrice: drift.Value(costPrice.toString()),
      sellingPrice: drift.Value(sellingPrice.toString()),
      stockQuantity: drift.Value(stockQuantity),
      reorderLevel: drift.Value(reorderLevel),
      isActive: drift.Value(isActive),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: drift.Value(isDeleted),
      deletedAt: drift.Value(deletedAt),
    );
  }

  bool get isLowStock => stockQuantity <= reorderLevel;
}
