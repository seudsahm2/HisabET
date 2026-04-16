import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

// Screens
import 'package:hisabet/features/cashbook/presentation/screens/cashbook_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:hisabet/features/customers/presentation/screens/customers_screen.dart';
import 'package:hisabet/features/inventory/presentation/screens/products_list_screen.dart';
import 'package:hisabet/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:hisabet/features/orders/presentation/screens/orders_screen.dart';
import 'package:hisabet/features/promotions/presentation/screens/promotions_screen.dart';
import 'package:hisabet/features/settings/presentation/screens/settings_screen.dart';
import 'package:hisabet/features/reports/presentation/screens/reports_screen.dart';
import 'package:hisabet/features/purchases/presentation/screens/purchase_orders_screen.dart';
import 'package:hisabet/features/sales/presentation/screens/pos_cart_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/team/presentation/screens/team_management_screen.dart';
import 'package:hisabet/features/suppliers/presentation/screens/suppliers_list_screen.dart';

class MerchantModulesScreen extends ConsumerWidget {
  const MerchantModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─────────────────────────────────────────────────────────────
            // Header & Pulse Bar
            // ─────────────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppDimensions.lg, AppDimensions.lg,
                    AppDimensions.lg, AppDimensions.sm),
                child: Text(
                  "Business Hub",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AppPulseBar(
                chips: [
                  AppPulseChip(
                    icon: Icons.warning_amber_rounded,
                    label: '3 items low stock',
                    color: AppColors.warning,
                  ),
                  AppPulseChip(
                    icon: Icons.access_time_filled,
                    label: '2 pending orders',
                    color: AppColors.info,
                  ),
                  AppPulseChip(
                    icon: Icons.receipt_long,
                    label: '1 unpaid bill',
                    color: AppColors.negative,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.lg)),

            // ─────────────────────────────────────────────────────────────
            // Daily Operations (Priority Cards)
            // ─────────────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Daily Operations',
                uppercase: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppDimensions.md,
                crossAxisSpacing: AppDimensions.md,
                childAspectRatio: 1.1,
                children: [
                  AppModuleCard.priority(
                    title: 'Sales (POS)',
                    subtitle: 'Point of sale, invoices & carts',
                    icon: Icons.point_of_sale,
                    color: AppColors.moduleSales,
                    onTap: () => _navigate(context, ref, 'Sales', const PosCartScreen()),
                  ),
                  AppModuleCard.priority(
                    title: 'Inventory',
                    subtitle: 'Products, stock levels & SKUs',
                    icon: Icons.inventory_2,
                    color: AppColors.moduleInventory,
                    onTap: () => _navigate(context, ref, 'Inventory', const ProductsListScreen()),
                  ),
                  AppModuleCard.priority(
                    title: 'Orders',
                    subtitle: 'Manage fulfillment & delivery',
                    icon: Icons.list_alt,
                    color: AppColors.moduleOrders,
                    onTap: () => _navigate(context, ref, 'Orders', const OrdersScreen()),
                    badge: const AppStatusBadgeData(label: '2 New', color: AppColors.info),
                  ),
                  AppModuleCard.priority(
                    title: 'Purchases',
                    subtitle: 'Supplier bills & buying',
                    icon: Icons.shopping_cart,
                    color: AppColors.modulePurchases,
                    onTap: () => _navigate(context, ref, 'Purchases', const PurchaseOrdersScreen()),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // Finance & Tracking (Compact Cards)
            // ─────────────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Finance & Tracking',
                uppercase: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppModuleCard.compact(
                    title: 'Expenses',
                    subtitle: 'Operating costs and recurring bills',
                    icon: Icons.receipt_long,
                    color: AppColors.moduleExpenses,
                    onTap: () => _navigate(context, ref, 'Expenses', const ExpensesScreen()),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleCard.compact(
                    title: 'Cashbook',
                    subtitle: 'Daily cash and bank reconciliation',
                    icon: Icons.account_balance_wallet,
                    color: AppColors.moduleCashbook,
                    onTap: () => _navigate(context, ref, 'Cashbook', const CashbookScreen()),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleCard.compact(
                    title: 'Reports',
                    subtitle: 'Profits, trends and analytics',
                    icon: Icons.bar_chart,
                    color: AppColors.moduleReports,
                    onTap: () => _navigate(context, ref, 'Reports', const ReportsScreen()),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // People & Relationships
            // ─────────────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'People & Relationships',
                uppercase: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: AppModuleCard.compact(
                          title: 'Customers',
                          subtitle: 'CRM',
                          icon: Icons.groups,
                          color: AppColors.moduleCustomers,
                          onTap: () => _navigate(context, ref, 'Customers', const CustomersScreen()),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: AppModuleCard.compact(
                          title: 'B2B Tenders',
                          subtitle: 'Global supply bids',
                          icon: Icons.storefront_rounded,
                          color: AppColors.moduleSuppliers,
                          onTap: () => _navigate(context, ref, 'Suppliers', const SuppliersListScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppModuleCard.compact(
                          title: 'Promotions',
                          subtitle: 'Coupons',
                          icon: Icons.local_offer,
                          color: AppColors.modulePromotions,
                          onTap: () => _navigate(context, ref, 'Promotions', const PromotionsScreen()),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: AppModuleCard.compact(
                          title: 'Team',
                          subtitle: 'Staff info',
                          icon: Icons.badge,
                          color: AppColors.moduleTeam,
                          onTap: () => _navigate(context, ref, 'Team', const TeamManagementScreen()),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // Administration
            // ─────────────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Administration',
                uppercase: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverToBoxAdapter(
                child: AppModuleCard.compact(
                  title: 'Store Settings',
                  subtitle: 'Taxes, invoices and business profile',
                  icon: Icons.settings,
                  color: AppColors.moduleSettings,
                  onTap: () => _navigate(context, ref, 'Settings', const SettingsScreen()),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // Permission handling wrapper
  Future<void> _navigate(
      BuildContext context, WidgetRef ref, String moduleTitle, Widget screen) async {
    final allowed = await _ensureModulePermission(context, ref, moduleTitle);
    if (!allowed) return;
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<bool> _ensureModulePermission(
    BuildContext context,
    WidgetRef ref,
    String moduleTitle,
  ) async {
    TeamPermission? requiredPermission;

    switch (moduleTitle) {
      case 'Inventory':
        requiredPermission = TeamPermission.manageInventory;
        break;
      case 'Sales':
      case 'Customers':
      case 'Orders':
      case 'Promotions':
        requiredPermission = TeamPermission.processSales;
        break;
      case 'Settings':
        requiredPermission = TeamPermission.manageTeam;
        break;
      case 'Purchases':
      case 'Suppliers':
        requiredPermission = TeamPermission.managePurchases;
        break;
      case 'Expenses':
        requiredPermission = TeamPermission.manageExpenses;
        break;
      case 'Reports':
      case 'Cashbook':
        requiredPermission = TeamPermission.viewReports;
        break;
      case 'Team':
        // Always allow Team so users can switch session role. Mutable actions protected inside.
        requiredPermission = null;
        break;
      default:
        requiredPermission = null;
    }

    if (requiredPermission == null) return true;

    final allowed = ref.read(hasPermissionProvider(requiredPermission));
    if (allowed) return true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You do not have access to $moduleTitle module.'),
          backgroundColor: AppColors.negative,
        ),
      );
    }
    return false;
  }
}
