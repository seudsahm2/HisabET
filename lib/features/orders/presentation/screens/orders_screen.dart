import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/orders/presentation/providers/orders_providers.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/sales/presentation/screens/pos_cart_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

enum OrderFilterStatus { all, pending, processing, delivered, completed, cancelled }

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderFilterStatus _filter = OrderFilterStatus.all;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          final filtered = _applyFilter(orders, _filter);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
              ref.invalidate(recentSalesProvider);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.lg,
              ),
              children: [
                const AppMissionHeader(
                  eyebrow: 'FULFILLMENT',
                  title: 'Order Command',
                  subtitle: 'Track dispatch, delivery, and completion in one lane.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.lg),
                _OrderSnapshotCard(orders: orders),
                const SizedBox(height: AppDimensions.xl),
                _StatusFilterChips(
                  selected: _filter,
                  onChanged: (next) => setState(() => _filter = next),
                ),
                const SizedBox(height: AppDimensions.xl),
                const AppSectionHeader(title: 'Active Fleet', uppercase: true),
                if (filtered.isEmpty)
                  const _EmptyOrdersState()
                else
                  ...filtered.map(
                    (order) => _OrderTile(
                      order: order,
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InvoicePreviewScreen(saleId: order.id)),
                        );
                      },
                      onStatusChange: (status) => _updateOrderStatus(order, status),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final allowed = await _ensureOrderPermission(context, ref, attemptedAction: 'open_new_order_pos');
          if (!allowed) return;
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PosCartScreen()));
          ref.invalidate(ordersProvider);
          ref.invalidate(recentSalesProvider);
        },
      ),
    );
  }

  List<SaleModel> _applyFilter(List<SaleModel> orders, OrderFilterStatus filter) {
    if (filter == OrderFilterStatus.all) return orders;
    final key = filter.name;
    return orders.where((order) => order.status.toLowerCase() == key).toList();
  }

  Future<void> _updateOrderStatus(SaleModel order, String newStatus) async {
    if (order.status.toLowerCase() == newStatus.toLowerCase()) return;

    final allowed = await _ensureOrderPermission(
      context, ref,
      attemptedAction: 'update_order_status',
      entityId: order.id,
    );
    if (!allowed) return;

    await ref.read(salesRepositoryProvider).updateSaleStatus(order.id, newStatus);
    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'order_status_updated',
      entityType: 'order',
      entityId: order.id,
      message: 'Order ${order.id} status changed from ${order.status} to $newStatus.',
    );

    ref.invalidate(ordersProvider);
    ref.invalidate(recentSalesProvider);
    ref.invalidate(recentAuditLogsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $newStatus.')));
    }
  }

  Future<bool> _ensureOrderPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: 'order',
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to manage orders.')));
    }
    return false;
  }
}

class _OrderSnapshotCard extends StatelessWidget {
  final List<SaleModel> orders;

  const _OrderSnapshotCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status.toLowerCase() == 'pending').length;
    final processing = orders.where((o) => o.status.toLowerCase() == 'processing').length;
    final openValue = orders
        .where((o) => o.status.toLowerCase() == 'pending' || o.status.toLowerCase() == 'processing')
        .fold<Decimal>(Decimal.zero, (sum, o) => sum + o.total);

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Board', style: AppTextStyles.cardTitle),
              AppStatusBadge.warning(label: '${pending + processing} Active', small: true),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending', style: AppTextStyles.cardSubtitle),
                    Text('$pending Tasks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Processing', style: AppTextStyles.cardSubtitle),
                    Text('$processing Active', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pipeline Value', style: AppTextStyles.cardSubtitle),
                    AppAmountText(amount: openValue.toString(), fontSize: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  final OrderFilterStatus selected;
  final ValueChanged<OrderFilterStatus> onChanged;

  const _StatusFilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppFilterChips<OrderFilterStatus>(
      options: OrderFilterStatus.values,
      selected: selected,
      labelBuilder: (status) {
        final raw = status.name;
        // Capitalize first letter
        return raw[0].toUpperCase() + raw.substring(1);
      },
      onSelected: onChanged,
    );
  }
}

class _OrderTile extends StatelessWidget {
  final SaleModel order;
  final VoidCallback onOpen;
  final ValueChanged<String> onStatusChange;

  const _OrderTile({
    required this.order,
    required this.onOpen,
    required this.onStatusChange,
  });

  Widget _buildMappedBadge(String status) {
    final lower = status.toLowerCase();
    switch (lower) {
      case 'pending':
        return AppStatusBadge.warning(label: 'Pending', small: true);
      case 'processing':
        return AppStatusBadge.neutral(label: 'Processing', small: true);
      case 'delivered':
        return AppStatusBadge.success(label: 'Delivered', small: true);
      case 'completed':
        return AppStatusBadge.success(label: 'Completed', small: true);
      case 'cancelled':
        return AppStatusBadge.danger(label: 'Cancelled', small: true);
      default:
        return AppStatusBadge.neutral(label: status.toUpperCase(), small: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLower = order.status.toLowerCase();
    final due = order.total - order.paidAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: AppListTile(
        onTap: onOpen,
        leadingIcon: Icons.local_shipping_rounded,
        leadingColor: AppColors.moduleOrders,
        title: order.customerName?.trim().isNotEmpty == true ? order.customerName! : 'Walk-in Order',
        subtitle: '${DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt)}\nDue: ETB $due',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMappedBadge(statusLower),
                const SizedBox(height: 4),
                AppAmountText(amount: order.total.toString(), fontSize: 13, isPositive: null),
              ],
            ),
            const SizedBox(width: AppDimensions.sm),
            PopupMenuButton<String>(
              tooltip: 'Order actions',
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'open') {
                  onOpen();
                } else {
                  onStatusChange(value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Text('Open invoice preview')),
                const PopupMenuDivider(),
                _statusItem('pending', statusLower),
                _statusItem('processing', statusLower),
                _statusItem('delivered', statusLower),
                _statusItem('completed', statusLower),
                _statusItem('cancelled', statusLower),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _statusItem(String status, String current) {
    final capitalized = status[0].toUpperCase() + status.substring(1);
    final label = current == status ? '$capitalized (Current)' : 'Mark $capitalized';
    return PopupMenuItem(value: status, child: Text(label));
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.list_alt_rounded,
      title: 'No matched orders',
      subtitle: 'New orders processed through the POS will appear within the pipeline.',
    );
  }
}
