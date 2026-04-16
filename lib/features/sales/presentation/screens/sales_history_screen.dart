import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recent Sales'),
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load sales: $error')),
        data: (sales) {
          if (sales.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No sales recorded yet.',
              subtitle: 'Process your first sale in the POS to see it here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.lg,
            ),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              final due = sale.total - sale.paidAmount;
              final isPaid = due <= Decimal.zero;

              final List<String> subtitleParts = [
                '${sale.paymentMethod.toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(sale.createdAt)}',
              ];

              if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) {
                subtitleParts.add('Customer: ${sale.customerName!}');
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
                      const Icon(Icons.chevron_right, color: AppColors.textHint, size: AppDimensions.iconSm),
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
          );
        },
      ),
    );
  }
}
