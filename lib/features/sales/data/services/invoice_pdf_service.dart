import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';

class InvoicePdfService {
  static Future<Uint8List> buildInvoicePdf(SaleInvoiceData invoiceData) async {
    final pdf = pw.Document();
    final sale = invoiceData.sale;
    final lines = invoiceData.lineItems;
    final bundleLines = lines.where((line) => line.isBundle).toList();
    final singleLines = lines.where((line) => !line.isBundle).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'HisabET Invoice',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Invoice #: ${sale.id.substring(0, 8).toUpperCase()}'),
          pw.Text('Date: ${sale.createdAt.toLocal()}'),
          if (sale.customerName != null && sale.customerName!.trim().isNotEmpty)
            pw.Text('Customer: ${sale.customerName}'),
          pw.SizedBox(height: 16),
          if (bundleLines.isNotEmpty) ...[
            pw.Text(
              'Bundle Products',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
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
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            ),
            pw.SizedBox(height: 12),
          ],
          if (singleLines.isNotEmpty) ...[
            pw.Text(
              'Single Products',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
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
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Subtotal: ETB ${sale.subtotal}'),
                pw.Text('Discount: ETB ${sale.discount}'),
                pw.Text('Tax: ETB ${sale.tax}'),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Total: ETB ${sale.total}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Paid: ETB ${sale.paidAmount}'),
                pw.Text('Due: ETB ${sale.total - sale.paidAmount}'),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
