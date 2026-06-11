import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';
import 'dart:convert';

class ColorSlot {
  final String color;
  final int count;

  const ColorSlot({required this.color, required this.count});

  factory ColorSlot.fromJson(Map<String, dynamic> json) {
    return ColorSlot(
      color: json['color'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'color': color,
        'count': count,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? category;
  final String? brand;
  final String? photoUrl;
  final String unit;
  final int? itemsPerCarton;
  
  // Shoe Batch Fingerprint
  final String? itemNumber;
  final int? sizeFrom;
  final int? sizeTo;
  final int seriesSize;
  final String? colorDistribution; // JSON array of ColorSlot
  final String? containerRef;
  final String? supplierContactId;
  final String businessRole;

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
    this.photoUrl,
    this.unit = 'pcs',
    this.itemsPerCarton,
    this.itemNumber,
    this.sizeFrom,
    this.sizeTo,
    this.seriesSize = 6,
    this.colorDistribution,
    this.containerRef,
    this.supplierContactId,
    this.businessRole = 'retailer',
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
      photoUrl: dbProduct.photoUrl,
      unit: dbProduct.unit,
      itemsPerCarton: dbProduct.itemsPerCarton,
      itemNumber: dbProduct.itemNumber,
      sizeFrom: dbProduct.sizeFrom,
      sizeTo: dbProduct.sizeTo,
      seriesSize: dbProduct.seriesSize,
      colorDistribution: dbProduct.colorDistribution,
      containerRef: dbProduct.containerRef,
      supplierContactId: dbProduct.supplierContactId,
      businessRole: dbProduct.businessRole,
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
    String? photoUrl,
    String? unit,
    int? itemsPerCarton,
    String? itemNumber,
    int? sizeFrom,
    int? sizeTo,
    int? seriesSize,
    String? colorDistribution,
    String? containerRef,
    String? supplierContactId,
    String? businessRole,
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
      photoUrl: photoUrl ?? this.photoUrl,
      unit: unit ?? this.unit,
      itemsPerCarton: itemsPerCarton ?? this.itemsPerCarton,
      itemNumber: itemNumber ?? this.itemNumber,
      sizeFrom: sizeFrom ?? this.sizeFrom,
      sizeTo: sizeTo ?? this.sizeTo,
      seriesSize: seriesSize ?? this.seriesSize,
      colorDistribution: colorDistribution ?? this.colorDistribution,
      containerRef: containerRef ?? this.containerRef,
      supplierContactId: supplierContactId ?? this.supplierContactId,
      businessRole: businessRole ?? this.businessRole,
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
      photoUrl: drift.Value(photoUrl),
      unit: drift.Value(unit),
      itemsPerCarton: drift.Value(itemsPerCarton),
      itemNumber: drift.Value(itemNumber),
      sizeFrom: drift.Value(sizeFrom),
      sizeTo: drift.Value(sizeTo),
      seriesSize: drift.Value(seriesSize),
      colorDistribution: drift.Value(colorDistribution),
      containerRef: drift.Value(containerRef),
      supplierContactId: drift.Value(supplierContactId),
      businessRole: drift.Value(businessRole),
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

  // Helpers
  int get uniqueSizesInSeries => (sizeTo != null && sizeFrom != null)
      ? (sizeTo! - sizeFrom! + 1).clamp(1, seriesSize) : 0;

  int? get repeatedSize => uniqueSizesInSeries < seriesSize ? sizeFrom : null;

  int get totalPiecesInStock {
    if (unit.toLowerCase() == 'carton') {
      return stockQuantity * (itemsPerCarton ?? 1) * seriesSize;
    } else if (unit.toLowerCase() == 'series') {
      return stockQuantity * seriesSize;
    } else {
      return stockQuantity;
    }
  }

  bool get isShoeBundle => itemNumber != null && itemNumber!.isNotEmpty;

  List<ColorSlot> get parsedColorDistribution {
    if (colorDistribution == null || colorDistribution!.isEmpty) return [];
    try {
      final list = jsonDecode(colorDistribution!) as List;
      return list.map((e) => ColorSlot.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
