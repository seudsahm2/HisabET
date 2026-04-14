import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/purchases/data/models/purchase_order_model.dart';
import 'package:hisabet/features/purchases/presentation/providers/purchase_orders_providers.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_upsert_screen.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Supplier Statement'),
        actions: [
          supplierAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (supplier) {
              if (supplier == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupplierUpsertScreen(supplierToEdit: supplier),
                    ),
                  );
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
            final isOpen = order.status != PurchaseOrderStatus.received &&
                order.status != PurchaseOrderStatus.cancelled;
            final dueDate = order.dueDate;
            return isOpen && dueDate != null && dueDate.isBefore(DateTime.now());
          }).toList();
          final dueSoonOrders = supplierOrders.where((order) {
            final isOpen = order.status != PurchaseOrderStatus.received &&
                order.status != PurchaseOrderStatus.cancelled;
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                contactAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (contact) {
                    if (contact == null) return const SizedBox.shrink();
                    return _SupplierHeaderCard(contact: contact);
                  },
                ),
                const SizedBox(height: 12),
                supplierAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (supplier) {
                    if (supplier == null) return const SizedBox.shrink();
                    final totalDue = supplier.currentBalance;
                    return _BalanceSummaryCard(
                      payableBalance: totalDue,
                      dueOrders: dueOrders,
                      dueSoonOrders: dueSoonOrders,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ReminderCard(dueOrders: dueOrders, dueSoonOrders: dueSoonOrders),
                const SizedBox(height: 12),
                _StatementSection(transactionsAsync: transactionsAsync),
                const SizedBox(height: 12),
                _PurchaseOrdersSection(orders: supplierOrders),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupplierHeaderCard extends StatelessWidget {
  final ContactModel contact;

  const _SupplierHeaderCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final status = switch (contact.verificationStatus) {
      ContactVerificationStatus.verified => ('Verified', AppColors.give, Icons.verified),
      ContactVerificationStatus.pending => (
        'Pending',
        const Color(0xFFB26A00),
        Icons.schedule
      ),
      ContactVerificationStatus.expired => ('Expired', AppColors.take, Icons.cancel_outlined),
      ContactVerificationStatus.unverified => (
        'Unverified',
        AppColors.textSecondary,
        Icons.circle_outlined
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 4),
                if (contact.phoneNumber != null)
                  Text(contact.phoneNumber!, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: status.$1 == 'Unverified'
                        ? Text(
                            status.$1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status.$2,
                            ),
                          )
                        : Icon(status.$3, size: 14, color: status.$2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  final Decimal payableBalance;
  final List<PurchaseOrderModel> dueOrders;
  final List<PurchaseOrderModel> dueSoonOrders;

  const _BalanceSummaryCard({
    required this.payableBalance,
    required this.dueOrders,
    required this.dueSoonOrders,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text('Payable Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Current balance: ETB $payableBalance'),
          Text('Overdue orders: ${dueOrders.length}'),
          Text('Due within 7 days: ${dueSoonOrders.length}'),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final List<PurchaseOrderModel> dueOrders;
  final List<PurchaseOrderModel> dueSoonOrders;

  const _ReminderCard({required this.dueOrders, required this.dueSoonOrders});

  @override
  Widget build(BuildContext context) {
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
          const Text('Due Reminders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (dueOrders.isEmpty && dueSoonOrders.isEmpty)
            const Text('No upcoming supplier due reminders.'),
          if (dueOrders.isNotEmpty) ...[
            const Text('Overdue', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
            const SizedBox(height: 8),
            ...dueOrders.map(
              (order) => _ReminderRow(
                title: 'ETB ${order.subtotal}',
                subtitle: 'Due ${DateFormat('MMM d, yyyy').format(order.dueDate!)}',
                isOverdue: true,
              ),
            ),
          ],
          if (dueSoonOrders.isNotEmpty) ...[
            if (dueOrders.isNotEmpty) const SizedBox(height: 12),
            const Text('Due Soon', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB26A00))),
            const SizedBox(height: 8),
            ...dueSoonOrders.map(
              (order) => _ReminderRow(
                title: 'ETB ${order.subtotal}',
                subtitle: 'Due ${DateFormat('MMM d, yyyy').format(order.dueDate!)}',
                isOverdue: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOverdue;

  const _ReminderRow({
    required this.title,
    required this.subtitle,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
            color: isOverdue ? Colors.redAccent : const Color(0xFFB26A00),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementSection extends StatelessWidget {
  final AsyncValue<List<TransactionModel>> transactionsAsync;

  const _StatementSection({required this.transactionsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
        data: (transactions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statement / Ledger', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const Text('No ledger entries yet.')
              else
                ...transactions.take(8).map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          tx.status == TransactionStatus.confirmed
                              ? Icons.verified
                              : tx.status == TransactionStatus.pending
                                  ? Icons.schedule
                                  : Icons.circle_outlined,
                          size: 16,
                          color: tx.status == TransactionStatus.confirmed
                              ? AppColors.give
                              : const Color(0xFFB26A00),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labelFor(tx),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(tx.date),
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text('${tx.amount}'),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _labelFor(TransactionModel tx) {
    switch (tx.type) {
      case TransactionType.goodsGiven:
        return 'Goods given';
      case TransactionType.goodsTaken:
        return 'Goods taken';
      case TransactionType.paymentGiven:
        return 'Payment given';
      case TransactionType.paymentReceived:
        return 'Payment received';
    }
  }
}

class _PurchaseOrdersSection extends StatelessWidget {
  final List<PurchaseOrderModel> orders;

  const _PurchaseOrdersSection({required this.orders});

  @override
  Widget build(BuildContext context) {
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
          const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const Text('No purchase orders recorded for this supplier.')
          else
            ...orders.take(8).map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      order.status == PurchaseOrderStatus.received
                          ? Icons.check_circle_outline
                          : order.status == PurchaseOrderStatus.draft
                              ? Icons.edit_note
                              : Icons.local_shipping_outlined,
                      size: 16,
                      color: order.status == PurchaseOrderStatus.received
                          ? AppColors.give
                          : const Color(0xFFB26A00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ETB ${order.subtotal}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${DateFormat('MMM d, yyyy').format(order.orderDate)} • ${order.status.name}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
