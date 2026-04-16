import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/sales/data/models/sale_line_item_model.dart';
import 'package:hisabet/features/sales/data/models/sale_model.dart';
import 'package:hisabet/features/sales/data/services/invoice_pdf_service.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/settings/data/models/app_settings_model.dart';
import 'package:hisabet/features/settings/presentation/providers/settings_providers.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final String saleId;

  const InvoicePreviewScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(saleInvoiceProvider(saleId));
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? AppSettingsModel.defaults();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          invoiceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (invoiceData) {
              return IconButton(
                icon: const Icon(Icons.print_outlined),
                onPressed: () async {
                  try {
                    await Printing.layoutPdf(
                      onLayout: (format) => InvoicePdfService.buildInvoicePdf(invoiceData, settings: settings),
                    );
                  } on MissingPluginException {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugin not registered.')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print failed: $e')));
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
                  padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                  children: [
                    _InvoicePreviewCard(
                      saleId: sale.id,
                      saleDate: sale.createdAt,
                      customerName: sale.customerName,
                      bundleLines: bundleLines,
                      singleLines: singleLines,
                      sale: sale,
                      settings: settings,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final pdfBytes = await InvoicePdfService.buildInvoicePdf(invoiceData, settings: settings);
                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: '${settings.invoicePrefix.toLowerCase()}_${sale.id.substring(0, 8)}.pdf',
                          );
                        } on MissingPluginException {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plugin not registered.')));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                        }
                      },
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('SHARE RECEIPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
  final AppSettingsModel settings;

  const _InvoicePreviewCard({
    required this.saleId,
    required this.saleDate,
    required this.customerName,
    required this.bundleLines,
    required this.singleLines,
    required this.sale,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settings.businessName.toUpperCase(), style: AppTextStyles.headlineSmall.copyWith(letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text('INVOICE #${settings.invoicePrefix}-${saleId.substring(0, 8).toUpperCase()}', style: AppTextStyles.mono.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppDimensions.sm),
                    Text(DateFormat('MMM dd, yyyy • hh:mm a').format(saleDate), style: AppTextStyles.cardSubtitle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (sale.total - sale.paidAmount <= Decimal.zero) ? AppColors.positiveLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  (sale.total - sale.paidAmount <= Decimal.zero) ? 'PAID' : 'DUE',
                  style: TextStyle(
                    color: (sale.total - sale.paidAmount <= Decimal.zero) ? AppColors.positive : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.md),

          if (settings.businessPhone?.trim().isNotEmpty == true || settings.businessAddress?.trim().isNotEmpty == true || (customerName != null && customerName!.trim().isNotEmpty)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.businessPhone?.trim().isNotEmpty == true || settings.businessAddress?.trim().isNotEmpty == true)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FROM:', style: AppTextStyles.sectionLabel),
                        const SizedBox(height: 4),
                        if (settings.businessPhone?.trim().isNotEmpty == true) Text(settings.businessPhone!, style: AppTextStyles.cardSubtitle),
                        if (settings.businessAddress?.trim().isNotEmpty == true) Text(settings.businessAddress!, style: AppTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                if (customerName != null && customerName!.trim().isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BILLED TO:', style: AppTextStyles.sectionLabel),
                        const SizedBox(height: 4),
                        Text(customerName!, style: AppTextStyles.cardTitle),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.xl),
          ],

          if (bundleLines.isNotEmpty) ...[
            Text('BUNDLE PURCHASES', style: AppTextStyles.sectionLabel),
            const SizedBox(height: AppDimensions.sm),
            ...bundleLines.map((line) => _InvoiceItemRow(
                  name: line.productName,
                  quantity: '${line.quantity} CTN',
                  price: '${settings.currencySymbol} ${line.pricePerCarton}',
                  total: '${settings.currencySymbol} ${line.lineTotal}',
                )),
            const SizedBox(height: AppDimensions.md),
          ],

          if (singleLines.isNotEmpty) ...[
            Text('SINGLE PURCHASES', style: AppTextStyles.sectionLabel),
            const SizedBox(height: AppDimensions.sm),
            ...singleLines.map((line) => _InvoiceItemRow(
                  name: line.productName,
                  quantity: line.quantity.toString(),
                  price: '${settings.currencySymbol} ${line.unitPrice}',
                  total: '${settings.currencySymbol} ${line.lineTotal}',
                )),
            const SizedBox(height: AppDimensions.md),
          ],
          
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.xl),
          
          _summaryRow('Subtotal', sale.subtotal.toString(), settings.currencySymbol),
          if (sale.discount > Decimal.zero) _summaryRow('Discount', sale.discount.toString(), settings.currencySymbol, isNegative: true),
          if (sale.tax > Decimal.zero) _summaryRow('Tax', sale.tax.toString(), settings.currencySymbol),
          
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Column(
              children: [
                _summaryRow('GRAND TOTAL', sale.total.toString(), settings.currencySymbol, isBold: true),
                const Divider(height: AppDimensions.lg),
                _summaryRow('Amount Paid', sale.paidAmount.toString(), settings.currencySymbol),
                _summaryRow('Amount Due', (sale.total - sale.paidAmount).toString(), settings.currencySymbol, isBold: true, color: (sale.total - sale.paidAmount > Decimal.zero) ? AppColors.negative : null),
              ],
            ),
          ),

          if (settings.invoiceFooter.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xxl),
            Center(
              child: Text(
                settings.invoiceFooter,
                style: AppTextStyles.cardSubtitle.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, String currency, {bool isBold = false, bool isNegative = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.cardSubtitle.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text('${isNegative ? '-' : ''}$currency $value', style: AppTextStyles.cardTitle.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String price;
  final String total;

  const _InvoiceItemRow({required this.name, required this.quantity, required this.price, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('$quantity x $price', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(total, textAlign: TextAlign.right, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
