import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/cashbook/presentation/screens/cashbook_screen.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:hisabet/features/home/presentation/providers/dashboard_providers.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/sales_history_screen.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final recentActivityAsync = ref.watch(recentActivityProvider);
    final expensesAsync = ref.watch(allExpensesProvider);
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Metrics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(allExpensesProvider);
          ref.invalidate(recentSalesProvider);
        },
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.lg,
          ),
          children: [
            // KPI Grid
            dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (stats) => _KpiGrid(stats: stats),
            ),
            const SizedBox(height: AppDimensions.xl),

            // Cashflow Visualization
            _buildChartHeader(),
            const SizedBox(height: AppDimensions.md),
            recentActivityAsync.when(
              loading: () => const AppCard(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const AppCard(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: Center(child: Text('Could not load chart data.'))),
              data: (activities) => _CashFlowChart(transactions: activities),
            ),
            const SizedBox(height: AppDimensions.xl),

            // Quick Actions Hub
            const AppSectionHeader(title: 'Record Books', uppercase: true),
            _QuickActions(context: context),
            const SizedBox(height: AppDimensions.xl),

            // Expenses & Sales Breakdowns
            expensesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (expenses) => _ExpenseSnapshotCard(expenses: expenses),
            ),
            const SizedBox(height: AppDimensions.lg),
            salesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (sales) => _SalesSnapshotCard(sales: sales),
            ),
            const SizedBox(height: AppDimensions.xl),

            // Recent Ledgers
            const AppSectionHeader(title: 'Recent Activity', uppercase: true),
            recentActivityAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (activities) =>
                  _RecentActivityCard(transactions: activities),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Cashflow Trend', style: AppTextStyles.cardTitle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Text('Last 7 Days',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14),
            ],
          ),
        )
      ],
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _CashFlowChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const AppEmptyState(
        icon: Icons.ssid_chart_rounded,
        title: 'Not enough data',
        subtitle: 'Log more transactions to visualize cash flow.',
      );
    }

    // Process transactions to derive total income vs outflow simply for the chart visualization.
    // Grouping by recent dates might be complex without guaranteed historical entries, 
    // so we plot an aggregate distribution of Income vs Expenses over the dataset.
    double income = 0.0;
    double outflow = 0.0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.paymentReceived ||
          tx.type == TransactionType.goodsGiven) {
        income += tx.amount.toDouble();
      } else {
        outflow += tx.amount.toDouble();
      }
    }

    if (income == 0 && outflow == 0) {
      income = 10;
      outflow = 10; // Placeholder curve so chart isn't empty on pure zero entries.
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegend('Income', AppColors.positive),
              const SizedBox(width: AppDimensions.lg),
              _buildLegend('Outflow', AppColors.negative),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: (income > outflow ? income : outflow) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt() == 0 ? 'Cash In' : 'Cash Out',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  checkToShowHorizontalLine: (value) => value % 10 == 0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: AppColors.positive,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusMd)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: outflow,
                        color: AppColors.warning, // Orange looks better than pure red for bars
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusMd)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.xs),
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardStats stats;

  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final healthIsPositive = stats.netBalance >= Decimal.zero;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.sm,
      crossAxisSpacing: AppDimensions.sm,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          'Total Receivable',
          '${stats.totalReceivable}',
          Icons.arrow_downward_rounded,
          AppColors.positive,
        ),
        _buildKpiCard(
          'Total Payable',
          '${stats.totalPayable.abs()}',
          Icons.arrow_upward_rounded,
          AppColors.warning,
        ),
        _buildKpiCard(
          'Net Balance',
          '${stats.netBalance}',
          Icons.account_balance_wallet_rounded,
          healthIsPositive ? AppColors.primary : AppColors.negative,
        ),
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Business Health', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(healthIsPositive ? 'Healthy' : 'At Risk', style: AppTextStyles.statValue.copyWith(color: healthIsPositive ? AppColors.positive : AppColors.negative, fontSize: 18)),
                  Icon(healthIsPositive ? Icons.trending_up_rounded : Icons.warning_rounded, color: healthIsPositive ? AppColors.positive : AppColors.negative),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildKpiCard(String title, String amount, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          AppAmountText(amount: amount, fontSize: 18),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final BuildContext context;

  const _QuickActions({required this.context});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            title: 'Cashbook',
            icon: Icons.menu_book_rounded,
            color: AppColors.moduleCashbook,
            onTap: () => Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => const CashbookScreen())),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _ActionTile(
            title: 'Sales',
            icon: Icons.point_of_sale_rounded,
            color: AppColors.moduleSales,
            onTap: () => Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _ActionTile(
            title: 'Expenses',
            icon: Icons.receipt_long_rounded,
            color: AppColors.moduleExpenses,
            onTap: () => Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md, horizontal: AppDimensions.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppDimensions.sm),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSnapshotCard extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const _ExpenseSnapshotCard({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<Decimal>(Decimal.zero, (sum, expense) => sum + expense.amount);
    final recurring = expenses.where((expense) => expense.isRecurring).length;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expenses Snapshot', style: AppTextStyles.cardTitle),
              AppStatusBadge(label: '$recurring Recurring', color: AppColors.moduleExpenses, small: true),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Volume', style: AppTextStyles.cardSubtitle),
                  Text('${expenses.length} Records', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Spent Frame', style: AppTextStyles.cardSubtitle),
                  AppAmountText(amount: '$total', fontSize: 16, isPositive: false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesSnapshotCard extends StatelessWidget {
  final List<SaleModel> sales;

  const _SalesSnapshotCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    final totalSales = sales.fold<Decimal>(Decimal.zero, (sum, sale) => sum + sale.total);
    final totalPaid = sales.fold<Decimal>(Decimal.zero, (sum, sale) => sum + sale.paidAmount);
    final due = totalSales - totalPaid;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sales Envelope', style: AppTextStyles.cardTitle),
              Icon(Icons.trending_up_rounded, color: AppColors.moduleSales, size: 20),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume', style: AppTextStyles.cardSubtitle),
                    Text('${sales.length} Deals', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Collected', style: AppTextStyles.cardSubtitle),
                    Text('ETB $totalPaid', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.positive, fontSize: 14)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pending', style: AppTextStyles.cardSubtitle),
                    Text('ETB $due', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _RecentActivityCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const AppEmptyState(icon: Icons.history_rounded, title: 'No History', subtitle: 'Ledger is completely flat.');
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: transactions.take(5).map((tx) {
          final isCredit = tx.type == TransactionType.paymentReceived || tx.type == TransactionType.goodsGiven;
          final color = isCredit ? AppColors.positive : AppColors.negative;
          final icon = isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

          return Column(
            children: [
              AppListTile(
                leadingIcon: icon,
                leadingColor: color,
                title: _labelFor(tx.type),
                subtitle: DateFormat('MMM d, y • h:mm a').format(tx.date),
                trailing: Text('ETB ${tx.amount}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                onTap: () {}, // No detail routing intended here
              ),
              if (tx != transactions.take(5).last)
                const Divider(height: 1, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _labelFor(TransactionType type) {
    switch (type) {
      case TransactionType.goodsGiven:
        return 'Sale Execution';
      case TransactionType.goodsTaken:
        return 'Goods Purchase';
      case TransactionType.paymentGiven:
        return 'Outbound Payment';
      case TransactionType.paymentReceived:
        return 'Inbound Payment';
    }
  }
}