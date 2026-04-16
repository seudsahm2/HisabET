import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/purchases/presentation/screens/purchase_order_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allPurchaseOrdersProvider);
    final contactsAsync = ref.watch(allContactsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Purchase Orders'),
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
                  .where((contact) => contact.role == ContactRole.supplier || contact.role == ContactRole.both)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                    vertical: AppDimensions.lg,
                  ),
                  children: [
                    _PurchaseOrdersSummary(orders: orders),
                    const SizedBox(height: AppDimensions.xl),
                    if (orders.isEmpty)
                      const AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No purchase orders yet',
                        subtitle: 'Create a supplier purchase order to track incoming inventory.',
                      )
                    else
                      ...orders.map(
                        (order) => _PurchaseOrderTile(
                          order: order,
                          supplierName: supplierNameById[order.supplierId] ?? 'Unknown Supplier',
                          onTap: () => _openEditOrder(context, ref, order),
                          onStatusSelected: (status) async {
                            final allowed = await _ensureManagePurchasesPermission(
                              context,
                              ref,
                              attemptedAction: 'update_purchase_order_status',
                              entityId: order.id,
                            );
                            if (!allowed) return;

                            await ref
                                .read(purchaseOrdersRepositoryProvider)
                                .updatePurchaseOrderStatus(order.id, status);
                            final actorRole = ref.read(currentRoleProvider);
                            await ref.read(auditRepositoryProvider).logAction(
                              actorRole: actorRole,
                              action: 'purchase_order_status_updated',
                              entityType: 'purchase_order',
                              entityId: order.id,
                              message: 'Purchase order ${order.id} set to ${status.name}.',
                            );
                            ref.invalidate(allPurchaseOrdersProvider);
                            ref.invalidate(recentAuditLogsProvider);
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
        onPressed: () async {
          final allowed = await _ensureManagePurchasesPermission(
            context,
            ref,
            attemptedAction: 'open_new_purchase_order',
          );
          if (!allowed) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PurchaseOrderUpsertScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  Future<void> _openEditOrder(BuildContext context, WidgetRef ref, PurchaseOrderModel order) async {
    final allowed = await _ensureManagePurchasesPermission(
      context,
      ref,
      attemptedAction: 'open_edit_purchase_order',
      entityId: order.id,
    );
    if (!allowed) return;

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PurchaseOrderUpsertScreen(orderToEdit: order),
      ),
    );
  }
}

Future<bool> _ensureManagePurchasesPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  String? entityId,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.managePurchases));
  if (allowed) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref.read(auditRepositoryProvider).logAction(
    actorRole: actorRole,
    action: 'permission_denied',
    entityType: 'purchase_order',
    entityId: entityId,
    message: 'Denied $attemptedAction for role ${actorRole.name}.',
  );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permission denied.')),
    );
  }
  return false;
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

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Purchase Summary', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total Orders', orders.length.toString(), Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Drafts', draftCount.toString(), AppColors.textSecondary),
              ),
              Expanded(
                child: _buildStatItem('Overdue', dueCount.toString(), AppColors.negative),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Value Held', style: AppTextStyles.cardSubtitle),
                Text('ETB $totalValue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color)),
        Text(label, style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
      ],
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
    final isOverdue = order.dueDate != null &&
        order.dueDate!.isBefore(DateTime.now()) &&
        order.status != PurchaseOrderStatus.received &&
        order.status != PurchaseOrderStatus.cancelled;

    final dueLabel = order.dueDate?.toLocal().toString().split(' ').first ?? 'No date';

    Widget statusBadge = switch (order.status) {
      PurchaseOrderStatus.draft => AppStatusBadge.neutral(label: 'DRAFT', small: true),
      PurchaseOrderStatus.ordered => AppStatusBadge.warning(label: 'ORDERED', small: true),
      PurchaseOrderStatus.received => AppStatusBadge.success(label: 'RECEIVED', small: true),
      PurchaseOrderStatus.cancelled => AppStatusBadge.danger(label: 'CANCELLED', small: true),
    };

    if (isOverdue && order.status != PurchaseOrderStatus.draft) {
      statusBadge = AppStatusBadge.danger(label: 'OVERDUE', small: true);
    }

    return AppListTile(
      leadingIcon: Icons.receipt_long_rounded,
      leadingColor: AppColors.primary,
      title: 'ETB ${order.subtotal}',
      subtitle: '$supplierName\nDue: $dueLabel',
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusBadge,
          PopupMenuButton<PurchaseOrderStatus>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint),
            onSelected: onStatusSelected,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            itemBuilder: (context) => const [
              PopupMenuItem(value: PurchaseOrderStatus.ordered, child: Text('Mark Ordered')),
              PopupMenuItem(value: PurchaseOrderStatus.received, child: Text('Mark Received')),
              PopupMenuItem(value: PurchaseOrderStatus.draft, child: Text('Revert to Draft')),
              PopupMenuItem(value: PurchaseOrderStatus.cancelled, child: Text('Cancel Order', style: TextStyle(color: AppColors.negative))),
            ],
          ),
        ],
      ),
    );
  }
}