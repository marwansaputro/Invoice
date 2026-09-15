import 'package:flutter/material.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';

/// Bottom sheet for creating or editing a customer. Returns a map of
/// field values via Navigator.pop for the caller to persist.
class AddCustomerSheet extends StatefulWidget {
  final Customer? existing;
  final VoidCallback? onDelete;
  const AddCustomerSheet({super.key, this.existing, this.onDelete});

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _address = TextEditingController(text: e?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'address': _address.text.trim(),
    });
  }

  Future<void> _delete() async {
    final confirm = await showScaleFadeDialog<bool>(
      context,
      child: _ConfirmDeleteCustomerDialog(customerName: widget.existing!.name),
    );
    if (confirm == true && mounted) {
      widget.onDelete?.call();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing != null ? 'Edit Customer' : 'New Customer',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          AppTextField(label: 'Full Name', controller: _name, hint: 'e.g. Mas Pra'),
          const SizedBox(height: 14),
          AppTextField(label: 'Phone Number', controller: _phone, hint: '0812-xxxx-xxxx', keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          AppTextField(label: 'Email', controller: _email, hint: 'name@email.com', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          AppTextField(label: 'Address', controller: _address, hint: 'Street, city...', maxLines: 2),
          const SizedBox(height: 22),
          AppButton(
            label: widget.existing != null ? 'Save Changes' : 'Add Customer',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _submit,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'Delete Customer',
              type: AppButtonStyleType.danger,
              icon: Icons.delete_outline_rounded,
              expand: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmDeleteCustomerDialog extends StatelessWidget {
  final String customerName;
  const _ConfirmDeleteCustomerDialog({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.solidSurface(context),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 36),
              const SizedBox(height: 14),
              Text('Delete $customerName?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Their invoices will be kept, but no longer linked to a customer. This action cannot be undone.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      type: AppButtonStyleType.outline,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Delete',
                      type: AppButtonStyleType.danger,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
