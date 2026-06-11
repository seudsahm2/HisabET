import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/tenders/presentation/providers/tenders_providers.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

class MerchantModulesScreen extends ConsumerWidget {
  const MerchantModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockCount =
        ref.watch(lowStockProductsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: AppMissionHeader(
                eyebrow: 'STRATEGY',
                title: 'Business Orbit',
                subtitle:
                    'Navigate operations, finance, and growth modules fast.',
              ),
            ),

            // ── Live Pulse / Alert Bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: AppPulseBar(
                chips: [
                  if (lowStockCount > 0)
                    AppPulseChip(
                      icon: Icons.warning_amber_rounded,
                      label:
                          '$lowStockCount item${lowStockCount == 1 ? '' : 's'} low stock',
                      color: AppColors.warning,
                    ),
                  AppPulseChip(
                    icon: Icons.handshake_rounded,
                    label: 'B2B Tenders active',
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ── Daily Operations ────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(title: 'Daily Operations'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, 0),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onTap: () =>
                        _navigate(context, ref, 'Sales', const PosCartScreen()),
                  ),
                  AppModuleTile.hero(
                    title: 'Inventory',
                    description: 'Products · Stock · SKUs',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.moduleInventory,
                    onTap: () => _navigate(
                        context, ref, 'Inventory', const ProductsListScreen()),
                  ),
                  AppModuleTile.hero(
                    title: 'Orders',
                    description: 'Fulfillment · Delivery',
                    icon: Icons.receipt_rounded,
                    accentColor: AppColors.moduleOrders,
                    onTap: () => _navigate(
                        context, ref, 'Orders', const OrdersScreen()),
                  ),
                  AppModuleTile.hero(
                    title: 'Purchases',
                    description: 'Supplier bills · Buying',
                    icon: Icons.shopping_bag_rounded,
                    accentColor: AppColors.modulePurchases,
                    onTap: () => _navigate(context, ref, 'Purchases',
                        const PurchaseOrdersScreen()),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ── Finance & Tracking ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(title: 'Finance & Tracking'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppModuleTile.compact(
                    title: 'Expenses',
                    description: 'Operating costs & recurring bills',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.moduleExpenses,
                    onTap: () => _navigate(
                        context, ref, 'Expenses', const ExpensesScreen()),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleTile.compact(
                    title: 'Cashbook',
                    description: 'Daily cash & bank reconciliation',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.moduleCashbook,
                    onTap: () => _navigate(
                        context, ref, 'Cashbook', const CashbookScreen()),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  AppModuleTile.compact(
                    title: 'Reports',
                    description: 'Profits, trends & analytics',
                    icon: Icons.bar_chart_rounded,
                    accentColor: AppColors.moduleReports,
                    onTap: () => _navigate(
                        context, ref, 'Reports', const ReportsScreen()),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ── People & Relationships ──────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(title: 'People & Relationships'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onTap: () => _navigate(
                        context, ref, 'Customers', const CustomersScreen()),
                  ),
                  AppModuleTile.compact(
                    title: 'B2B Tenders',
                    description: 'Import bids & deals',
                    icon: Icons.handshake_rounded,
                    accentColor: AppColors.moduleSuppliers,
                    onTap: () => _navigate(context, ref, 'B2B Tenders',
                        const TendersScreen()),
                  ),
                  AppModuleTile.compact(
                    title: 'Promotions',
                    description: 'Coupons & offers',
                    icon: Icons.local_offer_rounded,
                    accentColor: AppColors.modulePromotions,
                    onTap: () => _navigate(
                        context, ref, 'Promotions', const PromotionsScreen()),
                  ),
                  AppModuleTile.compact(
                    title: 'Team',
                    description: 'Staff & roles',
                    icon: Icons.badge_rounded,
                    accentColor: AppColors.moduleTeam,
                    onTap: () => _navigate(context, ref, 'Team',
                        const TeamManagementScreen()),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // ── Administration ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: AppSectionHeader(title: 'Administration'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH),
              sliver: SliverToBoxAdapter(
                child: AppModuleTile.compact(
                  title: 'Store Settings',
                  description: 'Taxes, invoices & business profile',
                  icon: Icons.settings_rounded,
                  accentColor: AppColors.moduleSettings,
                  onTap: () => _navigate(
                      context, ref, 'Settings', const SettingsScreen()),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _navigate(BuildContext context, WidgetRef ref,
      String moduleTitle, Widget screen) async {
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
      case 'Sales':
      case 'Customers':
      case 'Orders':
      case 'Promotions':
        requiredPermission = TeamPermission.processSales;
      case 'Settings':
        requiredPermission = TeamPermission.manageTeam;
      case 'Purchases':
      case 'Suppliers':
        requiredPermission = TeamPermission.managePurchases;
      case 'Expenses':
        requiredPermission = TeamPermission.manageExpenses;
      case 'Reports':
      case 'Cashbook':
        requiredPermission = TeamPermission.viewReports;
      default:
        requiredPermission = null;
    }

    if (requiredPermission == null) return true;
    final allowed = ref.read(hasPermissionProvider(requiredPermission));
    if (allowed) return true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You do not have access to $moduleTitle module.'),
        backgroundColor: AppColors.negative,
      ));
    }
    return false;
  }
}




class TendersScreen extends ConsumerStatefulWidget {
  const TendersScreen({super.key});

  @override
  ConsumerState<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends ConsumerState<TendersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('B2B Tenders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.public_rounded), text: 'Open Tenders'),
            Tab(icon: Icon(Icons.history_rounded), text: 'My Activity'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Post a Tender',
            onPressed: () => _showPostTenderSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OpenTendersTab(myUid: myUid),
          _MyActivityTab(myUid: myUid),
        ],
      ),
    );
  }

  Future<void> _showPostTenderSheet(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myDoc = myUid != null
        ? await FirebaseFirestore.instance.collection('users').doc(myUid).get()
        : null;
    final myName = myDoc?.data()?['name'] ?? 'Importer';
    final roles = List<String>.from(myDoc?.data()?['roles'] ?? []);
    if (!roles.contains('Importer') && !roles.contains('importer')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Only Importers can post tenders.'),
          backgroundColor: AppColors.negative,
        ));
      }
      return;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PostTenderSheet(myUid: myUid!, myName: myName),
    );
  }
}

