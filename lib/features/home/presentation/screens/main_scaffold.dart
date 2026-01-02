import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:hisabet/features/contacts/presentation/screens/add_contact_screen.dart';
import 'package:hisabet/features/home/presentation/providers/dashboard_providers.dart';
import 'package:hisabet/core/l10n/language_provider.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  late PageController _pageController;

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
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          _HomeDashboard(),
          ContactsListScreen(),
          Center(child: Icon(Icons.store, size: 80, color: Colors.grey)),
          _MenuTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigate,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight.withOpacity(0.2),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: AppColors.primary),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Store',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu, color: AppColors.primary),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

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
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back,",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "Merchant",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.notifications_none,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Card
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _DashboardStatsCard(stats: stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox(),
            ),
          ),

          // Quick Actions
          const SliverToBoxAdapter(child: _QuickActionGrid()),

          // Recent Activity Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                "RECENT ACTIVITY",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Recent Activity List
          activityAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No recent activity")),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = transactions[index];
                  return _MiniTransactionTile(transaction: tx);
                }, childCount: transactions.length),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
            error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _DashboardStatsCard extends StatelessWidget {
  final DashboardStats stats;
  const _DashboardStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                "TO COLLECT",
                stats.totalReceivable,
                Colors.greenAccent,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatColumn(
                "TO PAY",
                stats.totalPayable.abs(),
                Colors.redAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "ETB $amount",
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            context,
            Icons.person_add,
            "Add Contact",
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddContactScreen()),
            ),
          ),
          _buildActionButton(
            context,
            Icons.qr_code_scanner,
            "Scan QR",
            Colors.purple,
            () {},
          ),
          _buildActionButton(
            context,
            Icons.analytics,
            "Reports",
            Colors.orange,
            () {},
          ),
          _buildActionButton(
            context,
            Icons.settings,
            "Settings",
            Colors.grey,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MiniTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _MiniTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.balanceEffect.toDouble() >= 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive
                  ? Icons.arrow_downward
                  : Icons
                        .arrow_upward, // Logic inversion: If balance effect positive (they owe me), I gave goods (arrow up/out) or they paid (arrow down/in)? Wait.
              // Logic Check:
              // GoodsGiven -> They Owe Me (+) -> I gave -> Arrow Up?
              // Simplification: Green = Good, Red = Bad/Owe.
              isPositive ? Icons.check : Icons.priority_high,
              size: 16,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? "Transaction",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat("MMM d, h:mm a").format(transaction.date),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${isPositive ? '+' : ''}${transaction.amount}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.give : AppColors.take,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTab extends ConsumerWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Settings & Tools",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildMenuOption(
              icon: Icons.language,
              title: "Language / ቋንቋ",
              subtitle: "English / አማርኛ",
              onTap: () => _showLanguageSheet(context, ref),
            ),
            _buildMenuOption(
              icon: Icons.bug_report_outlined,
              title: "Debug Tools",
              subtitle: "Reconciliation & Logs",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Language",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
              title: const Text("English"),
              onTap: () {
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text("🇪🇹", style: TextStyle(fontSize: 24)),
              title: const Text("Amharic (አማርኛ)"),
              onTap: () {
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(const Locale('am'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
