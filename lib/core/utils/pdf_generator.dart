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
  static final _date = DateFormat('dd/MM/yyyy');

  static String _money(double v) => 'Rp${_currency.format(v.round())}';

  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Customer? customer,
    required BusinessProfile business,
  }) async {
    final doc = pw.Document();

    final primary = PdfColor.fromInt(0xFF150E45);
    final secondaryGrey = PdfColor.fromInt(0xFF6B7280);
    final dark = PdfColor.fromInt(0xFF202124);
    final danger = PdfColor.fromInt(0xFFE95B5B);
    final borderGrey = PdfColors.grey300;

    final paymentMethodLabel =
        invoice.paymentMethod.isNotEmpty ? invoice.paymentMethod : 'Bank Transfer';
    List<pw.InlineSpan> paymentDetailSpans(PdfColor emphasisColor) {
      final emphasized = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: emphasisColor);
      switch (paymentMethodLabel) {
        case 'QRIS':
          return [
            pw.TextSpan(
                text: business.qrisId.isNotEmpty
                    ? business.qrisId
                    : 'Scan the QRIS code to pay.'),
          ];
        case 'E-Wallet':
          return [
            pw.TextSpan(
                text: '${business.eWalletProvider.isNotEmpty ? business.eWalletProvider : 'E-Wallet'}: '),
            pw.TextSpan(text: business.eWalletNumber, style: emphasized),
          ];
        case 'Cash':
          return const [pw.TextSpan(text: 'Payment due in cash upon receipt.')];
        default:
          return [
            pw.TextSpan(text: '${business.bankName} : ${business.bankAccountName}'),
            if (business.bankAccountNumber.isNotEmpty)
              pw.TextSpan(text: '\n${business.bankAccountNumber}', style: emphasized),
          ];
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Brand accent strip
              pw.Container(height: 4, width: double.infinity, color: primary),
              pw.SizedBox(height: 18),

              // Logo + invoice title | business address & contact
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.ClipRRect(
                    horizontalRadius: 11,
                    verticalRadius: 11,
                    child: business.logoBytes != null
                        ? pw.Image(
                            pw.MemoryImage(Uint8List.fromList(business.logoBytes!)),
                            width: 42,
                            height: 42,
                            fit: pw.BoxFit.contain,
                          )
                        : pw.Container(
                            width: 42,
                            height: 42,
                            color: primary,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              business.businessName.isNotEmpty ? business.businessName[0].toUpperCase() : '?',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18),
                            ),
                          ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE ${invoice.invoiceNumber}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, fontSize: 15, color: dark)),
                        pw.SizedBox(height: 2),
                        pw.Text(business.businessName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: dark)),
                        if (business.phone.isNotEmpty) pw.Text(business.phone, style: pw.TextStyle(fontSize: 9, color: secondaryGrey)),
                        if (invoice.poNumber.isNotEmpty)
                          pw.Text('Ref: ${invoice.poNumber}', style: pw.TextStyle(color: secondaryGrey, fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.SizedBox(
                    width: 160,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (business.address.isNotEmpty)
                          pw.Text(business.address, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, color: secondaryGrey)),
                        if (business.email.isNotEmpty)
                          pw.Text(business.email, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, color: secondaryGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: borderGrey),
              pw.SizedBox(height: 14),

              // Bill to | invoice meta
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(customer?.name ?? 'Walk-in Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if ((customer?.address ?? '').isNotEmpty)
                          pw.Text(customer!.address, style: pw.TextStyle(fontSize: 9, color: secondaryGrey)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _metaRow('INVOICE DATE', _date.format(invoice.invoiceDate), secondaryGrey, dark),
                        pw.SizedBox(height: 3),
                        _metaRow('INVOICE DUE', invoice.dueDate != null ? _date.format(invoice.dueDate!) : 'Due On Receipt', secondaryGrey, dark),
                        pw.SizedBox(height: 3),
                        _metaRow('BALANCE DUE', _money(invoice.balanceDue), secondaryGrey, danger),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2.5),
                  4: pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('QTY', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('DISCOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                    pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: secondaryGrey)),
                  ]),
                  pw.TableRow(children: [
                    pw.SizedBox(height: 8),
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
                        child: item.discount > 0
                            ? pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(_money(item.discount), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                                  pw.Text(
                                    '(${(item.lineSubtotal > 0 ? item.discount / item.lineSubtotal * 100 : 0).toStringAsFixed(0)}%)',
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(fontSize: 8, color: secondaryGrey),
                                  ),
                                ],
                              )
                            : pw.Text(_money(0), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, color: secondaryGrey)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Text(_money(item.lineTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                ],
              ),
              pw.Divider(color: borderGrey),
              pw.SizedBox(height: 14),

              // Payment instructions | totals
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: borderGrey), borderRadius: pw.BorderRadius.circular(6)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PAYMENT INSTRUCTIONS', style: pw.TextStyle(fontSize: 8.5, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(fontSize: 9.5, color: secondaryGrey),
                              children: [
                                pw.TextSpan(
                                  text: '$paymentMethodLabel: ',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: dark),
                                ),
                                ...paymentDetailSpans(dark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _totalRow('Subtotal', _money(invoice.subtotal), secondaryGrey),
                        if (invoice.discount > 0) _totalRow('Discount', '-${_money(invoice.discount)}', secondaryGrey),
                        if (invoice.tax > 0) _totalRow('Tax', _money(invoice.tax), secondaryGrey),
                        if (invoice.shipping > 0) _totalRow('Shipping', _money(invoice.shipping), secondaryGrey),
                        pw.Divider(color: borderGrey),
                        _totalRow('TOTAL', _money(invoice.total), dark, bold: true),
                        if (invoice.amountPaid > 0) _totalRow('Paid (${_date.format(invoice.updatedAt)})', _money(invoice.amountPaid), secondaryGrey),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4),
                          padding: const pw.EdgeInsets.only(top: 4),
                          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: danger, width: 1))),
                          child: _totalRow('BALANCE DUE', _money(invoice.balanceDue), danger, bold: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (invoice.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Divider(color: borderGrey),
                pw.SizedBox(height: 10),
                pw.Text('NOTES', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.notes, style: pw.TextStyle(fontSize: 9.5, color: secondaryGrey, fontStyle: pw.FontStyle.italic)),
              ],
              if (invoice.attachmentBytes != null) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: borderGrey),
                pw.SizedBox(height: 10),
                pw.Text('ATTACHMENT', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Image(pw.MemoryImage(Uint8List.fromList(invoice.attachmentBytes!)), height: 110, fit: pw.BoxFit.contain),
              ],
              if (invoice.signatureBytes != null || invoice.isApproved) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: borderGrey),
                pw.SizedBox(height: 10),
                pw.Text('APPROVAL', style: pw.TextStyle(fontSize: 9, color: secondaryGrey, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (invoice.signatureBytes != null)
                  pw.Image(pw.MemoryImage(Uint8List.fromList(invoice.signatureBytes!)), height: 50, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.isApproved ? 'Approved by ${invoice.approverName.isNotEmpty ? invoice.approverName : "customer"}' : 'Pending approval',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: invoice.isApproved ? PdfColor.fromInt(0xFF2ECC71) : secondaryGrey),
                ),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _metaRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: labelColor)),
        pw.SizedBox(width: 6),
        pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: valueColor)),
      ],
    );
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
