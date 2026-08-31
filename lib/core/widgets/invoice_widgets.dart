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
    final accent = AppColors.themedPrimary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: accent.withOpacity(isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.receipt_long_rounded,
                    color: accent, size: 22),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        if (invoice.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.favorite_rounded,
                                size: 15, color: AppColors.secondary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(customerName,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(AppFormatters.date(invoice.invoiceDate),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (firstItem != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        extraItems > 0
                            ? '${firstItem.name} +$extraItems more'
                            : firstItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5),
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

  const InvoiceItemRow(
      {super.key, required this.item, this.onTap, this.onDelete});

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
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 6),
                Text(
                  '${AppFormatters.money(item.price)}  ×  ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          MoneyText(
              value: item.lineTotal,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
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

  Widget _row(String label, double value,
      {bool negative = false, bool bold = false}) {
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
                  color: bold ? null : AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 15 : 13.5)),
          Text(text,
              style: TextStyle(
                  color: negative && value > 0 ? AppColors.danger : null,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  fontSize: bold ? 15 : 13.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themedPrimary(context);
    final content = Column(
      children: [
        _row('Subtotal', subtotal),
        if (discount > 0) _row('Discount', discount, negative: true),
        if (tax > 0) _row('Tax', tax),
        if (shipping > 0) _row('Shipping', shipping),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              animateTotal
                  ? AnimatedNumber(
                      value: total,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: accent))
                  : MoneyText(
                      value: total,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: accent)),
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

  const InvoicePaper(
      {super.key,
      required this.invoice,
      required this.customer,
      required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 28,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand accent strip
          Container(
              height: 5, width: double.infinity, color: AppColors.primary),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + invoice title | business address & contact —
                // the address column moves below on narrow (phone-width)
                // screens so the title never gets squeezed into a
                // letter-by-letter wrap.
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;
                  final hasAddressBlock = business.address.isNotEmpty || business.email.isNotEmpty;

                  final addressBlock = !hasAddressBlock
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            if (business.address.isNotEmpty)
                              Text(business.address,
                                  textAlign: isNarrow ? TextAlign.left : TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                      height: 1.5)),
                            if (business.email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(business.email,
                                    textAlign: isNarrow ? TextAlign.left : TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary)),
                              ),
                          ],
                        );

                  final titleRow = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedEntry(
                        duration: AppDurations.medium,
                        offsetY: 0,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            business.businessName.isNotEmpty
                                ? business.businessName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text('INVOICE ${invoice.invoiceNumber}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 17,
                                        color: Color(0xFF202124))),
                                StatusBadge(status: invoice.status),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(business.businessName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF202124))),
                            if (business.phone.isNotEmpty)
                              Text(business.phone,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary)),
                            if (invoice.poNumber.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Ref: ${invoice.poNumber}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ),
                            if (isNarrow && hasAddressBlock) ...[
                              const SizedBox(height: 8),
                              addressBlock,
                            ],
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 10),
                        SizedBox(width: 130, child: addressBlock),
                      ],
                    ],
                  );

                  return titleRow;
                }),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Bill to | invoice meta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILL TO',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.6)),
                          const SizedBox(height: 6),
                          Text(customer?.name ?? 'Walk-in Customer',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF202124))),
                          if ((customer?.address ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(customer!.address,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary)),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MetaRow('INVOICE DATE',
                              AppFormatters.dateInput(invoice.invoiceDate)),
                          const SizedBox(height: 10),
                          _MetaRow(
                              'DUE DATE',
                              invoice.dueDate != null
                                  ? AppFormatters.dateInput(invoice.dueDate!)
                                  : 'On Receipt'),
                          const SizedBox(height: 10),
                          _MetaRow('BALANCE DUE',
                              AppFormatters.money(invoice.balanceDue),
                              valueColor: AppColors.danger),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Items — a clean, spacious receipt-style list instead of
                // a cramped multi-column grid (which truncated on narrow
                // screens). Each item gets its own two-line block.
                const Text('ITEMS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 12),
                ...invoice.items.map((item) {
                  final pct = item.lineSubtotal > 0
                      ? (item.discount / item.lineSubtotal * 100)
                      : 0;
                  final qtyStr = item.quantity
                      .toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                      color: Color(0xFF202124))),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                      '${AppFormatters.money(item.price)} × $qtyStr',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  if (item.discount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger
                                            .withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          '-${AppFormatters.money(item.discount)} (${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%)',
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.danger)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppFormatters.money(item.lineTotal),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF202124))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Payment instructions | totals — stacks vertically on
                // narrow (phone-width) screens instead of overflowing.
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 380;

                  final paymentBox = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PAYMENT INSTRUCTIONS',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5),
                            children: [
                              TextSpan(
                                  text:
                                      '${invoice.paymentMethod.isNotEmpty ? invoice.paymentMethod : 'Bank Transfer'}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF202124))),
                              TextSpan(
                                  text:
                                      '${business.bankName} : ${business.bankAccountName}'),
                              if (business.bankAccountNumber.isNotEmpty)
                                TextSpan(
                                    text: '\n${business.bankAccountNumber}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  final totalsBox = Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TotalRow('SUBTOTAL', invoice.subtotal),
                      if (invoice.discount > 0)
                        _TotalRow('DISCOUNT', invoice.discount,
                            negative: true),
                      if (invoice.tax > 0) _TotalRow('TAX', invoice.tax),
                      if (invoice.shipping > 0)
                        _TotalRow('SHIPPING', invoice.shipping),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1)),
                      _TotalRow('TOTAL', invoice.total, bold: true),
                      if (invoice.amountPaid > 0)
                        _TotalRow(
                            'PAID (${AppFormatters.dateInput(invoice.updatedAt)})',
                            invoice.amountPaid),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: AppColors.danger, width: 1.4)),
                        ),
                        width: double.infinity,
                        child: _TotalRow('BALANCE DUE', invoice.balanceDue,
                            bold: true, color: AppColors.danger),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        paymentBox,
                        const SizedBox(height: 16),
                        totalsBox,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: paymentBox),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: totalsBox),
                    ],
                  );
                }),

                if (invoice.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text('NOTES',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  Text(invoice.notes,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic)),
                ],
                if (invoice.attachmentBytes != null) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text('ATTACHMENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6)),
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
                  const Text('APPROVAL',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  if (invoice.signatureBytes != null)
                    Image.memory(Uint8List.fromList(invoice.signatureBytes!),
                        height: 70,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft),
                  const SizedBox(height: 4),
                  Text(
                    invoice.isApproved
                        ? 'Approved by ${invoice.approverName.isNotEmpty ? invoice.approverName : "customer"}'
                        : 'Pending approval',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: invoice.isApproved
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A right-aligned label/value pair used in the invoice header meta block
/// (invoice date, due date, balance due). Label sits above the value so
/// neither ever has to fight the other for horizontal room.
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? const Color(0xFF202124))),
      ],
    );
  }
}

/// A totals-block row (subtotal / tax / total / balance due) used in the
/// invoice paper's payment summary column.
class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final bool negative;
  final Color? color;
  const _TotalRow(this.label, this.value,
      {this.bold = false, this.negative = false, this.color});

  @override
  Widget build(BuildContext context) {
    final text = negative && value > 0
        ? '-${AppFormatters.money(value)}'
        : AppFormatters.money(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: bold ? 12.5 : 11,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color ??
                        (bold
                            ? const Color(0xFF202124)
                            : AppColors.textSecondary))),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: bold ? 12.5 : 11,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: color ?? const Color(0xFF202124))),
        ],
      ),
    );
  }
}
