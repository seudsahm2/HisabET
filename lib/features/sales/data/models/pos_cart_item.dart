import 'package:decimal/decimal.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';

class PosCartItem {
  final ProductModel product;
  final int quantity;

  const PosCartItem({required this.product, required this.quantity});

  bool get isBundle =>
      product.unit.toLowerCase() == 'carton' || (product.itemsPerCarton ?? 0) > 0;

  Decimal get pricePerCarton {
    final count = product.itemsPerCarton ?? 0;
    if (count <= 0) return product.sellingPrice;
    return product.sellingPrice * Decimal.fromInt(count);
  }

  Decimal get lineTotal {
    final unitPrice = isBundle ? pricePerCarton : product.sellingPrice;
    return unitPrice * Decimal.fromInt(quantity);
  }

  PosCartItem copyWith({ProductModel? product, int? quantity}) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
