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
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        child: Container(
          height: 64,
          // The nav bar is the one element that genuinely floats above the
          // page, so it is the one element that earns a shadow.
          decoration: AppGlass.floating(
            context,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Ledger'),
              _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Items'),
              _buildNavItem(3, Icons.business_center_outlined, Icons.business_center_rounded, 'Hub'),
              _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = isDark ? AppColors.primaryBright : AppColors.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    
    return GestureDetector(
      onTap: () => _onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        // 200ms sits inside the 150-300ms micro-interaction band; the previous
        // 300ms made every tab switch feel a beat slow.
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 14 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.badgeLabel.copyWith(
                  color: activeColor,
                  fontSize: 12.5,
                  letterSpacing: -0.1,
                ),
              ),
            ]
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
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider).value;
    final user = FirebaseAuth.instance.currentUser;
    final name = profile?.displayName ?? user?.displayName ?? 'Merchant';
    final photoUrl = profile?.photoUrl ?? user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.lg,
        AppDimensions.pagePaddingH,
        AppDimensions.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timeGreeting,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Semantics(
            button: true,
            label: 'Open profile',
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        name.characters.first.toUpperCase(),
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.hairlineDark : AppColors.hairline,
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
