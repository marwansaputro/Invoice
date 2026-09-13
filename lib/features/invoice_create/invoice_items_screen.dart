import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../models/models.dart';
import 'add_item_sheet.dart';

/// Dedicated page listing the invoice's line items, pushed from Create
/// Invoice's "Add Item" row instead of showing the list inline in the
/// (already long) invoice form. Mutates [items] in place so the caller's
/// list is up to date as soon as this screen is popped.
class InvoiceItemsScreen extends StatefulWidget {
  final List<InvoiceItem> items;
  const InvoiceItemsScreen({super.key, required this.items});

  @override
  State<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends State<InvoiceItemsScreen> {
  double get _subtotal => widget.items.fold(0.0, (sum, i) => sum + i.lineSubtotal);

  Future<void> _addItem() async {
    final item = await showAppBottomSheet<InvoiceItem>(context, child: const AddItemSheet());
    if (item != null) setState(() => widget.items.add(item));
  }

  Future<void> _editItem(InvoiceItem item) async {
    final updated = await showAppBottomSheet<InvoiceItem>(context, child: AddItemSheet(existing: item));
    if (updated != null) {
      setState(() {
        final index = widget.items.indexWhere((i) => i.id == item.id);
        if (index != -1) widget.items[index] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: SafeArea(
        child: widget.items.isEmpty
            ? EmptyState(
                title: 'No items yet',
                message: 'Add the products or services for this invoice.',
                actionLabel: 'Add Item',
                onAction: _addItem,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  ...widget.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InvoiceItemRow(
                        item: item,
                        onTap: () => _editItem(item),
                        onDelete: () => setState(() => widget.items.removeWhere((i) => i.id == item.id)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        MoneyText(value: _subtotal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: widget.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
            ),
    );
  }
}
