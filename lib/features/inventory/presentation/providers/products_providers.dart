import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/data/models/stock_movement_model.dart';
import 'package:hisabet/features/inventory/data/repositories/products_repository.dart';

const _kLowStockKey = 'inventory_low_stock_threshold';
const _kDefaultLowStock = 5;

// ── Global low-stock threshold ────────────────────────────────────────────────
class LowStockThresholdNotifier extends Notifier<int> {
  @override
  int build() => _kDefaultLowStock;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_kLowStockKey) ?? _kDefaultLowStock;
  }

  Future<void> setThreshold(int value) async {
    if (value < 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLowStockKey, value);
    state = value;
  }
}

final lowStockThresholdProvider =
    NotifierProvider<LowStockThresholdNotifier, int>(
        LowStockThresholdNotifier.new);

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductsRepositoryImpl(db);
});

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getAllProducts();
});

final lowStockProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  final threshold = ref.watch(lowStockThresholdProvider);
  final all = await repo.getAllProducts();
  return all.where((p) => p.stockQuantity <= threshold).toList();
});

final productProvider =
    StreamProvider.family<ProductModel?, String>((ref, id) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchAllProducts().map((products) {
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  });
});

final productStockMovementsProvider = FutureProvider.family<
    List<StockMovementModel>, String>((ref, productId) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getMovementsForProduct(productId);
});
