import 'package:flutter/material.dart';
import 'package:hisabet/features/inventory/presentation/screens/products_list_screen.dart';
import 'package:hisabet/features/sales/presentation/screens/pos_cart_screen.dart';

class MerchantModulesScreen extends StatelessWidget {
  const MerchantModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = _merchantModules;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Merchant Modules',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Choose any business area to manage your operations.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final module = modules[index];
                return _ModuleCard(
                  module: module,
                  onTap: () {
                    if (module.title == 'Inventory') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProductsListScreen(),
                        ),
                      );
                      return;
                    }

                    if (module.title == 'Sales') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PosCartScreen(),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FeatureWorkspaceScreen(module: module),
                      ),
                    );
                  },
                );
              }, childCount: modules.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureWorkspaceScreen extends StatelessWidget {
  final MerchantModule module;

  const FeatureWorkspaceScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: module.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: module.color,
                  child: Icon(module.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.subtitle,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Initial Feature Set',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...module.features.map(
            (feature) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(feature),
                subtitle: const Text('Ready for incremental implementation'),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${module.title} build queue started.'),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Building This Module'),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final MerchantModule module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: module.color.withValues(alpha: 0.18),
                  child: Icon(module.icon, color: module.color),
                ),
                const Spacer(),
                Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  module.shortLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MerchantModule {
  final String title;
  final String shortLabel;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;

  const MerchantModule({
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
  });
}

const List<MerchantModule> _merchantModules = [
  MerchantModule(
    title: 'Inventory',
    shortLabel: 'Stock, SKU, low stock',
    subtitle: 'Track stock levels, SKUs, reorder points and stock adjustments.',
    icon: Icons.inventory_2,
    color: Colors.indigo,
    features: ['Products', 'Stock adjustments', 'Low stock alerts', 'Barcode support'],
  ),
  MerchantModule(
    title: 'Sales',
    shortLabel: 'POS and invoices',
    subtitle: 'Create invoices, process payments and monitor daily sales.',
    icon: Icons.point_of_sale,
    color: Colors.green,
    features: ['POS checkout', 'Invoice printing', 'Discounts', 'Refunds'],
  ),
  MerchantModule(
    title: 'Purchases',
    shortLabel: 'Supplier buying flow',
    subtitle: 'Record supplier purchases, bills and cost tracking.',
    icon: Icons.shopping_cart,
    color: Colors.orange,
    features: ['Purchase orders', 'Goods receipt', 'Bills', 'Due dates'],
  ),
  MerchantModule(
    title: 'Customers',
    shortLabel: 'CRM and credit',
    subtitle: 'Manage customer profiles, receivables and loyalty.',
    icon: Icons.groups,
    color: Colors.blue,
    features: ['Customer profiles', 'Credit limits', 'Loyalty points', 'Statements'],
  ),
  MerchantModule(
    title: 'Suppliers',
    shortLabel: 'Payables and terms',
    subtitle: 'Supplier directory, balances and payment terms.',
    icon: Icons.local_shipping,
    color: Colors.teal,
    features: ['Supplier profiles', 'Payables', 'Terms management', 'Supplier ledger'],
  ),
  MerchantModule(
    title: 'Expenses',
    shortLabel: 'Business cost control',
    subtitle: 'Track operating expenses and recurring costs.',
    icon: Icons.receipt_long,
    color: Colors.deepOrange,
    features: ['Expense categories', 'Recurring expenses', 'Receipts', 'Approvals'],
  ),
  MerchantModule(
    title: 'Cashbook',
    shortLabel: 'Cash and bank flow',
    subtitle: 'Daily cash-in/cash-out and bank account reconciliation.',
    icon: Icons.account_balance_wallet,
    color: Colors.brown,
    features: ['Cash entries', 'Bank accounts', 'Transfer', 'Reconciliation'],
  ),
  MerchantModule(
    title: 'Reports',
    shortLabel: 'Business intelligence',
    subtitle: 'Profit, stock movement, sales trends and debtor reports.',
    icon: Icons.bar_chart,
    color: Colors.purple,
    features: ['Profit report', 'Sales trend', 'Inventory valuation', 'Top products'],
  ),
  MerchantModule(
    title: 'Team',
    shortLabel: 'Staff and permissions',
    subtitle: 'Role-based access and performance tracking for employees.',
    icon: Icons.badge,
    color: Colors.cyan,
    features: ['Roles & permissions', 'Staff accounts', 'Audit trail', 'Activity logs'],
  ),
  MerchantModule(
    title: 'Orders',
    shortLabel: 'Online and offline orders',
    subtitle: 'Capture order lifecycle from pending to delivered.',
    icon: Icons.list_alt,
    color: Colors.redAccent,
    features: ['Order board', 'Status workflow', 'Delivery notes', 'Returns'],
  ),
  MerchantModule(
    title: 'Promotions',
    shortLabel: 'Campaign and coupons',
    subtitle: 'Run offers, bundles and discount campaigns.',
    icon: Icons.local_offer,
    color: Colors.pink,
    features: ['Coupons', 'Bundles', 'Campaign windows', 'Usage analytics'],
  ),
  MerchantModule(
    title: 'Settings',
    shortLabel: 'Business profile setup',
    subtitle: 'Configure tax, invoices, localization and company profile.',
    icon: Icons.settings,
    color: Colors.grey,
    features: ['Business profile', 'Tax settings', 'Invoice template', 'Backup options'],
  ),
];
