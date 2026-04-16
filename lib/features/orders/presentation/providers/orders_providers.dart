import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';

final ordersProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getRecentSales(limit: 500);
});
