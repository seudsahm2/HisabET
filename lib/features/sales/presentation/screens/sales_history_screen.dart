import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recent Sales'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load sales: $error')),
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Text('No sales recorded yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final sale = sales[index];
              final due = sale.total - sale.paidAmount;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.receipt_long, color: AppColors.primary),
                  ),
                  title: Text(
                    'ETB ${sale.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid: ETB ${sale.paidAmount} • Due: ETB $due'),
                      Text(
                        '${sale.paymentMethod.toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(sale.createdAt)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (sale.customerName != null && sale.customerName!.trim().isNotEmpty)
                        Text('Customer: ${sale.customerName!}'),
                    ],
                  ),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InvoicePreviewScreen(saleId: sale.id),
                          ),
                        );
                      },
                    ),
                  ),
              );
            },
          );
        },
      ),
    );
  }
}
