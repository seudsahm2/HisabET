import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/home/presentation/providers/dashboard_providers.dart';
import 'package:hisabet/features/home/presentation/screens/merchant_modules_screen.dart';
import 'package:hisabet/features/inventory/presentation/screens/products_list_screen.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/core/l10n/language_provider.dart';

// Navigation targets
import 'package:hisabet/features/inventory/presentation/screens/product_upsert_screen.dart';
import 'package:hisabet/features/sales/presentation/screens/pos_cart_screen.dart';
import 'package:hisabet/features/expenses/presentation/screens/expense_upsert_screen.dart';
import 'package:hisabet/features/reports/presentation/screens/reports_screen.dart';

import 'package:intl/intl.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          _HomeDashboard(),
          ContactsListScreen(), // Will be renamed to Ledger in future phases
          ProductsListScreen(), // The Inventory
          MerchantModulesScreen(), // The Business Hub
          _ProfileTab(), // Replaced Menu Tab
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigate,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Ledger',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_center_outlined),
              selectedIcon: Icon(Icons.business_center_rounded),
              label: 'Business',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppDimensions.lg, AppDimensions.lg, AppDimensions.lg, AppDimensions.sm),
              child: _DashboardHeader(),
            ),
          ),

          // Premium gradient hero card
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => AppGradientCard(
                label: 'TOTAL NET BALANCE',
                value: 'ETB ${stats.netBalance}',
                backgroundIcon: Icons.account_balance_wallet,
                children: [
                  AppGradientCardStatRow(
                    leftLabel: 'To Collect',
                    leftValue: 'ETB ${stats.totalReceivable}',
                    rightLabel: 'To Pay',
                    rightValue: 'ETB ${stats.totalPayable.abs()}',
                  ),
                ],
              ),
              loading: () => Container(
                height: 180,
                margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => const SizedBox(),
            ),
          ),

          // Quick Actions
          const SliverToBoxAdapter(child: _PremiumQuickActions()),

          // Recent Activity Header
          const SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Recent Activity',
              actionLabel: 'See All',
            ),
          ),

          // Activity List
          activityAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Recent Activity',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = transactions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
                    child: _PremiumTransactionTile(transaction: tx),
                  );
                }, childCount: transactions.length),
              );
            },
            loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
            error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: AppTextStyles.sectionLabel,
            ),
            const SizedBox(height: 4),
            Text("Hello, Merchant", style: AppTextStyles.headlineSmall),
          ],
        ),
        Container(
          width: AppDimensions.avatarMd,
          height: AppDimensions.avatarMd,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _PremiumQuickActions extends ConsumerWidget {
  const _PremiumQuickActions();

  void _showComingSoon(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName will be available in the next major update! 🚀'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            context: context,
            icon: Icons.person_add,
            label: "Add Contact",
            bg: AppColors.infoLight,
            iconColor: AppColors.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddContactScreen()),
              );
            },
          ),
          _buildActionItem(
            context: context,
            icon: Icons.inventory_2,
            label: "Add Product",
            bg: AppColors.positiveLight,
            iconColor: AppColors.positive,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductUpsertScreen()),
              );
            },
          ),
          _buildActionItem(
            context: context,
            icon: Icons.receipt_long,
            label: "Add Expense",
            bg: AppColors.negativeLight,
            iconColor: AppColors.negative,
            onTap: () => _showComingSoon(context, 'Expense Tracking'),
          ),
          _buildActionItem(
            context: context,
            icon: Icons.bar_chart,
            label: "Reports",
            bg: AppColors.warningLight,
            iconColor: AppColors.warning,
            onTap: () => _showComingSoon(context, 'Analytics & Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.badgeLabel.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _PremiumTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.balanceEffect.toDouble() >= 0;

    return AppListTile(
      leadingIcon: isPositive ? Icons.arrow_downward : Icons.arrow_upward,
      leadingColor: isPositive ? AppColors.positive : AppColors.negative,
      title: transaction.description ?? "Untitled",
      subtitle: DateFormat('MMM d • h:mm a').format(transaction.date),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAmountText(
            amount: transaction.amount.toString(),
            isPositive: isPositive,
            showSign: true,
          ),
          const SizedBox(height: 4),
          AppStatusBadge.success(label: 'Completed', small: true),
        ],
      ),
      onTap: () {},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings & Tools", style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppDimensions.xxxl),
            
              AppFormSection(
                title: "General",
                icon: Icons.tune,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: const Text("Language / ቋንቋ"),
                    subtitle: const Text("English / አማርኛ"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageSheet(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.security, color: AppColors.primary),
                    title: const Text("Permissions"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: AppColors.negative),
                    title: const Text("Logout", style: TextStyle(color: AppColors.negative)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                    },
                  ),
                ],
              ),
            
            const SizedBox(height: AppDimensions.xl),
            
            AppFormSection(
              title: "Developer",
              icon: Icons.bug_report,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.terminal, color: AppColors.primary),
                  title: const Text("Debug Tools"),
                  subtitle: const Text("Reconciliation & Logs"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Language", style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.xxl),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
              ),
              title: const Text("English", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Default"),
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("🇪🇹", style: TextStyle(fontSize: 24)),
              ),
              title: const Text("Amharic", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("አማርኛ"),
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(const Locale('am'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
