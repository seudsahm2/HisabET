import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/data/models/stock_movement_model.dart';
import 'package:hisabet/features/inventory/data/repositories/products_repository.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductsRepositoryImpl(db);
});

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getAllProducts();
});

final lowStockProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getLowStockProducts();
});

final productProvider = StreamProvider.family<ProductModel?, String>((
  ref,
  id,
) {
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
