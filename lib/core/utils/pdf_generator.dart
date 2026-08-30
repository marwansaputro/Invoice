import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/models.dart';

/// Builds a professional-looking, printable PDF for a given invoice,
/// mirroring the on-screen [InvoicePaper] layout.
class PdfGenerator {
  PdfGenerator._();

  static final _currency = NumberFormat.decimalPattern('id_ID');
  static final _date = DateFormat('dd MMM yyyy');

  static String _money(double v) => 'Rp${_currency.format(v.round())}';

  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Customer? customer,
    required BusinessProfile business,
  }) async {
    final doc = pw.Document();

    final primary = PdfColor.fromInt(0xFF344F68);
    final secondaryGrey = PdfColor.fromInt(0xFF6B7280);
    final danger = PdfColor.fromInt(0xFFE95B5B);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 40,
                    height: 40,
                    decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(8)),
                    alignment: pw.Alignment.center,
                    child: pw.Text('P', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(business.businessName.toUpperCase(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.invoiceNumber, style: pw.TextStyle(color: secondaryGrey, fontSize: 11)),
                        if (invoice.poNumber.isNotEmpty)
                          pw.Text('Ref: ${invoice.poNumber}', style: pw.TextStyle(color: secondaryGrey, fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice Date', style: pw.TextStyle(color: secondaryGrey, fontSize: 9)),
                      pw.Text(_date.format(invoice.invoiceDate), style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 6),
                      pw.Text('Due Date', style: pw.TextStyle(color: secondaryGrey, fontSize: 9)),
                      pw.Text(invoice.dueDate != null ? _date.format(invoice.dueDate!) : 'On Receipt', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(business.address, style: pw.TextStyle(fontSize: 9, color: secondaryGrey)),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),
              pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(customer?.name ?? 'Walk-in Customer', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              if ((customer?.address ?? '').isNotEmpty)
                pw.Text(customer!.address, style: pw.TextStyle(fontSize: 9, color: secondaryGrey)),
              pw.SizedBox(height: 20),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('QTY', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                  ]),
                  pw.TableRow(children: [
                    pw.SizedBox(height: 8),
                    pw.SizedBox(height: 8),
                    pw.SizedBox(height: 8),
                    pw.SizedBox(height: 8),
                  ]),
                  for (final item in invoice.items)
                    pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(_money(item.price), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(_money(item.lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                ],
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),
              pw.Text('PAYMENT INSTRUCTIONS', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.paymentMethod.isNotEmpty ? '${invoice.paymentMethod}:' : 'Bank Transfer:', style: pw.TextStyle(fontSize: 9, color: secondaryGrey)),
              pw.Text('${business.bankName} : ${business.bankAccountName}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _totalRow('Subtotal', _money(invoice.subtotal), secondaryGrey),
                      if (invoice.discount > 0) _totalRow('Discount', '-${_money(invoice.discount)}', secondaryGrey),
                      if (invoice.tax > 0) _totalRow('Tax', _money(invoice.tax), secondaryGrey),
                      if (invoice.shipping > 0) _totalRow('Shipping', _money(invoice.shipping), secondaryGrey),
                      pw.Divider(color: PdfColors.grey300),
                      _totalRow('TOTAL', _money(invoice.total), PdfColors.black, bold: true),
                      pw.SizedBox(height: 4),
                      _totalRow('BALANCE DUE', _money(invoice.balanceDue), danger, bold: true),
                    ],
                  ),
                ),
              ),
              if (invoice.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Text('NOTES', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.notes, style: pw.TextStyle(fontSize: 9.5, color: secondaryGrey, fontStyle: pw.FontStyle.italic)),
              ],
              if (invoice.attachmentBytes != null) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Text('ATTACHMENT', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Image(pw.MemoryImage(Uint8List.fromList(invoice.attachmentBytes!)), height: 110, fit: pw.BoxFit.contain),
              ],
              if (invoice.signatureBytes != null || invoice.isApproved) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Text('APPROVAL', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (invoice.signatureBytes != null)
                  pw.Image(pw.MemoryImage(Uint8List.fromList(invoice.signatureBytes!)), height: 50, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.isApproved ? 'Approved by ${invoice.approverName.isNotEmpty ? invoice.approverName : "customer"}' : 'Pending approval',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: invoice.isApproved ? PdfColor.fromInt(0xFF35B779) : secondaryGrey),
                ),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _totalRow(String label, String value, PdfColor color, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: bold ? 11 : 9.5, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: bold ? 11 : 9.5, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
