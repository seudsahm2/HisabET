import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';

enum SaleFilterStatus { all, paid, partial }
enum SaleDateFilter { today, thisWeek, thisMonth, all }

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SaleFilterStatus _statusFilter = SaleFilterStatus.all;
  SaleDateFilter _dateFilter = SaleDateFilter.today;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(SaleModel sale) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    final customerMatch = sale.customerName?.toLowerCase().contains(q) ?? false;
    final idMatch = sale.id.toLowerCase().contains(q);
    return customerMatch || idMatch;
  }

  bool _matchesStatus(SaleModel sale) {
    final due = sale.total - sale.paidAmount;
    final isPaid = due <= Decimal.zero;

    switch (_statusFilter) {
      case SaleFilterStatus.all:
        return true;
      case SaleFilterStatus.paid:
        return isPaid;
      case SaleFilterStatus.partial:
        return !isPaid;
    }
  }

  bool _matchesDate(SaleModel sale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final saleDate = DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);

    switch (_dateFilter) {
      case SaleDateFilter.today:
        return saleDate.isAtSameMomentAs(today);
      case SaleDateFilter.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return saleDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      case SaleDateFilter.thisMonth:
        return saleDate.year == today.year && saleDate.month == today.month;
      case SaleDateFilter.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load sales: $error')),
        data: (allSales) {
          final filteredSales = allSales
              .where(_matchesSearch)
              .where(_matchesStatus)
              .where(_matchesDate)
              .toList();

          final totalRevenue = filteredSales.fold<Decimal>(Decimal.zero, (sum, sale) => sum + sale.total);
          final totalReceivable = filteredSales.fold<Decimal>(
              Decimal.zero,
              (sum, sale) => sum + ((sale.total - sale.paidAmount) > Decimal.zero ? (sale.total - sale.paidAmount) : Decimal.zero));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recentSalesProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppMissionHeader(
                          eyebrow: 'REVENUE TRACK',
                          title: 'Sales Chronicle',
                          subtitle: 'Review paid, partial, and time-filtered revenue movement.',
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        // Summary Banner
                        AppCard(
                          padding: const EdgeInsets.all(AppDimensions.lg),
                          color: AppColors.primary,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_dateFilter.name.toUpperCase()} REVENUE',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ETB $totalRevenue',
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: AppDimensions.sm),
                                    Text(
                                      '${filteredSales.length} Sales • ETB $totalReceivable Unpaid',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // Search
                        AppSearchBar(
                          controller: _searchController,
                          hintText: 'Search customer or invoice ID...',
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // Date Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: SaleDateFilter.values.map((filter) {
                              final isSelected = _dateFilter == filter;
                              String label = '';
                              switch (filter) {
                                case SaleDateFilter.today: label = 'Today'; break;
                                case SaleDateFilter.thisWeek: label = 'This Week'; break;
                                case SaleDateFilter.thisMonth: label = 'This Month'; break;
                                case SaleDateFilter.all: label = 'All Time'; break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _dateFilter = filter);
                                  },
                                  selectedColor: AppColors.primaryLight.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),

                        // Status Filter
                        Row(
                          children: [
                            _StatusFilterChip(
                              label: 'All',
                              isSelected: _statusFilter == SaleFilterStatus.all,
                              onTap: () => setState(() => _statusFilter = SaleFilterStatus.all),
                            ),
                            const SizedBox(width: 8),
                            _StatusFilterChip(
                              label: 'Paid',
                              isSelected: _statusFilter == SaleFilterStatus.paid,
                              onTap: () => setState(() => _statusFilter = SaleFilterStatus.paid),
                              color: AppColors.positive,
                            ),
                            const SizedBox(width: 8),
                            _StatusFilterChip(
                              label: 'Partial / Credit',
                              isSelected: _statusFilter == SaleFilterStatus.partial,
                              onTap: () => setState(() => _statusFilter = SaleFilterStatus.partial),
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sales List
                if (filteredSales.isEmpty)
                  const SliverFillRemaining(
                    child: AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No sales found',
                      subtitle: 'Try adjusting your filters or date range.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, 0, AppDimensions.pagePaddingH, AppDimensions.xxxl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sale = filteredSales[index];
                          final due = sale.total - sale.paidAmount;
                          final isPaid = due <= Decimal.zero;

                          final List<String> subtitleParts = [
                            '${sale.paymentMethod.toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(sale.createdAt)}',
                          ];

                          if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) {
                            subtitleParts.add('Customer: ${sale.customerName!}');
                          } else {
                            subtitleParts.add('Walk-in Customer');
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                            child: AppListTile(
                              leadingIcon: Icons.receipt_long,
                              leadingColor: isPaid ? AppColors.positive : AppColors.warning,
                              title: 'ETB ${sale.total}',
                              subtitle: subtitleParts.join('\n'),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  isPaid
                                      ? AppStatusBadge.success(label: 'PAID', small: true)
                                      : AppStatusBadge.warning(label: 'DUE: ETB $due', small: true),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${sale.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => InvoicePreviewScreen(saleId: sale.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: filteredSales.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
