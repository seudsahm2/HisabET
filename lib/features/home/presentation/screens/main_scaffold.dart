import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/features/settings/presentation/screens/trash_screen.dart';
import 'package:hisabet/features/settings/presentation/screens/profile_edit_screen.dart';

import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/home/presentation/providers/dashboard_providers.dart';
import 'package:hisabet/features/home/presentation/screens/merchant_modules_screen.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
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
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
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

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final String userName = userProfileAsync.when(
      data: (profile) => profile?.displayName ?? 'Merchant',
      loading: () => 'Merchant',
      error: (_, __) => 'Merchant',
    );

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
            Text("Hello, $userName", style: AppTextStyles.headlineSmall),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
          ),
          child: Builder(
            builder: (ctx) {
              final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
              return Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  image: photoUrl != null
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: photoUrl == null
                    ? Icon(Icons.person, color: AppColors.primary)
                    : null,
              );
            },
          ),
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
            bg: AppColors.neutral200,
            iconColor: AppColors.neutral400,
            disabled: true,
            onTap: () => _showComingSoon(context, 'Expense Tracking'),
          ),
          _buildActionItem(
            context: context,
            icon: Icons.bar_chart,
            label: "Reports",
            bg: AppColors.neutral200,
            iconColor: AppColors.neutral400,
            disabled: true,
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
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: disabled ? [] : [
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
                color: disabled ? AppColors.textHint : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = userProfileAsync.value?.displayName ?? user?.displayName ?? 'Merchant';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppDimensions.xxl),

            // ── Profile Card ───────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 22, color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: AppTextStyles.cardTitle),
                          if (email.isNotEmpty)
                            Text(email, style: AppTextStyles.cardSubtitle),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.xl),

            // ── Account & Data ─────────────────────────────────────────────
            AppFormSection(
              title: 'Account & Data',
              icon: Icons.manage_accounts_outlined,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outlined, color: AppColors.primary),
                  title: const Text('Trash & Recovery'),
                  subtitle: const Text('Restore deleted items (30 days)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.negative),
                  title: const Text('Logout', style: TextStyle(color: AppColors.negative)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                  },
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.xl),

            // ── Inventory Settings ─────────────────────────────────────────
            AppFormSection(
              title: 'Inventory Settings',
              icon: Icons.inventory_2_rounded,
              children: [
                Builder(builder: (context) {
                  final threshold = ref.watch(lowStockThresholdProvider);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    title: const Text('Low Stock Alert Threshold'),
                    subtitle: Text(
                      'Warn when stock ≤ $threshold units',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLowStockDialog(context, ref, threshold),
                  );
                }),
              ],
            ),

            const SizedBox(height: AppDimensions.xxxl),
          ],
        ),
      ),
    );
  }


  void _showLowStockDialog(BuildContext context, WidgetRef ref, int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Alert Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Products with stock at or below this number will be highlighted as low stock across the entire inventory.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Threshold (units)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 0) {
                ref.read(lowStockThresholdProvider.notifier).setThreshold(value);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
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
