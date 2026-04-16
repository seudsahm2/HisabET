import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

class SupplierDetailScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(supplierId));
    final supplierAsync = ref.watch(supplierProvider(supplierId));
    final transactionsAsync = ref.watch(contactTransactionsProvider(supplierId));
    final ordersAsync = ref.watch(allPurchaseOrdersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('B2B Profile / Tender History'),
        actions: [
          supplierAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (supplier) {
              if (supplier == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final allowed = await _ensureManagePurchasesPermission(context, ref, attemptedAction: 'open_edit_supplier_from_detail', entityId: supplier.id);
                  if (!allowed) return;
                  if (!context.mounted) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupplierUpsertScreen(supplierToEdit: supplier)));
                },
              );
            },
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          final supplierOrders = orders.where((order) => order.supplierId == supplierId).toList();
          final dueOrders = supplierOrders.where((order) {
            final isOpen = order.status != PurchaseOrderStatus.received && order.status != PurchaseOrderStatus.cancelled;
            final dueDate = order.dueDate;
            return isOpen && dueDate != null && dueDate.isBefore(DateTime.now());
          }).toList();
          final dueSoonOrders = supplierOrders.where((order) {
            final isOpen = order.status != PurchaseOrderStatus.received && order.status != PurchaseOrderStatus.cancelled;
            final dueDate = order.dueDate;
            if (!isOpen || dueDate == null) return false;
            final diff = dueDate.difference(DateTime.now()).inDays;
            return diff >= 0 && diff <= 7;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(contactProvider(supplierId));
              ref.invalidate(supplierProvider(supplierId));
              ref.invalidate(contactTransactionsProvider(supplierId));
              ref.invalidate(allPurchaseOrdersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
              children: [
                contactAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (contact) {
                    if (contact == null) return const SizedBox.shrink();
                    return _buildHeaderCard(contact);
                  },
                ),
                const SizedBox(height: AppDimensions.xl),
                supplierAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (supplier) {
                    if (supplier == null) return const SizedBox.shrink();
                    return _buildBalanceCard(supplier.currentBalance, dueOrders, dueSoonOrders);
                  },
                ),
                const SizedBox(height: AppDimensions.xl),
                _buildReminderCard(dueOrders, dueSoonOrders),
                const SizedBox(height: AppDimensions.xl),
                _buildStatementCard(transactionsAsync),
                const SizedBox(height: AppDimensions.xl),
                _buildTendersCard(supplierOrders),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ContactModel contact) {
    final isVerified = contact.verificationStatus == ContactVerificationStatus.verified;
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.moduleSuppliers.withOpacity(0.15),
            child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.moduleSuppliers)),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
                if (contact.phoneNumber != null) Text(contact.phoneNumber!, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (isVerified) AppStatusBadge.success(label: 'Verified Corporate Entity', small: true) else AppStatusBadge.warning(label: 'Unverified Entity', small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Decimal currentBalance, List<PurchaseOrderModel> dueOrders, List<PurchaseOrderModel> dueSoonOrders) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trade Balance', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ETB $currentBalance', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.negative)),
                    Text('Owed Receivable', style: AppTextStyles.badgeLabel),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${dueOrders.length}', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.negative)),
                    Text('Delayed Payments', style: AppTextStyles.badgeLabel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(List<PurchaseOrderModel> dueOrders, List<PurchaseOrderModel> dueSoonOrders) {
    if (dueOrders.isEmpty && dueSoonOrders.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Alerts', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppDimensions.md),
          if (dueOrders.isNotEmpty) ...[
            const Text('Overdue Tenders', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.negative)),
            const SizedBox(height: 8),
            ...dueOrders.map((o) => _buildAlertRow('Tender Value: ETB ${o.subtotal}', 'Due: ${DateFormat('MMM d').format(o.dueDate!)}', true)),
          ],
          if (dueSoonOrders.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            const Text('Pending Execution', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
            const SizedBox(height: 8),
            ...dueSoonOrders.map((o) => _buildAlertRow('Tender Value: ETB ${o.subtotal}', 'Due: ${DateFormat('MMM d').format(o.dueDate!)}', false)),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertRow(String title, String subtitle, bool isError) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(isError ? Icons.warning_rounded : Icons.schedule_rounded, color: isError ? AppColors.negative : AppColors.warning, size: 20),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementCard(AsyncValue<List<TransactionModel>> txAsync) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
        data: (transactions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Market Ledger', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppDimensions.md),
              if (transactions.isEmpty)
                const Text('No transactions mapped to this vendor.', style: TextStyle(color: AppColors.textSecondary))
              else
                ...transactions.take(8).map((tx) {
                  final confirmed = tx.status == TransactionStatus.confirmed;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(confirmed ? Icons.verified_rounded : Icons.pending_rounded, size: 18, color: confirmed ? AppColors.positive : AppColors.warning),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.description ?? tx.type.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(DateFormat('MMM d, yyyy').format(tx.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('ETB ${tx.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTendersCard(List<PurchaseOrderModel> orders) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('B2B Tenders', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppDimensions.md),
          if (orders.isEmpty)
            const Text('No tenders or orders tied to this vendor.', style: TextStyle(color: AppColors.textSecondary))
          else
            ...orders.take(8).map((o) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_rounded, size: 18, color: AppColors.moduleOrders),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ETB ${o.subtotal}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${DateFormat('MMM d, yyyy').format(o.orderDate)} • ${o.status.name.toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<bool> _ensureManagePurchasesPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.managePurchases));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'supplier', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}
