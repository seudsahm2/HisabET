import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/purchases/data/models/purchase_order_line_item_model.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/data/repositories/purchase_orders_repository.dart';

final purchaseOrdersRepositoryProvider = Provider<PurchaseOrdersRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PurchaseOrdersRepositoryImpl(db);
});

final allPurchaseOrdersProvider = FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final repo = ref.watch(purchaseOrdersRepositoryProvider);
  return repo.getAllPurchaseOrders();
});

final purchaseOrderLineItemsProvider = FutureProvider.family<List<PurchaseOrderLineItemModel>, String>(
  (ref, purchaseOrderId) async {
    final repo = ref.watch(purchaseOrdersRepositoryProvider);
    return repo.getPurchaseOrderLineItems(purchaseOrderId);
  },
);