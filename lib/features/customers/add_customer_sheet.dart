import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';

/// Bottom sheet for creating or editing a customer. Returns a map of
/// field values via Navigator.pop for the caller to persist.
class AddCustomerSheet extends StatefulWidget {
  final Customer? existing;
  const AddCustomerSheet({super.key, this.existing});

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
        ],
      ),
    );
  }
}
