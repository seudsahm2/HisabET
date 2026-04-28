import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_detail_screen.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class SuppliersListScreen extends ConsumerWidget {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Source: contacts table filtered by role=supplier — NOT the legacy suppliers table.
    final suppliersAsync = ref.watch(supplierContactsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (suppliers) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(supplierContactsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical: AppDimensions.lg),
              children: [
                const AppMissionHeader(
                  eyebrow: 'SUPPLY NETWORK',
                  title: 'Tender Marketplace',
                  subtitle: 'Source suppliers, issue RFQs, and manage vendor flow.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildMarketplaceHub(suppliers),
                const SizedBox(height: AppDimensions.xl),
                const AppSectionHeader(title: 'Active Supplier Network', uppercase: true),
                if (suppliers.isEmpty)
                  const AppEmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No Registered Suppliers',
                    subtitle:
                        'Add supplier contacts to start issuing Request for Quotes (RFQs) and tenders.',
                  )
                else
                  ...suppliers.map((supplier) =>
                      _buildTenderTile(context, ref, supplier)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final allowed = await _ensureManagePurchasesPermission(context, ref,
              attemptedAction: 'open_create_supplier');
          if (!allowed) return;
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddContactScreen(initialRole: ContactRole.supplier),
          ));
          ref.invalidate(supplierContactsProvider);
        },
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Board Supplier',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMarketplaceHub(List<ContactModel> suppliers) {
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
                  color: AppColors.moduleSuppliers.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.candlestick_chart_rounded,
                    color: AppColors.moduleSuppliers),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Marketplace Analytics', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${suppliers.length}',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.primary)),
                    Text('Active Vendors', style: AppTextStyles.badgeLabel),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suppliers
                          .where((s) => s.netBalance < Decimal.zero)
                          .length
                          .toString(),
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.negative),
                    ),
                    Text('With Payables', style: AppTextStyles.badgeLabel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenderTile(
      BuildContext context, WidgetRef ref, ContactModel supplier) {
    final isVerified =
        supplier.verificationStatus == ContactVerificationStatus.verified;

    return AppListTile(
      leadingIcon: Icons.storefront_rounded,
      leadingColor: AppColors.moduleSuppliers,
      title: supplier.name,
      subtitle: supplier.phoneNumber ?? 'No phone on record',
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SupplierDetailScreen(supplierId: supplier.id)));
      },
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isVerified)
            AppStatusBadge.success(label: 'Verified', small: true)
          else
            AppStatusBadge.neutral(label: 'Unverified', small: true),
        ],
      ),
    );
  }

  Future<bool> _ensureManagePurchasesPermission(
      BuildContext context, WidgetRef ref,
      {required String attemptedAction, String? entityId}) async {
    final allowed =
        ref.read(hasPermissionProvider(TeamPermission.managePurchases));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
        actorRole: actorRole,
        action: 'permission_denied',
        entityType: 'supplier',
        entityId: entityId,
        message: 'Denied $attemptedAction for role ${actorRole.name}.');
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied.')));
    return false;
  }
}