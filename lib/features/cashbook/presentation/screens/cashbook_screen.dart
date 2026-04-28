import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/cashbook/presentation/providers/cashbook_providers.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  CashbookPeriod _selectedPeriod = CashbookPeriod.last30Days;

  @override
  Widget build(BuildContext context) {
    final cashbookAsync = ref.watch(cashbookDataProvider(_selectedPeriod));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: cashbookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(cashbookDataProvider(_selectedPeriod));
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.lg,
              ),
              children: [
                const AppMissionHeader(
                  eyebrow: 'FINANCE ORBIT',
                  title: 'Cash Flow Radar',
                  subtitle: 'Track inflow, outflow, and daily balance with clarity.',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.lg),
                _PeriodChips(
                  selectedPeriod: _selectedPeriod,
                  onSelect: (period) => setState(() => _selectedPeriod = period),
                ),
                const SizedBox(height: AppDimensions.xl),
                _SummaryCard(summary: data.summary),
                const SizedBox(height: AppDimensions.xl),
                const AppSectionHeader(title: 'Ledger Entries', uppercase: true),
                if (data.entries.isEmpty)
                  const _EmptyState()
                else
                  ...data.entries.map((entry) => _EntryTile(entry: entry)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  final CashbookPeriod selectedPeriod;
  final ValueChanged<CashbookPeriod> onSelect;

  const _PeriodChips({
    required this.selectedPeriod,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      CashbookPeriod.today: 'Today',
      CashbookPeriod.last7Days: '7 Days',
      CashbookPeriod.last30Days: '30 Days',
      CashbookPeriod.all: 'All Time',
    };

    return AppFilterChips<CashbookPeriod>(
      options: options.keys.toList(),
      selected: selectedPeriod,
      labelBuilder: (period) => options[period]!,
      onSelected: onSelect,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CashbookSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Cash Summary', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cash In', style: AppTextStyles.cardSubtitle),
                    AppAmountText(amount: summary.totalIn.toString(), fontSize: 16, isPositive: true),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Cash Out', style: AppTextStyles.cardSubtitle),
                    AppAmountText(amount: summary.totalOut.toString(), fontSize: 16, isPositive: false),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Net Frame', style: AppTextStyles.cardSubtitle),
                    AppAmountText(
                      amount: summary.net.toString(),
                      fontSize: 16,
                      isPositive: summary.net >= Decimal.zero,
                    ),
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

class _EntryTile extends StatelessWidget {
  final CashbookEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.direction == CashbookDirection.cashIn;
    final color = isIn ? AppColors.positive : AppColors.negative;
    final icon = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: AppListTile(
        leadingIcon: icon,
        leadingColor: color,
        title: entry.title,
        subtitle: '${entry.source}\n${DateFormat('MMM d, yyyy • h:mm a').format(entry.date)}',
        trailing: AppAmountText(
          amount: entry.amount.toString(),
          fontSize: 16,
          isPositive: isIn,
          showSign: true,
        ),
        onTap: () {}, // Detail navigation not fully spec'd yet
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.account_balance_wallet_rounded,
      title: 'No cash entries yet',
      subtitle: 'Recorded expenses and sales payments will automatically flow into this unified ledger.',
    );
  }
}