import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../customers/add_customer_sheet.dart';
import '../invoice_preview/invoice_preview_screen.dart';
import '../settings/settings_screen.dart' show BusinessProfileSheet;
import '../../data/database/app_database.dart';
import 'add_item_sheet.dart';

/// Create / Edit Invoice screen. When [existingInvoiceId] is provided the
/// form is pre-filled for editing; otherwise a fresh draft is built.
///
/// Laid out as a flat stack of icon-led rows (per the reference design)
/// rather than boxed, labelled sections.
class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? existingInvoiceId;
  const CreateInvoiceScreen({super.key, this.existingInvoiceId});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  late String _customerId;
  late String _invoiceNumber;
  late DateTime _invoiceDate;
  DateTime? _dueDate;
  bool _dueOnReceipt = true;
  final List<InvoiceItem> _items = [];
  double _discount = 0;
  double _tax = 0;
  double _shipping = 0;
  final _notesController = TextEditingController();
  bool _saving = false;
  late final TextEditingController _poController;
  late final TextEditingController _approverController;
  String _paymentMethod = '';
  Uint8List? _attachmentBytes;
  Uint8List? _signatureBytes;
  bool _isApproved = false;
  bool _markAsPaid = false;

  static const _paymentMethods = ['Bank Transfer', 'Cash', 'QRIS', 'E-Wallet'];

  Invoice? get _existing => widget.existingInvoiceId == null
      ? null
      : ref.read(invoiceRepositoryProvider.notifier).byId(widget.existingInvoiceId!);

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    if (existing != null) {
      _customerId = existing.customerId;
      _invoiceNumber = existing.invoiceNumber;
      _invoiceDate = existing.invoiceDate;
      _dueDate = existing.dueDate;
      _dueOnReceipt = existing.dueDate == null;
      _items.addAll(existing.items);
      _discount = existing.discount;
      _tax = existing.tax;
      _shipping = existing.shipping;
      _notesController.text = existing.notes;
      _paymentMethod = existing.paymentMethod;
      _attachmentBytes = existing.attachmentBytes != null ? Uint8List.fromList(existing.attachmentBytes!) : null;
      _signatureBytes = existing.signatureBytes != null ? Uint8List.fromList(existing.signatureBytes!) : null;
      _isApproved = existing.isApproved;
      _markAsPaid = existing.status == InvoiceStatus.paid;
    } else {
      final customers = ref.read(customerRepositoryProvider);
      _customerId = customers.isNotEmpty ? customers.first.id : '';
      _invoiceNumber = ref.read(invoiceRepositoryProvider.notifier).generateInvoiceNumber();
      _invoiceDate = DateTime.now();
      _notesController.text = 'Thank you for shopping with us!';
    }
    _poController = TextEditingController(text: existing?.poNumber ?? '');
    _approverController = TextEditingController(text: existing?.approverName ?? '');
  }

  String _trim(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _notesController.dispose();
    _poController.dispose();
    _approverController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.lineSubtotal);
  double get _total => _subtotal - _discount + _tax + _shipping;
  double get _amountPaid => _markAsPaid ? _total : (_existing?.amountPaid ?? 0);
  double get _balanceDue => (_total - _amountPaid).clamp(0, double.infinity);

  Future<void> _pickCustomer() async {
    final customers = ref.read(customerRepositoryProvider);
    final selected = await showAppBottomSheet<String>(
      context,
      child: _CustomerPickerSheet(customers: customers, selectedId: _customerId),
    );
    if (selected == 'NEW') {
      final result = await showAppBottomSheet<Map<String, String>>(context, child: const AddCustomerSheet());
      if (result != null) {
        final created = ref.read(customerRepositoryProvider.notifier).add(
              name: result['name']!,
              phone: result['phone'] ?? '',
              email: result['email'] ?? '',
              address: result['address'] ?? '',
            );
        setState(() => _customerId = created.id);
      }
    } else if (selected != null) {
      setState(() => _customerId = selected);
    }
  }

  Future<void> _editBusinessInfo() async {
    await showAppBottomSheet(context, child: BusinessProfileSheet(business: AppDatabase.business));
    if (mounted) setState(() {});
  }

  Future<void> _addItem() async {
    final item = await showAppBottomSheet<InvoiceItem>(context, child: const AddItemSheet());
    if (item != null) setState(() => _items.add(item));
  }

  Future<void> _editItem(InvoiceItem item) async {
    final updated = await showAppBottomSheet<InvoiceItem>(context, child: AddItemSheet(existing: item));
    if (updated != null) {
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) _items[index] = updated;
      });
    }
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _attachmentBytes = bytes);
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now()) : _invoiceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
          _dueOnReceipt = false;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  Future<void> _editAmount({required String title, required double value, required ValueChanged<double> onSaved}) async {
    final controller = TextEditingController(text: value == 0 ? '' : _trim(value));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '')) ?? 0),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onSaved(result);
  }

  Future<void> _pickPaymentMethod() async {
    final selected = await showAppBottomSheet<String>(
      context,
      child: _PaymentMethodSheet(methods: _paymentMethods, selected: _paymentMethod),
    );
    if (selected != null) setState(() => _paymentMethod = selected == _paymentMethod ? '' : selected);
  }

  Future<void> _openSignatureSheet() async {
    await showAppBottomSheet<void>(
      context,
      child: _SignatureSheet(
        initialBytes: _signatureBytes,
        onChanged: (bytes) => setState(() => _signatureBytes = bytes),
      ),
    );
  }

  Invoice _buildInvoice() {
    final repo = ref.read(invoiceRepositoryProvider.notifier);
    final invoice = _existing ??
        Invoice(
          id: _uniqueId(),
          invoiceNumber: _invoiceNumber,
          customerId: _customerId,
          invoiceDate: _invoiceDate,
        );
    invoice.customerId = _customerId;
    invoice.invoiceNumber = _invoiceNumber;
    invoice.invoiceDate = _invoiceDate;
    invoice.dueDate = _dueOnReceipt ? null : _dueDate;
    invoice.items = List.of(_items);
    invoice.discount = _discount;
    invoice.tax = _tax;
    invoice.shipping = _shipping;
    invoice.notes = _notesController.text.trim();
    invoice.poNumber = _poController.text.trim();
    invoice.paymentMethod = _paymentMethod;
    invoice.attachmentBytes = _attachmentBytes;
    invoice.signatureBytes = _signatureBytes;
    invoice.isApproved = _isApproved;
    invoice.approverName = _approverController.text.trim();
    if (_markAsPaid) {
      invoice.status = InvoiceStatus.paid;
      invoice.amountPaid = invoice.total;
    } else if (invoice.status == InvoiceStatus.draft && _items.isNotEmpty) {
      invoice.status = InvoiceStatus.unpaid;
    }
    repo.save(invoice);
    repo.commitInvoiceNumberIfNeeded(invoice);
    return invoice;
  }

  String _uniqueId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _save({bool andPreview = false}) async {
    if (_customerId.isEmpty) {
      AppSnackbar.show(context, message: 'Please select a customer first', icon: Icons.info_rounded, color: AppColors.warning);
      return;
    }
    if (_items.isEmpty) {
      AppSnackbar.show(context, message: 'Add at least one item', icon: Icons.info_rounded, color: AppColors.warning);
      return;
    }
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final invoice = _buildInvoice();
    if (!mounted) return;
    setState(() => _saving = false);
    if (andPreview) {
      Navigator.of(context).pushReplacement(SlideFadeRoute(page: InvoicePreviewScreen(invoiceId: invoice.id)));
    } else {
      AppSnackbar.show(context, message: 'Invoice saved');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerRepositoryProvider);
    final business = AppDatabase.business;
    Customer? customer;
    try {
      customer = customers.firstWhere((c) => c.id == _customerId);
    } catch (_) {
      customer = null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(_existing != null ? 'Edit Invoice' : 'Create Invoice'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(),
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
          children: [
            // Invoice # / Due date
            _FlatRow(
              icon: Icons.tag_rounded,
              iconColor: AppColors.secondary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice #', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(_invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _pickDate(isDueDate: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_dueOnReceipt ? 'Due on Receipt' : 'Due Date',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(_dueOnReceipt ? _fmtDate(_invoiceDate) : _fmtDate(_dueDate!),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.primary,
              onTap: () => _pickDate(isDueDate: false),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Invoice Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(_fmtDate(_invoiceDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.info_rounded,
              iconColor: AppColors.primary,
              onTap: _editBusinessInfo,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              child: Text(business.businessName.isNotEmpty ? business.businessName : 'Business Info',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.person_rounded,
              iconColor: AppColors.warning,
              onTap: _pickCustomer,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              child: Text(
                customer != null ? 'To: ${customer.name}' : 'To: Select Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: customer != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.bookmark_rounded,
              iconColor: AppColors.secondary,
              child: TextField(
                controller: _poController,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'PO / Reference Number',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items
            _FlatRow(
              icon: Icons.add_circle_rounded,
              iconColor: AppColors.primary,
              onTap: _addItem,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              child: const Text('Add Item', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InvoiceItemRow(
                    item: item,
                    onTap: () => _editItem(item),
                    onDelete: () => setState(() => _items.removeWhere((i) => i.id == item.id)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _DarkBar(label: 'Subtotal', value: _subtotal),
            const SizedBox(height: 16),

            // Adjustments
            _FlatRow(
              icon: Icons.percent_rounded,
              iconColor: AppColors.secondary,
              onTap: () => _editAmount(title: 'Discount', value: _discount, onSaved: (v) => setState(() => _discount = v)),
              child: _AmountRowContent(label: 'Discount', value: _discount),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              onTap: () => _editAmount(title: 'Tax', value: _tax, onSaved: (v) => setState(() => _tax = v)),
              child: _AmountRowContent(label: 'Tax', value: _tax),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.local_shipping_rounded,
              iconColor: AppColors.success,
              onTap: () => _editAmount(title: 'Shipping', value: _shipping, onSaved: (v) => setState(() => _shipping = v)),
              child: _AmountRowContent(label: 'Shipping', value: _shipping),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.summarize_rounded,
              iconColor: AppColors.primary,
              child: _AmountRowContent(label: 'Total', value: _total, bold: true),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              child: _AmountRowContent(label: 'Payments', value: _amountPaid),
            ),
            const SizedBox(height: 10),
            _DarkBar(label: 'Balance Due', value: _balanceDue),
            const SizedBox(height: 16),

            // Attachment
            _FlatRow(
              icon: Icons.image_rounded,
              iconColor: AppColors.secondary,
              onTap: _pickAttachment,
              trailing: _attachmentBytes == null
                  ? const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary)
                  : PressableScale(
                      onTap: () => setState(() => _attachmentBytes = null),
                      child: const Icon(Icons.close_rounded, color: AppColors.danger),
                    ),
              child: _attachmentBytes == null
                  ? const Text('Add Photo', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_attachmentBytes!, height: 44, width: 44, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 10),

            // Payment instruction
            _FlatRow(
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.primary,
              onTap: _pickPaymentMethod,
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Instruction', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_paymentMethod.isEmpty ? 'Bank Transfer' : _paymentMethod, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Signature
            _FlatRow(
              icon: Icons.draw_rounded,
              iconColor: AppColors.primary,
              onTap: _openSignatureSheet,
              trailing: _signatureBytes != null
                  ? Image.memory(_signatureBytes!, height: 32, width: 60, fit: BoxFit.contain)
                  : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              child: const Text('Signature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            _FlatRow(
              icon: Icons.verified_rounded,
              iconColor: AppColors.success,
              trailing: Switch(value: _isApproved, onChanged: (v) => setState(() => _isApproved = v)),
              child: const Text('Approved by customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            if (_isApproved) ...[
              const SizedBox(height: 10),
              _FlatRow(
                icon: Icons.badge_rounded,
                iconColor: AppColors.success,
                child: TextField(
                  controller: _approverController,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Approver name'),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Notes
            _FlatRow(
              icon: Icons.edit_note_rounded,
              iconColor: AppColors.textSecondary,
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Add a note for your customer...'),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: PressableScale(
                onTap: () => setState(() => _markAsPaid = !_markAsPaid),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    color: _markAsPaid ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _markAsPaid ? AppColors.success : AppColors.primary, width: 1.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_markAsPaid) ...[
                        const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _markAsPaid ? 'Marked as Paid' : 'Mark Paid',
                        style: TextStyle(
                          color: _markAsPaid ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _save(andPreview: true),
        icon: _saving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.visibility_rounded),
        label: Text(_saving ? 'Saving...' : 'Save & Preview'),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Flat, icon-led row card used throughout Create Invoice, matching the
/// reference design's continuous list style (no boxed section headers).
class _FlatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _FlatRow({required this.icon, required this.iconColor, required this.child, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.14), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    if (onTap == null) return content;
    return PressableScale(scaleDown: 0.99, onTap: onTap, child: content);
  }
}

/// Dark navy summary bar (Subtotal / Balance Due), matching the reference.
class _DarkBar extends StatelessWidget {
  final String label;
  final double value;
  const _DarkBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          MoneyText(value: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AmountRowContent extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _AmountRowContent({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w700, fontSize: bold ? 15 : 14)),
        MoneyText(
          value: value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontSize: bold ? 15 : 14,
            color: bold ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentMethodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  final List<String> methods;
  final String selected;
  const _PaymentMethodSheet({required this.methods, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods
              .map((m) => _PaymentMethodChip(
                    label: m,
                    selected: selected == m,
                    onTap: () => Navigator.pop(context, m),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Bottom sheet wrapper around [_SignaturePad] so the drawing surface only
/// takes over the screen when the user taps the Signature row.
class _SignatureSheet extends StatelessWidget {
  final Uint8List? initialBytes;
  final ValueChanged<Uint8List?> onChanged;
  const _SignatureSheet({required this.initialBytes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        _SignaturePad(initialBytes: initialBytes, onChanged: onChanged),
        const SizedBox(height: 14),
        AppButton(label: 'Done', expand: true, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

/// Free-hand signature capture pad — draws strokes on a canvas and
/// exports the result as PNG bytes whenever a stroke is completed.
class _SignaturePad extends StatefulWidget {
  final Uint8List? initialBytes;
  final ValueChanged<Uint8List?> onChanged;
  const _SignaturePad({this.initialBytes, required this.onChanged});

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final _repaintKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _hasDrawn = false;

  void _addPoint(Offset point) => setState(() => _points.add(point));
  void _endStroke() => setState(() => _points.add(null));

  Future<void> _capture() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    widget.onChanged(byteData.buffer.asUint8List());
  }

  void _clear() {
    setState(() {
      _points.clear();
      _hasDrawn = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Draw below', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textSecondary)),
            TextButton(onPressed: _clear, child: const Text('Clear')),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFFF4F5F7),
            child: RepaintBoundary(
              key: _repaintKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.initialBytes != null && !_hasDrawn)
                    Image.memory(widget.initialBytes!, fit: BoxFit.contain),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) {
                      _hasDrawn = true;
                      _addPoint(d.localPosition);
                    },
                    onPanUpdate: (d) => _addPoint(d.localPosition),
                    onPanEnd: (_) {
                      _endStroke();
                      _capture();
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => oldDelegate.points != points;
}

class _CustomerPickerSheet extends StatelessWidget {
  final List<Customer> customers;
  final String selectedId;
  const _CustomerPickerSheet({required this.customers, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: SingleChildScrollView(
            child: Column(
              children: customers
                  .map((c) => PressableScale(
                        scaleDown: 0.99,
                        onTap: () => Navigator.pop(context, c.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.id == selectedId ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                              if (c.id == selectedId) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppButton(
          label: '+ New Customer',
          type: AppButtonStyleType.outline,
          expand: true,
          onPressed: () => Navigator.pop(context, 'NEW'),
        ),
      ],
    );
  }
}
