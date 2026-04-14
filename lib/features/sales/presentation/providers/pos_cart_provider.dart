import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/sales/data/models/pos_cart_item.dart';

class PosCartState {
  final List<PosCartItem> items;
  final Decimal discount;
  final Decimal tax;

  PosCartState({
    this.items = const [],
    Decimal? discount,
    Decimal? tax,
  })  : discount = discount ?? Decimal.zero,
        tax = tax ?? Decimal.zero;

  Decimal get subtotal =>
      items.fold(Decimal.zero, (sum, item) => sum + item.lineTotal);

  Decimal get total => subtotal - discount + tax;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PosCartState copyWith({
    List<PosCartItem>? items,
    Decimal? discount,
    Decimal? tax,
  }) {
    return PosCartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }
}

class PosCartController extends StateNotifier<PosCartState> {
  PosCartController() : super(PosCartState());

  void addProduct(ProductModel product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    final updated = [...state.items];

    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      updated.add(PosCartItem(product: product, quantity: 1));
    }

    state = state.copyWith(items: updated);
  }

  void increaseQty(String productId) {
    final updated = state.items.map((item) {
      if (item.product.id != productId) return item;
      return item.copyWith(quantity: item.quantity + 1);
    }).toList();

    state = state.copyWith(items: updated);
  }

  void decreaseQty(String productId) {
    final updated = <PosCartItem>[];

    for (final item in state.items) {
      if (item.product.id != productId) {
        updated.add(item);
        continue;
      }

      if (item.quantity > 1) {
        updated.add(item.copyWith(quantity: item.quantity - 1));
      }
    }

    state = state.copyWith(items: updated);
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void setDiscount(Decimal discount) {
    state = state.copyWith(discount: discount < Decimal.zero ? Decimal.zero : discount);
  }

  void setTax(Decimal tax) {
    state = state.copyWith(tax: tax < Decimal.zero ? Decimal.zero : tax);
  }

  void clear() {
    state = PosCartState();
  }
}

final posCartProvider =
    StateNotifierProvider<PosCartController, PosCartState>((ref) {
  return PosCartController();
});
