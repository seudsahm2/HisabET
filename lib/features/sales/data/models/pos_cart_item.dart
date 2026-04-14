import 'package:decimal/decimal.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';

class PosCartItem {
  final ProductModel product;
  final int quantity;

  const PosCartItem({required this.product, required this.quantity});

  Decimal get lineTotal => product.sellingPrice * Decimal.fromInt(quantity);

  PosCartItem copyWith({ProductModel? product, int? quantity}) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
