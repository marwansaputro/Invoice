import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../models/models.dart';

const _uuid = Uuid();

/// How the value typed into the Discount field should be interpreted:
/// a flat Rupiah amount, or a percentage of the item's line subtotal.
enum _DiscountType { flat, percent }

/// Bottom sheet form for adding or editing a single invoice item
/// (spec section 12): name, price, quantity, discount, tax.
class AddItemSheet extends StatefulWidget {
  final InvoiceItem? existing;
  const AddItemSheet({super.key, this.existing});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _qty;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  _DiscountType _discountType = _DiscountType.flat;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e != null ? _trim(e.price) : '');
    _qty = TextEditingController(text: e != null ? _trim(e.quantity) : '1');
    _discount = TextEditingController(text: e != null ? _trim(e.discount) : '');
    _tax = TextEditingController(text: e != null ? _trim(e.tax) : '');
  }

  String _trim(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  double get _flatDiscount {
    final entered = double.tryParse(_discount.text.replaceAll(',', '')) ?? 0;
    if (_discountType == _DiscountType.flat) return entered;
    final price = double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
    final qty = double.tryParse(_qty.text.replaceAll(',', '')) ?? 1;
    return price * qty * entered / 100;
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final item = InvoiceItem(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _name.text.trim(),
      price: double.tryParse(_price.text.replaceAll(',', '')) ?? 0,
      quantity: double.tryParse(_qty.text.replaceAll(',', '')) ?? 1,
      discount: _flatDiscount,
      tax: double.tryParse(_tax.text.replaceAll(',', '')) ?? 0,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing != null ? 'Edit Item' : 'Add Item',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        AppTextField(label: 'Product Name', controller: _name, hint: 'e.g. Waffle Tinggi Ori'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Price',
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: const Padding(padding: EdgeInsets.only(left: 14), child: Text('Rp', style: TextStyle(color: AppColors.textSecondary))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Quantity',
                controller: _qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Discount',
                controller: _discount,
                hint: '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: _DiscountTypeDropdown(
                  value: _discountType,
                  onChanged: (v) => setState(() => _discountType = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Tax',
                controller: _tax,
                hint: AppDatabase.settings.defaultTaxPercent > 0
                    ? '0 (default ${AppDatabase.settings.defaultTaxPercent.toStringAsFixed(0)}%)'
                    : '0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AppButton(
          label: widget.existing != null ? 'Save Changes' : 'Add Item',
          icon: Icons.check_rounded,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Compact "%" / "Rp" dropdown shown inside the Discount field, letting
/// the typed value be interpreted as a percentage of the line subtotal
/// or as a flat Rupiah amount.
class _DiscountTypeDropdown extends StatelessWidget {
  final _DiscountType value;
  final ValueChanged<_DiscountType> onChanged;
  const _DiscountTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DiscountType>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: _DiscountType.flat, child: Text('Rp')),
            DropdownMenuItem(value: _DiscountType.percent, child: Text('%')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
