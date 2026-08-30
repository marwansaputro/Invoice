import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../animations/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'widgets.dart';

/// Invoice list/dashboard row card. Wrapped in a [Hero] so tapping it
/// morphs smoothly into the Invoice Detail screen.
class InvoiceListCard extends StatelessWidget {
  final Invoice invoice;
  final String customerName;
  final VoidCallback onTap;

  const InvoiceListCard({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = invoice.items.isNotEmpty ? invoice.items.first : null;
    final extraItems = invoice.items.length - 1;

    return Hero(
      tag: 'invoice-${invoice.id}',
      child: Material(
        type: MaterialType.transparency,
        child: AppCard(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(invoice.invoiceNumber,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        if (invoice.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite_rounded, size: 15, color: AppColors.secondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(customerName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.date(invoice.invoiceDate),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (firstItem != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        extraItems > 0 ? '${firstItem.name} +$extraItems more' : firstItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    value: invoice.total,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: invoice.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row inside the itemized product table, used in both the
/// Create Invoice items list and the printable invoice preview table.
class InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvoiceItemRow({super.key, required this.item, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 6),
                Text(
                  '${AppFormatters.money(item.price)}  ×  ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          MoneyText(value: item.lineTotal, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// The bill summary block (subtotal / discount / tax / shipping / total)
/// shown in Create Invoice and the invoice preview.
class TotalSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;
  final bool animateTotal;
  final bool compact;

  const TotalSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shipping,
    required this.total,
    this.animateTotal = true,
    this.compact = false,
  });

  Widget _row(String label, double value, {bool negative = false, bool bold = false}) {
    final text = negative && value > 0
        ? '-${AppFormatters.money(value)}'
        : AppFormatters.money(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 15 : 13.5)),
          Text(text,
              style: TextStyle(
                  color: negative && value > 0 ? AppColors.danger : (bold ? AppColors.textPrimary : AppColors.textPrimary),
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: bold ? 15 : 13.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _row('Subtotal', subtotal),
        if (discount > 0) _row('Discount', discount, negative: true),
        if (tax > 0) _row('Tax', tax),
        if (shipping > 0) _row('Shipping', shipping),
        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              animateTotal
                  ? AnimatedNumber(value: total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary))
                  : MoneyText(value: total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
    return compact ? content : AppCard(child: content);
  }
}

/// The full "printable paper" look for the invoice — used both on-screen
/// in Invoice Preview and mirrored by the PDF generator.
class InvoicePaper extends StatelessWidget {
  final Invoice invoice;
  final Customer? customer;
  final BusinessProfile business;

  const InvoicePaper({super.key, required this.invoice, required this.customer, required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + business + invoice number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedEntry(
                duration: AppDurations.medium,
                offsetY: 0,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.icecream_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.businessName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF202124))),
                    const SizedBox(height: 2),
                    Text(invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary)),
                    if (invoice.poNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Ref: ${invoice.poNumber}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(business.address,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Bill to
          const Text('BILL TO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(customer?.name ?? 'Walk-in Customer', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          if ((customer?.address ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(customer!.address, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 20),

          // Table
          Row(
            children: const [
              Expanded(flex: 4, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
              Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          ...invoice.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: Text(item.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                  Expanded(flex: 2, child: Text(AppFormatters.money(item.price), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 3, child: Text(AppFormatters.money(item.lineTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Payment instructions
          const Text('PAYMENT INSTRUCTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(invoice.paymentMethod.isNotEmpty ? '${invoice.paymentMethod}:' : 'Bank Transfer:',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('${business.bankName} : ${business.bankAccountName}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          TotalSummary(
            subtotal: invoice.subtotal,
            discount: invoice.discount,
            tax: invoice.tax,
            shipping: invoice.shipping,
            total: invoice.total,
            compact: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BALANCE DUE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.danger)),
              Text(AppFormatters.money(invoice.balanceDue),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.danger)),
            ],
          ),

          if (invoice.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text('NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Text(invoice.notes, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          if (invoice.attachmentBytes != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text('ATTACHMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                Uint8List.fromList(invoice.attachmentBytes!),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (invoice.signatureBytes != null || invoice.isApproved) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text('APPROVAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            if (invoice.signatureBytes != null)
              Image.memory(Uint8List.fromList(invoice.signatureBytes!), height: 70, fit: BoxFit.contain, alignment: Alignment.centerLeft),
            const SizedBox(height: 4),
            Text(
              invoice.isApproved
                  ? 'Approved by ${invoice.approverName.isNotEmpty ? invoice.approverName : "customer"}'
                  : 'Pending approval',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: invoice.isApproved ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
