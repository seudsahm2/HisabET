import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/customers/presentation/providers/customers_providers.dart';
import 'package:hisabet/features/customers/presentation/screens/customer_profile_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(contactProvider(customerId));
    final txAsync = ref.watch(contactTransactionsProvider(customerId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('CRM Profile Overview'),
        actions: [
          customerAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (customer) {
              if (customer == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final allowed = await _ensureCustomerPermission(context, ref, attemptedAction: 'open_edit_customer_profile', entityId: customer.id);
                  if (!allowed) return;
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerProfileUpsertScreen(customerToEdit: customer)));
                  ref.invalidate(customerContactsProvider);
                  ref.invalidate(contactProvider(customerId));
                },
              );
            },
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (customer) {
          if (customer == null) return const AppEmptyState(icon: Icons.error_outline_rounded, title: 'Profile Not Found', subtitle: 'This customer may have been deleted.');

          final receivable = customer.netBalance > Decimal.zero ? customer.netBalance : Decimal.zero;
          final utilization = customer.creditLimit > Decimal.zero ? (receivable.toDouble() / customer.creditLimit.toDouble()) : 0.0;
          final clampedUtil = utilization.clamp(0.0, 1.0);

          return txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (transactions) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(contactProvider(customerId));
                  ref.invalidate(contactTransactionsProvider(customerId));
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
                  children: [
                    _buildProfileHeader(customer),
                    const SizedBox(height: AppDimensions.xl),
                    _buildCreditCard(customer.creditLimit, receivable, clampedUtil),
                    const SizedBox(height: AppDimensions.md),
                    _buildLoyaltyCard(context, ref, customer),
                    const SizedBox(height: AppDimensions.xl),
                    _buildStatementCard(transactions),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ContactModel customer) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            child: Text(customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.primary)),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                  Text(customer.phoneNumber!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(Decimal limit, Decimal receivable, double utilization) {
    final overLimit = receivable > limit && limit > Decimal.zero;
    final percent = (utilization * 100).toStringAsFixed(0);

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Credit Line', style: AppTextStyles.cardTitle),
              if (overLimit) AppStatusBadge.danger(label: 'LIMIT EXCEEDED', small: true),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(child: _buildStatBlock('Receivable Owed', 'ETB $receivable', AppColors.positive)),
              Expanded(child: _buildStatBlock('Ceiling Limit', 'ETB $limit', AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilization,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(overLimit ? AppColors.negative : AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('Utilization: $percent%', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard(BuildContext context, WidgetRef ref, ContactModel customer) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loyalty Network', style: AppTextStyles.cardTitle),
                Text('${customer.loyaltyPoints} points', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.warning)),
              ],
            ),
          ),
          IconButton(onPressed: () => _adjustLoyalty(context, ref, customer, -10), icon: const Icon(Icons.remove_circle_rounded, color: AppColors.textSecondary)),
          IconButton(onPressed: () => _adjustLoyalty(context, ref, customer, 10), icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildStatementCard(List<TransactionModel> transactions) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction Activity', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppDimensions.md),
          if (transactions.isEmpty)
            const Text('No ledger statements captured.', style: TextStyle(color: AppColors.textSecondary))
          else
            ...transactions.take(8).map((tx) {
              final isPositive = tx.balanceEffect >= Decimal.zero;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16, color: isPositive ? AppColors.positive : AppColors.negative),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.description ?? tx.type.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(DateFormat('MMM d, yyyy').format(tx.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text('ETB ${tx.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Future<void> _adjustLoyalty(BuildContext context, WidgetRef ref, ContactModel customer, int delta) async {
    final allowed = await _ensureCustomerPermission(context, ref, attemptedAction: delta > 0 ? 'add_loyalty_points' : 'redeem_loyalty_points', entityId: customer.id);
    if (!allowed) return;

    final contactsRepo = ref.read(contactsRepositoryProvider);
    final nextPoints = (customer.loyaltyPoints + delta) < 0 ? 0 : customer.loyaltyPoints + delta;
    await contactsRepo.updateCustomerProfile(id: customer.id, name: customer.name, phone: customer.phoneNumber, shop: customer.shopNumber, creditLimit: customer.creditLimit, loyaltyPoints: nextPoints);

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'customer_loyalty_updated', entityType: 'customer', entityId: customer.id, message: 'Loyalty points changed by $delta for ${customer.name}.');

    ref.invalidate(contactProvider(customerId));
    ref.invalidate(customerContactsProvider);
    ref.invalidate(recentAuditLogsProvider);
  }

  Future<bool> _ensureCustomerPermission(BuildContext context, WidgetRef ref, {required String attemptedAction, String? entityId}) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'permission_denied', entityType: 'customer', entityId: entityId, message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}
