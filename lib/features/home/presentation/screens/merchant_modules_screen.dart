import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

// Screens
import 'package:hisabet/features/cashbook/presentation/screens/cashbook_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH, AppDimensions.lg,
                    AppDimensions.pagePaddingH, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Business Hub",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "All your tools in one place",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pulse / Alert Bar ───────────────────────────────────────────
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
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // SECTION: Daily Operations  — 2-column hero grid
            // ─────────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionLabel(label: 'Daily Operations'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0,
                  AppDimensions.pagePaddingH, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.md,
                  mainAxisSpacing: AppDimensions.md,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate([
                  AppModuleTile.hero(
                    title: 'Sales',
                    description: 'POS · Invoices · Carts',
                    icon: Icons.point_of_sale_rounded,
                    accentColor: AppColors.moduleSales,
                    onTap: () => _showComingSoon(context, 'Sales & POS'),
                  ),
                  if (kDebugMode)
                    AppModuleTile.hero(
                      title: 'Inventory',
                      description: 'Products · Stock · SKUs',
                      icon: Icons.inventory_2_rounded,
                      accentColor: AppColors.moduleInventory,
                      onTap: () => _navigate(context, ref, 'Inventory', const ProductsListScreen()),
                      badge: const AppStatusBadgeData(label: 'DEV ONLY', color: AppColors.negative),
                    ),
                  AppModuleTile.hero(
                    title: 'Orders',
                    description: 'Fulfillment · Delivery',
                    icon: Icons.receipt_rounded,
                    accentColor: AppColors.moduleOrders,
                    onTap: () => _showComingSoon(context, 'Order Fulfillment'),
                  ),
                  AppModuleTile.hero(
                    title: 'Purchases',
                    description: 'Supplier bills · Buying',
                    icon: Icons.shopping_bag_rounded,
                    accentColor: AppColors.modulePurchases,
                    onTap: () => _showComingSoon(context, 'Purchasing'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // SECTION: Finance & Tracking  — vertical compact list
            // ─────────────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(label: 'Finance & Tracking')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppModuleTile.compact(
                    title: 'Expenses',
                    description: 'Operating costs & recurring bills',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.moduleExpenses,
                    onTap: () => _showComingSoon(context, 'Expense Tracking'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleTile.compact(
                    title: 'Cashbook',
                    description: 'Daily cash & bank reconciliation',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.moduleCashbook,
                    onTap: () => _showComingSoon(context, 'Cashbook'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleTile.compact(
                    title: 'Reports',
                    description: 'Profits, trends & analytics',
                    icon: Icons.bar_chart_rounded,
                    accentColor: AppColors.moduleReports,
                    onTap: () => _showComingSoon(context, 'Analytics & Reports'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // SECTION: People & Relationships — 2-column compact grid
            // ─────────────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(label: 'People & Relationships')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.md,
                  mainAxisSpacing: AppDimensions.md,
                  childAspectRatio: 2.4,
                ),
                delegate: SliverChildListDelegate([
                  AppModuleTile.compact(
                    title: 'Customers',
                    description: 'CRM & loyalty',
                    icon: Icons.groups_rounded,
                    accentColor: AppColors.moduleCustomers,
                    onTap: () => _showComingSoon(context, 'Customer CRM'),
                  ),
                  AppModuleTile.compact(
                    title: 'B2B Tenders',
                    description: 'Global supply bids',
                    icon: Icons.handshake_rounded,
                    accentColor: AppColors.moduleSuppliers,
                    onTap: () => _showComingSoon(context, 'Supplier Network'),
                  ),
                  AppModuleTile.compact(
                    title: 'Promotions',
                    description: 'Coupons & offers',
                    icon: Icons.local_offer_rounded,
                    accentColor: AppColors.modulePromotions,
                    onTap: () => _showComingSoon(context, 'Promotions Manager'),
                  ),
                  AppModuleTile.compact(
                    title: 'Team',
                    description: 'Staff & roles',
                    icon: Icons.badge_rounded,
                    accentColor: AppColors.moduleTeam,
                    onTap: () => _showComingSoon(context, 'Team Management'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ─────────────────────────────────────────────────────────────
            // SECTION: Administration
            // ─────────────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _SectionLabel(label: 'Administration')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverToBoxAdapter(
                child: AppModuleTile.compact(
                  title: 'Store Settings',
                  description: 'Taxes, invoices & business profile',
                  icon: Icons.settings_rounded,
                  accentColor: AppColors.moduleSettings,
                  onTap: () => _showComingSoon(context, 'Store Settings'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName will be available in the next major update! 🚀'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Permission-aware navigation ──────────────────────────────────────────
  Future<void> _navigate(
      BuildContext context, WidgetRef ref, String moduleTitle, Widget screen) async {
    final allowed = await _ensureModulePermission(context, ref, moduleTitle);
    if (!allowed) return;
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<bool> _ensureModulePermission(
      BuildContext context, WidgetRef ref, String moduleTitle) async {
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

// ── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.sm),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: isDark ? Colors.white30 : AppColors.textHint,
        ),
      ),
    );
  }
}
