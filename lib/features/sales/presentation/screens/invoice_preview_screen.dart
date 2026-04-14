import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/sales/data/models/sale_line_item_model.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/data/services/invoice_pdf_service.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:printing/printing.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final String saleId;

  const InvoicePreviewScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(saleInvoiceProvider(saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          invoiceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (invoiceData) {
              return IconButton(
                icon: const Icon(Icons.print_outlined),
                onPressed: () async {
                  try {
                    await Printing.layoutPdf(
                      onLayout: (format) => InvoicePdfService.buildInvoicePdf(invoiceData),
                    );
                  } on MissingPluginException {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Printing is not registered in the current running app. Stop and run the app again to load the plugin.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Print failed: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (invoiceData) {
          final sale = invoiceData.sale;
          final lines = invoiceData.lineItems;
          final bundleLines = lines.where((line) => line.isBundle).toList();
          final singleLines = lines.where((line) => !line.isBundle).toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _InvoicePreviewCard(
                      saleId: sale.id,
                      saleDate: sale.createdAt,
                      customerName: sale.customerName,
                      bundleLines: bundleLines,
                      singleLines: singleLines,
                      sale: sale,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final pdfBytes = await InvoicePdfService.buildInvoicePdf(invoiceData);
                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: 'invoice_${sale.id.substring(0, 8)}.pdf',
                          );
                        } on MissingPluginException {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sharing is not registered in the current running app. Stop and run the app again to load the plugin.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}

class _InvoicePreviewCard extends StatelessWidget {
  final String saleId;
  final DateTime saleDate;
  final String? customerName;
  final List<SaleLineItemModel> bundleLines;
  final List<SaleLineItemModel> singleLines;
  final SaleModel sale;

  const _InvoicePreviewCard({
    required this.saleId,
    required this.saleDate,
    required this.customerName,
    required this.bundleLines,
    required this.singleLines,
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HisabET Invoice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Invoice #: ${saleId.substring(0, 8).toUpperCase()}'),
          Text('Date: $saleDate'),
          if (customerName != null && customerName!.trim().isNotEmpty)
            Text('Customer: $customerName'),
          const SizedBox(height: 14),

          if (bundleLines.isNotEmpty) ...[
            const Text(
              'Bundle Products',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...bundleLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${line.quantity} carton(s) x ETB ${line.pricePerCarton} /carton = ETB ${line.lineTotal}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
          ],

          if (singleLines.isNotEmpty) ...[
            const Text(
              'Single Products',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...singleLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('${line.quantity} x ${line.unitPrice}'),
                    const SizedBox(width: 8),
                    Text('ETB ${line.lineTotal}'),
                  ],
                ),
              ),
            ),
            const Divider(),
          ],

          const SizedBox(height: 8),
          _summaryRow('Subtotal', sale.subtotal.toString()),
          _summaryRow('Discount', sale.discount.toString()),
          _summaryRow('Tax', sale.tax.toString()),
          const SizedBox(height: 6),
          _summaryRow('Total', sale.total.toString(), bold: true),
          _summaryRow('Paid', sale.paidAmount.toString()),
          _summaryRow('Due', (sale.total - sale.paidAmount).toString(), bold: true),
        ],
      ),
    );
  }
}

Widget _summaryRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          'ETB $value',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