class _OpenTendersTab extends ConsumerWidget {
  final String myUid;
  const _OpenTendersTab({required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tendersAsync = ref.watch(activeTendersProvider);
    return tendersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tenders) {
        if (tenders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.handshake_rounded,
                      size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('No Open Tenders',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Importers can post tenders here.\nBrokers will bid and win them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.lg),
          itemCount: tenders.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, i) => _TenderCard(
            tender: tenders[i],
            myUid: myUid,
            onWin: () => _winTender(context, ref, tenders[i], myUid),
          ),
        );
      },
    );
  }

  Future<void> _winTender(BuildContext context, WidgetRef ref, TenderModel tender, String myUid) async {
    // Pre-fill bottom sheet with tender product info
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _WinTenderSheet(
        tender: tender,
        myUid: myUid,
        onConfirm: (name, price) async {
          await _confirmWin(context, ref, tender, myUid, name, price);
        },
      ),
    );
  }

  Future<void> _confirmWin(
    BuildContext context,
    WidgetRef ref,
    TenderModel tender,
    String myUid,
    String productName,
    double price,
  ) async {
    try {
      // 1. Mark tender as won in Firestore
      await FirebaseFirestore.instance
          .collection('tenders')
          .doc(tender.id)
          .update({'status': 'won', 'winnerUid': myUid});

      // 2. Auto-add product to broker's local inventory
      final productsRepo = ref.read(productsRepositoryProvider);
      await productsRepo.addProduct(
        name: productName,
        itemNumber: tender.itemNumber,
        photoUrl: tender.photoUrl,
        colorDistribution: tender.colorDistribution,
        unit: 'carton',
        itemsPerCarton: tender.seriesSize,
        seriesSize: tender.seriesSize,
        stockQuantity: tender.cartons,
        costPrice: Decimal.parse(price.toStringAsFixed(2)),
        sellingPrice: Decimal.parse(price.toStringAsFixed(2)),
        businessRole: 'broker',
      );

      // 3. Log a purchase transaction automatically
      final txRepo = ref.read(transactionsRepositoryProvider);
      final totalCost = price * tender.cartons;
      await txRepo.addTransaction(
        contactId: tender.importerUid,
        type: TransactionType.goodsTaken,
        amount: Decimal.parse(totalCost.toStringAsFixed(2)),
        date: DateTime.now(),
        description: 'Won Tender: ${tender.itemNumber} — $productName',
        metadata: {
          'source': 'tender',
          'tenderId': tender.id,
          'importerUid': tender.importerUid,
          'product_snapshot': {
            'name': productName,
            'itemNumber': tender.itemNumber,
            'photoUrl': tender.photoUrl,
            'cartons': tender.cartons,
            'seriesSize': tender.seriesSize,
            'colorDistribution': tender.colorDistribution,
            'costPrice': price.toStringAsFixed(2),
          }
        },
      );

      ref.invalidate(allProductsProvider);

      if (context.mounted) {
        Navigator.of(context).pop(); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Tender won! Product added to inventory.'),
          backgroundColor: AppColors.positive,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative));
      }
    }
  }
}

