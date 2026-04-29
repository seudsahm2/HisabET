import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/features/settings/presentation/screens/trash_screen.dart';
import 'package:hisabet/features/settings/presentation/screens/profile_edit_screen.dart';
import 'package:hisabet/core/theme/theme_provider.dart';

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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.pagePaddingH,
              AppDimensions.pagePaddingH,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: AppPersonalizedHeader(
                onAvatarTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                ),
              ),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
    final colorScheme = Theme.of(context).colorScheme;

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
            accentColor: AppColors.info,
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
            accentColor: AppColors.positive,
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
            accentColor: colorScheme.outline,
            disabled: true,
            onTap: () => _showComingSoon(context, 'Expense Tracking'),
          ),
          _buildActionItem(
            context: context,
            icon: Icons.bar_chart,
            label: "Reports",
            accentColor: colorScheme.outline,
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
    required Color accentColor,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = disabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface;
    final iconTone = disabled ? colorScheme.onSurfaceVariant : accentColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          style: AppCardStyle.glass,
          margin: EdgeInsets.zero,
          onTap: disabled ? null : onTap,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: iconTone.withValues(alpha: disabled ? 0.10 : 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Icon(icon, color: iconTone, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.badgeLabel.copyWith(
                  color: labelColor,
                  fontSize: 11.5,
                  height: 1.05,
                ),
              ),
            ],
          ),
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
    final photoUrl = userProfileAsync.value?.photoUrl ?? user?.photoURL;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppMissionHeader(
              eyebrow: 'CONTROL',
              title: 'Control Deck',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppDimensions.xl),

            AppProfileHeader(
              name: displayName,
              avatar: photoUrl != null ? NetworkImage(photoUrl) : null,
              subtitle: email.isNotEmpty ? email : null,
              helperText: 'Open profile editor',
              onAvatarTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
            ),

            const SizedBox(height: AppDimensions.xl),

            // ── Preferences ──────────────────────────────────────────────
            AppFormSection(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              children: [
                AppSettingTile(
                  title: 'Appearance',
                  subtitle: ref.watch(themeModeProvider).name.toUpperCase(),
                  icon: Icons.dark_mode_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                  ),
                ),
                const Divider(),
                AppSettingTile(
                  title: 'Language',
                  subtitle: ref.watch(languageProvider).languageCode == 'am' ? 'አማርኛ' : 'English',
                  icon: Icons.language_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.xl),

            // ── Account & Data ─────────────────────────────────────────────
            AppFormSection(
              title: 'Account & Data',
              icon: Icons.manage_accounts_outlined,
              children: [
                AppSettingTile(
                  title: 'Trash & Recovery',
                  subtitle: 'Restore deleted items (30 days)',
                  icon: Icons.delete_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  ),
                ),
                const Divider(),
                AppSettingTile(
                  title: 'Logout',
                  subtitle: 'Sign out of this device',
                  icon: Icons.logout,
                  iconColor: AppColors.negative,
                  titleColor: AppColors.negative,
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
                  return AppSettingTile(
                    title: 'Low Stock Alert Threshold',
                    subtitle: 'Warn when stock is at or below $threshold units',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.warning,
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
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Alert Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products with stock at or below this number will be highlighted as low stock across the entire inventory.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
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

}
