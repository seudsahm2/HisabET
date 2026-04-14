import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/sales/data/models/sale_line_item_model.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/data/repositories/sales_repository.dart';

class SaleInvoiceData {
  final SaleModel sale;
  final List<SaleLineItemModel> lineItems;

  const SaleInvoiceData({required this.sale, required this.lineItems});
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesRepositoryImpl(db);
});

final recentSalesProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getRecentSales();
});

final saleInvoiceProvider = FutureProvider.family<SaleInvoiceData, String>((ref, saleId) async {
  final repo = ref.watch(salesRepositoryProvider);
  final sale = await repo.getSaleById(saleId);
  if (sale == null) {
    throw Exception('Sale not found');
  }

  final lineItems = await repo.getSaleLineItems(saleId);
  return SaleInvoiceData(sale: sale, lineItems: lineItems);
});
