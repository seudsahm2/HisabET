import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/settings/data/models/app_settings_model.dart';

class InvoicePdfService {
  static Future<Uint8List> buildInvoicePdf(
    SaleInvoiceData invoiceData, {
    AppSettingsModel? settings,
  }) async {
    final pdf = pw.Document();
    final sale = invoiceData.sale;
    final lines = invoiceData.lineItems;
    final bundleLines = lines.where((line) => line.isBundle).toList();
    final singleLines = lines.where((line) => !line.isBundle).toList();
    final effectiveSettings = settings ?? AppSettingsModel.defaults();
    final currency = effectiveSettings.currencySymbol;
    final invoiceCode =
        '${effectiveSettings.invoicePrefix}-${sale.id.substring(0, 8).toUpperCase()}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            '${effectiveSettings.businessName} Invoice',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Invoice #: $invoiceCode'),
          pw.Text('Date: ${sale.createdAt.toLocal()}'),
          if (effectiveSettings.businessPhone?.isNotEmpty == true)
            pw.Text('Phone: ${effectiveSettings.businessPhone}'),
          if (effectiveSettings.businessAddress?.isNotEmpty == true)
            pw.Text('Address: ${effectiveSettings.businessAddress}'),
          if (sale.customerName != null && sale.customerName!.trim().isNotEmpty)
            pw.Text('Customer: ${sale.customerName}'),
          pw.SizedBox(height: 16),
          if (bundleLines.isNotEmpty) ...[
            pw.Text(
              'Bundle Products',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Item', 'Cartons', 'Price/Carton', 'Line Total'],
              data: bundleLines
                  .map(
                    (line) => [
                      line.productName,
                      line.quantity.toString(),
                      line.pricePerCarton.toString(),
                      line.lineTotal.toString(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          if (singleLines.isNotEmpty) ...[
            pw.Text(
              'Single Products',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const ['Item', 'Qty', 'Unit Price', 'Line Total'],
              data: singleLines
                  .map(
                    (line) => [
                      line.productName,
                      line.quantity.toString(),
                      line.unitPrice.toString(),
                      line.lineTotal.toString(),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Subtotal: $currency ${sale.subtotal}'),
                pw.Text('Discount: $currency ${sale.discount}'),
                pw.Text('Tax: $currency ${sale.tax}'),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Total: $currency ${sale.total}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Paid: $currency ${sale.paidAmount}'),
                pw.Text('Due: $currency ${sale.total - sale.paidAmount}'),
              ],
            ),
          ),
          if (effectiveSettings.invoiceFooter.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              effectiveSettings.invoiceFooter,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }
}
