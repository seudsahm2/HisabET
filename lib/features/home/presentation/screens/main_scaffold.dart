import 'package:decimal/decimal.dart';
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

import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:hisabet/features/reports/presentation/screens/reports_screen.dart';
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
      extendBody: true,
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return AppBottomNav(
      currentIndex: _currentIndex,
      onSelect: _onNavigate,
      items: const [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        AppBottomNavItem(
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book_rounded,
          label: 'Ledger',
        ),
        AppBottomNavItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'Items',
        ),
        AppBottomNavItem(
          icon: Icons.business_center_outlined,
          activeIcon: Icons.business_center_rounded,
          label: 'Hub',
        ),
        AppBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
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
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(allContactsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: _GreetingHeader()),

            // Balance statement
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, 0),
              sliver: SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => AppBalancePanel(
                    label: 'Net position',
                    netBalance: stats.netBalance,
                    receivable: stats.totalReceivable,
                    payable: stats.totalPayable,
                    footnote: stats.netBalance >= Decimal.zero
                        ? 'Owed to you across all contacts'
                        : 'You owe more than you are owed',
                  ),
                  loading: () => const _PanelSkeleton(),
                  error: (e, _) => const _PanelError(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),

            // Actions
            const SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
              sliver: SliverToBoxAdapter(child: _DashboardActions()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xxl)),

            // Recent activity
            const SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Recent activity',
                uppercase: true,
              ),
            ),

            activityAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.pagePaddingH,
                      ),
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Nothing recorded yet',
                        subtitle:
                            'Transactions you record with a contact appear here.',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppLedgerGroup(
                      children: [
                        for (final tx in transactions) _activityRow(tx),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: _ListSkeleton()),
              error: (e, _) => const SliverToBoxAdapter(child: _PanelError()),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(TransactionModel tx) {
    final isIncoming = tx.balanceEffect >= Decimal.zero;
    final (statusLabel, statusTone) = switch (tx.status) {
      TransactionStatus.confirmed => ('Confirmed', AppColors.positive),
      TransactionStatus.disputed => ('Disputed', AppColors.negative),
      TransactionStatus.pending => ('Pending', AppColors.warning),
    };

    return AppLedgerRow(
      title: tx.description?.trim().isNotEmpty == true
          ? tx.description!
          : _fallbackTitle(tx.type),
      amount: tx.amount,
      direction:
          isIncoming ? LedgerDirection.incoming : LedgerDirection.outgoing,
      status: statusLabel,
      statusTone: statusTone,
      meta: DateFormat('MMM d').format(tx.date),
      onTap: () {},
    );
  }

  String _fallbackTitle(TransactionType type) => switch (type) {
        TransactionType.goodsGiven => 'Goods given',
        TransactionType.goodsTaken => 'Goods taken',
        TransactionType.paymentGiven => 'Payment made',
        TransactionType.paymentReceived => 'Payment received',
      };
}

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final user = FirebaseAuth.instance.currentUser;
    final name = profile?.displayName ?? user?.displayName ?? 'Merchant';
    final photoUrl = profile?.photoUrl ?? user?.photoURL;

    return AppTopBar.greeting(
      greeting: _timeGreeting,
      name: name,
      avatar: photoUrl != null ? NetworkImage(photoUrl) : null,
      onAvatarTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
      ),
    );
  }
}

class _DashboardActions extends ConsumerWidget {
  const _DashboardActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

    return AppQuickActions(
      actions: [
        AppQuickAction(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add contact',
          onTap: () => open(const AddContactScreen()),
        ),
        AppQuickAction(
          icon: Icons.inventory_2_outlined,
          label: 'Add item',
          onTap: () => open(const ProductUpsertScreen()),
        ),
        AppQuickAction(
          icon: Icons.receipt_long_outlined,
          label: 'Expenses',
          onTap: () => open(const ExpensesScreen()),
        ),
        AppQuickAction(
          icon: Icons.insights_outlined,
          label: 'Reports',
          onTap: () => open(const ReportsScreen()),
        ),
      ],
    );
  }
}

/// Skeletons reserve the real content height so nothing jumps when data lands.
class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 168,
      decoration: BoxDecoration(
        // Matches the loaded anchor panel so the surface does not flash from
        // white to teal when the balance arrives.
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
      child: SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _PanelError extends StatelessWidget {
  const _PanelError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.lg,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: AppDimensions.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Could not load this right now. Pull down to retry.',
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
    final displayName = userProfileAsync.valueOrNull?.displayName ?? user?.displayName ?? 'Merchant';
    final email = user?.email ?? '';
    final photoUrl = userProfileAsync.valueOrNull?.photoUrl ?? user?.photoURL;

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