class _MyActivityTab extends ConsumerWidget {
  final String myUid;
  const _MyActivityTab({required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(myTenderActivityProvider(myUid));
    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tenders) {
        if (tenders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text('No Tender Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Tenders you win will appear here.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.lg),
          itemCount: tenders.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, i) => _TenderCard(
            tender: tenders[i],
            myUid: myUid,
            showStatus: true,
          ),
        );
      },
    );
  }
}

class _TenderCard extends StatelessWidget {
  final TenderModel tender;
  final String myUid;
  final VoidCallback? onWin;
  final bool showStatus;

  const _TenderCard({
    required this.tender,
    required this.myUid,
    this.onWin,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwn = tender.importerUid == myUid;
    final statusColor = tender.status == 'won' ? AppColors.positive : tender.status == 'lost' ? AppColors.negative : AppColors.info;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Header
          if (tender.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
              child: Image.network(tender.photoUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item # ${tender.itemNumber}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('by ${tender.importerName}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (showStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(tender.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _InfoChip(label: '${tender.cartons} Cartons', icon: Icons.inventory_2_outlined),
                    _InfoChip(label: '${tender.seriesSize} Pairs/Series', icon: Icons.straighten_rounded),
                    _InfoChip(label: 'ETB ${tender.price.toStringAsFixed(2)}', icon: Icons.sell_outlined),
                    Text(DateFormat('MMM dd, yyyy').format(tender.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                if (onWin != null && !isOwn && tender.status == 'open') ...[
                  const SizedBox(height: AppDimensions.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onWin,
                      icon: const Icon(Icons.emoji_events_rounded, size: 18),
                      label: const Text('Win This Tender', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _PostTenderSheet extends StatefulWidget {
  final String myUid;
  final String myName;
  const _PostTenderSheet({required this.myUid, required this.myName});

  @override
  State<_PostTenderSheet> createState() => _PostTenderSheetState();
}

class _PostTenderSheetState extends State<_PostTenderSheet> {
  final _itemNumberCtrl = TextEditingController();
  final _cartonsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _seriesSizeCtrl = TextEditingController(text: '6');
  bool _saving = false;

  @override
  void dispose() {
    _itemNumberCtrl.dispose();
    _cartonsCtrl.dispose();
    _priceCtrl.dispose();
    _seriesSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final itemNumber = _itemNumberCtrl.text.trim();
    final cartons = int.tryParse(_cartonsCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());
    final seriesSize = int.tryParse(_seriesSizeCtrl.text.trim()) ?? 6;
    if (itemNumber.isEmpty || cartons == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('tenders').add({
        'importerUid': widget.myUid,
        'importerName': widget.myName,
        'itemNumber': itemNumber,
        'cartons': cartons,
        'seriesSize': seriesSize,
        'price': price,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Tender posted successfully!'),
          backgroundColor: AppColors.positive,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Post New Tender', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Brokers will see this and can win it.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(controller: _itemNumberCtrl, decoration: const InputDecoration(labelText: 'Item Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag_rounded))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _cartonsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cartons *', border: OutlineInputBorder()))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _seriesSizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pairs/Series', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price per Carton (ETB) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sell_outlined))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _post,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Post Tender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinTenderSheet extends StatefulWidget {
  final TenderModel tender;
  final String myUid;
  final Future<void> Function(String name, double price) onConfirm;

  const _WinTenderSheet({required this.tender, required this.myUid, required this.onConfirm});

  @override
  State<_WinTenderSheet> createState() => _WinTenderSheetState();
}

class _WinTenderSheetState extends State<_WinTenderSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Item ${widget.tender.itemNumber}');
    _priceCtrl = TextEditingController(text: widget.tender.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;
    final total = (double.tryParse(_priceCtrl.text) ?? tender.price) * tender.cartons;
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.positive.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.positive),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Win This Tender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('This will add the product to your inventory automatically.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
          ]),
          const SizedBox(height: 24),
          if (tender.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(tender.photoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Product Name (you can edit)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Your Cost per Carton (ETB)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sell_outlined)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tender.cartons} cartons  ×  ETB ${_priceCtrl.text}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('Total: ETB ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : () async {
                setState(() => _saving = true);
                final name = _nameCtrl.text.trim();
                final price = double.tryParse(_priceCtrl.text.trim()) ?? tender.price;
                await widget.onConfirm(name, price);
                if (mounted) setState(() => _saving = false);
              },
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded),
              label: Text(_saving ? 'Processing...' : 'Confirm & Win Tender', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

