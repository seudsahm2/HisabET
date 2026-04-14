import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/data/repositories/sales_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesRepositoryImpl(db);
});

final recentSalesProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getRecentSales();
});
