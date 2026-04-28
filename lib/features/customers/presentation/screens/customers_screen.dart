import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/customers/presentation/providers/customers_providers.dart';
import 'package:hisabet/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:hisabet/features/customers/presentation/screens/customer_profile_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerContactsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (customers) {
          final totalCredit = customers.fold<Decimal>(Decimal.zero, (sum, c) => sum + c.creditLimit);
          final totalReceivable = customers.fold<Decimal>(Decimal.zero, (sum, c) => sum + (c.netBalance > Decimal.zero ? c.netBalance : Decimal.zero));
          final totalLoyalty = customers.fold<int>(0, (sum, c) => sum + c.loyaltyPoints);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerContactsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
              children: [
                const AppMissionHeader(
                  eyebrow: 'CRM FIELD',
                  title: 'Customer Command',
                  subtitle: 'Monitor credit, loyalty, and relationship health.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildSummaryCard(customers.length, totalCredit, totalReceivable, totalLoyalty),
                const SizedBox(height: AppDimensions.xl),
                if (customers.isEmpty)
                  const AppEmptyState(
                    icon: Icons.groups_rounded,
                    title: 'No CRM Profiles',
                    subtitle: 'Create customer profiles to track credit limits and loyalty points.',
                  )
                else
                  ...customers.map((customer) => _buildCustomerTile(context, customer)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Profile'),
        onPressed: () async {
          final allowed = await _ensureCustomerPermission(context, ref, attemptedAction: 'open_add_customer_profile');
          if (!allowed) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerProfileUpsertScreen()));
          ref.invalidate(customerContactsProvider);
        },
      ),
    );
  }

  Widget _buildSummaryCard(int customerCount, Decimal totalCredit, Decimal totalReceivable, int totalLoyalty) {
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
                child: const Icon(Icons.hub_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('CRM Analytics', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerCount.toString(), style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
                    Text('Total Profiles', style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(totalLoyalty.toString(), style: AppTextStyles.headlineSmall.copyWith(color: AppColors.warning)),
                    Text('Loyalty Points Active', style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Est. Receivables', style: AppTextStyles.cardSubtitle),
                Text('ETB $totalReceivable', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.positive)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, ContactModel customer) {
    final isOverLimit = customer.netBalance > customer.creditLimit && customer.creditLimit > Decimal.zero;

    return AppListTile(
      leadingIcon: Icons.person_rounded,
      leadingColor: isOverLimit ? AppColors.negative : AppColors.primary,
      title: customer.name,
      subtitle: 'Credit: ETB ${customer.creditLimit} • Loyalty: ${customer.loyaltyPoints} pts',
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('ETB ${customer.netBalance}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: customer.netBalance > Decimal.zero ? AppColors.positive : null)),
          if (isOverLimit) AppStatusBadge.danger(label: 'LIMIT EXCEEDED', small: true),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)));
      },
    );
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
