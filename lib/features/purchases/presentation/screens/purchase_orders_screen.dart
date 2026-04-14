import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/purchases/presentation/screens/purchase_order_upsert_screen.dart';

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allPurchaseOrdersProvider);
    final contactsAsync = ref.watch(allContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          return contactsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (contacts) {
              final suppliers = contacts
                  .where(
                    (contact) =>
                        contact.role == ContactRole.supplier ||
                        contact.role == ContactRole.both,
                  )
                  .toList();
              final supplierNameById = {
                for (final supplier in suppliers) supplier.id: supplier.name,
              };

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allPurchaseOrdersProvider);
                  ref.invalidate(allContactsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _PurchaseOrdersSummary(orders: orders),
                    const SizedBox(height: 12),
                    if (orders.isEmpty)
                      const _EmptyPurchaseOrdersState()
                    else
                      ...orders.map(
                        (order) => _PurchaseOrderTile(
                          order: order,
                          supplierName: supplierNameById[order.supplierId] ?? 'Unknown Supplier',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PurchaseOrderUpsertScreen(orderToEdit: order),
                              ),
                            );
                          },
                          onStatusSelected: (status) async {
                            await ref
                                .read(purchaseOrdersRepositoryProvider)
                                .updatePurchaseOrderStatus(order.id, status);
                            ref.invalidate(allPurchaseOrdersProvider);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PurchaseOrderUpsertScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _PurchaseOrdersSummary extends StatelessWidget {
  final List<PurchaseOrderModel> orders;

  const _PurchaseOrdersSummary({required this.orders});

  @override
  Widget build(BuildContext context) {
    final draftCount = orders.where((order) => order.status == PurchaseOrderStatus.draft).length;
    final dueCount = orders
        .where(
          (order) =>
              order.dueDate != null &&
              order.dueDate!.isBefore(DateTime.now()) &&
              order.status != PurchaseOrderStatus.received &&
              order.status != PurchaseOrderStatus.cancelled,
        )
        .length;
    final totalValue = orders.fold<Decimal>(Decimal.zero, (sum, order) => sum + order.subtotal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Purchase Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Total orders: ${orders.length}'),
          Text('Draft orders: $draftCount'),
          Text('Overdue bills: $dueCount'),
          Text('Purchase value: ETB $totalValue'),
        ],
      ),
    );
  }
}

class _PurchaseOrderTile extends StatelessWidget {
  final PurchaseOrderModel order;
  final String supplierName;
  final VoidCallback onTap;
  final Future<void> Function(PurchaseOrderStatus status) onStatusSelected;

  const _PurchaseOrderTile({
    required this.order,
    required this.supplierName,
    required this.onTap,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (order.status) {
      PurchaseOrderStatus.draft => 'Draft',
      PurchaseOrderStatus.ordered => 'Ordered',
      PurchaseOrderStatus.received => 'Received',
      PurchaseOrderStatus.cancelled => 'Cancelled',
    };
    final isOverdue =
        order.dueDate != null &&
        order.dueDate!.isBefore(DateTime.now()) &&
        order.status != PurchaseOrderStatus.received &&
        order.status != PurchaseOrderStatus.cancelled;
    final dueLabel = order.dueDate?.toLocal().toString().split(' ').first ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
            ),
            title: Text('ETB ${order.subtotal}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supplierName),
                  Text(
                    'Status: $statusLabel • Due: $dueLabel',
                    style: TextStyle(
                      color: isOverdue ? Colors.redAccent : AppColors.textSecondary,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<PurchaseOrderStatus>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  onStatusSelected(value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: PurchaseOrderStatus.ordered,
                    child: Text('Mark Ordered'),
                  ),
                  PopupMenuItem(
                    value: PurchaseOrderStatus.received,
                    child: Text('Mark Received (Goods Receipt)'),
                  ),
                  PopupMenuItem(
                    value: PurchaseOrderStatus.cancelled,
                    child: Text('Cancel Order'),
                  ),
                  PopupMenuItem(
                    value: PurchaseOrderStatus.draft,
                    child: Text('Set Draft'),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPurchaseOrdersState extends StatelessWidget {
  const _EmptyPurchaseOrdersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No purchase orders yet.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Create a supplier purchase order to begin the buying flow.'),
        ],
      ),
    );
  }
}