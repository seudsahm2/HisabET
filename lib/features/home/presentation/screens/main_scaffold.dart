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

// ... (imports remain the same)
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
          // 1. Header Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _DashboardHeader(),
            ),
          ),

          // 2. Premium Stats Card
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (stats) => _PremiumStatsCard(stats: stats),
              loading: () => Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => const SizedBox(),
            ),
          ),

          // 3. Quick Actions Grid
          const SliverToBoxAdapter(child: _PremiumQuickActions()),

          // 4. Recent Activity Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RECENT ACTIVITY",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    child: Text(
                      "See All",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Activity List
          activityAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyActivityState(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tx = transactions[index];
                  return _PremiumTransactionTile(transaction: tx);
                }, childCount: transactions.length),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
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
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Hello, Merchant",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _PremiumStatsCard extends StatelessWidget {
  final DashboardStats stats;
  const _PremiumStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF00251A), Color(0xFF004D40)], // Deep Luxury Teal
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 200,
              color: Colors.white.withOpacity(0.03),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TOTAL NET BALANCE",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ETB ${stats.netBalance}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          "To Collect",
                          stats.totalReceivable,
                          Colors.greenAccent,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      Expanded(
                        child: _buildMiniStat(
                          "To Pay",
                          stats.totalPayable.abs(),
                          Colors.redAccent.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          "ETB $amount",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _PremiumQuickActions extends StatelessWidget {
  const _PremiumQuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(
            context,
            Icons.person_add,
            "Add Contact",
            const Color(0xFFE3F2FD),
            Colors.blue,
            0,
          ),
          _buildActionItem(
            context,
            Icons.qr_code_scanner,
            "Scan",
            const Color(0xFFF3E5F5),
            Colors.purple,
            1,
          ),
          _buildActionItem(
            context,
            Icons.bar_chart,
            "Analytics",
            const Color(0xFFFFF3E0),
            Colors.orange,
            2,
          ),
          _buildActionItem(
            context,
            Icons.settings_outlined,
            "Settings",
            const Color(0xFFF5F5F5),
            Colors.grey.shade700,
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    Color iconColor,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        if (index == 0)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textPrimary,
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

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(
                      0.08,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? "Untitled",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d • h:mm a').format(transaction.date),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isPositive ? '+' : ''} ${transaction.amount}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPositive ? AppColors.give : AppColors.take,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Completed",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No Recent Activity",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ... (_MenuTab remains largely same but we can keep it as is or include it if specific style needed, but for now we focus on Dashboard)
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Application Language",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
              ),
              title: const Text(
                "English",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Default system language"),
              onTap: () {
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("🇪🇹", style: TextStyle(fontSize: 24)),
              ),
              title: const Text(
                "Amharic",
                style: TextStyle(fontWeight: FontWeight.bold),
              ), // Corrected to just Amharic for cleaner UI
              subtitle: const Text("አማርኛ"),
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
