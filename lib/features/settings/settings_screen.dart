import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _editBusinessProfile() async {
    final business = AppDatabase.business;
    await showAppBottomSheet(context, child: BusinessProfileSheet(business: business));
    setState(() {});
  }

  Future<void> _editInvoiceSettings() async {
    final settings = AppDatabase.settings;
    await showAppBottomSheet(context, child: _InvoiceSettingsSheet(settings: settings));
    setState(() {});
  }

  Future<void> _editTaxSettings() async {
    final settings = AppDatabase.settings;
    await showAppBottomSheet(context, child: _TaxSettingsSheet(settings: settings));
    setState(() {});
  }

  Future<void> _pickCurrency() async {
    final settings = AppDatabase.settings;
    final picked = await showAppBottomSheet<String>(context, child: _CurrencySheet(current: settings.currencySymbol));
    if (picked != null) {
      settings.currencySymbol = picked;
      await settings.save();
      if (mounted) {
        AppSnackbar.show(context, message: 'Currency set to $picked');
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = AppDatabase.business;
    final settings = AppDatabase.settings;
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        children: [
          AnimatedEntry(
            offsetY: 10,
            child: const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Text('Manage your business & app preferences', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          const SizedBox(height: 20),
          AnimatedEntry(
            delay: const Duration(milliseconds: 60),
            child: AppCard(
              onTap: _editBusinessProfile,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(business.businessName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        const Text('Tap to edit business profile', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedEntry(
            delay: const Duration(milliseconds: 100),
            child: _GroupedSettingsCard(
              title: 'Business',
              items: [
                _SettingsItem(icon: Icons.badge_rounded, label: 'Business Profile', onTap: _editBusinessProfile),
                _SettingsItem(icon: Icons.receipt_long_rounded, label: 'Invoice Settings', onTap: _editInvoiceSettings),
                _SettingsItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Payment Methods',
                  trailing: business.acceptedPaymentMethods.isEmpty
                      ? business.bankName
                      : business.acceptedPaymentMethods.length == 1
                          ? business.acceptedPaymentMethods.first
                          : '${business.acceptedPaymentMethods.length} methods',
                  onTap: _editBusinessProfile,
                ),
                _SettingsItem(
                  icon: Icons.percent_rounded,
                  label: 'Tax Settings',
                  trailing: '${settings.defaultTaxPercent.toStringAsFixed(0)}%',
                  onTap: _editTaxSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 140),
            child: _GroupedSettingsCard(
              title: 'Preferences',
              items: [
                _SettingsItem(icon: Icons.attach_money_rounded, label: 'Currency', trailing: settings.currencySymbol, onTap: _pickCurrency),
                _SettingsItem(
                  icon: Icons.description_rounded,
                  label: 'Invoice Template',
                  onTap: () => AppSnackbar.show(context, message: 'Your invoices use the default professional template.'),
                ),
                _SettingsItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  trailingWidget: Switch.adaptive(
                    value: settings.notificationsEnabled,
                    activeColor: AppColors.themedPrimary(context),
                    onChanged: (v) {
                      settings.notificationsEnabled = v;
                      settings.save();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 180),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Row(
                      children: [
                        Text('Appearance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _ThemeOption(label: 'Light', icon: Icons.light_mode_rounded, selected: themeMode == 1, onTap: () => ref.read(themeModeProvider.notifier).set(1))),
                      const SizedBox(width: 8),
                      Expanded(child: _ThemeOption(label: 'Dark', icon: Icons.dark_mode_rounded, selected: themeMode == 2, onTap: () => ref.read(themeModeProvider.notifier).set(2))),
                      const SizedBox(width: 8),
                      Expanded(child: _ThemeOption(label: 'System', icon: Icons.smartphone_rounded, selected: themeMode == 0, onTap: () => ref.read(themeModeProvider.notifier).set(0))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedEntry(
            delay: const Duration(milliseconds: 220),
            child: _GroupedSettingsCard(
              title: 'Data',
              items: [
                _SettingsItem(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Backup & Restore',
                  onTap: () => AppSnackbar.show(context,
                      message: 'All your data is already saved locally on this device.', icon: Icons.storage_rounded),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  onTap: () => showScaleFadeDialog(context, child: const _AboutDialog()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('INVOICELY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textSecondary.withOpacity(0.6), letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text('Create. Send. Get Paid.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary.withOpacity(0.5))),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  _SettingsItem({required this.icon, required this.label, this.trailing, this.trailingWidget, this.onTap});
}

class _GroupedSettingsCard extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  const _GroupedSettingsCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4)),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _SettingsRow(item: items[i]),
                if (i != items.length - 1) const Divider(height: 1, indent: 70, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsItem item;
  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.trailingWidget != null ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: AppColors.themedPrimary(context)),
            const SizedBox(width: 16),
            Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
            if (item.trailingWidget != null)
              item.trailingWidget!
            else ...[
              if (item.trailing != null)
                Text(item.trailing!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.themedPrimary(context);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent : Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? accent : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? accent : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// ------------------------- EDIT SHEETS -------------------------

class BusinessProfileSheet extends StatefulWidget {
  final BusinessProfile business;
  const BusinessProfileSheet({super.key, required this.business});

  @override
  State<BusinessProfileSheet> createState() => _BusinessProfileSheetState();
}

class _BusinessProfileSheetState extends State<BusinessProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccountName;
  late final TextEditingController _bankAccountNumber;
  late final Set<String> _selectedMethods;

  static const _availableMethods = ['Bank Transfer', 'Cash', 'QRIS', 'E-Wallet'];

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _name = TextEditingController(text: b.businessName);
    _address = TextEditingController(text: b.address);
    _phone = TextEditingController(text: b.phone);
    _email = TextEditingController(text: b.email);
    _bankName = TextEditingController(text: b.bankName);
    _bankAccountName = TextEditingController(text: b.bankAccountName);
    _bankAccountNumber = TextEditingController(text: b.bankAccountNumber);
    _selectedMethods = b.acceptedPaymentMethods.toSet();
  }

  void _toggleMethod(String method) {
    setState(() {
      if (_selectedMethods.contains(method)) {
        if (_selectedMethods.length > 1) _selectedMethods.remove(method);
      } else {
        _selectedMethods.add(method);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _bankName.dispose();
    _bankAccountName.dispose();
    _bankAccountNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.business
      ..businessName = _name.text.trim()
      ..address = _address.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..bankName = _bankName.text.trim()
      ..bankAccountName = _bankAccountName.text.trim()
      ..bankAccountNumber = _bankAccountNumber.text.trim()
      ..acceptedPaymentMethods = _selectedMethods.toList();
    await widget.business.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Business profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          AppTextField(label: 'Business Name', controller: _name),
          const SizedBox(height: 14),
          AppTextField(label: 'Address', controller: _address, maxLines: 2),
          const SizedBox(height: 14),
          AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          AppTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          const Text('PAYMENT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMethods
                .map((m) => _MethodChip(
                      label: m,
                      selected: _selectedMethods.contains(m),
                      onTap: () => _toggleMethod(m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Bank Name', controller: _bankName),
          const SizedBox(height: 14),
          AppTextField(label: 'Account Name', controller: _bankAccountName),
          const SizedBox(height: 14),
          AppTextField(label: 'Account Number', controller: _bankAccountNumber, keyboardType: TextInputType.number),
          const SizedBox(height: 22),
          AppButton(label: 'Save Changes', icon: Icons.check_rounded, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip({required this.label, required this.selected, required this.onTap});

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSettingsSheet extends StatefulWidget {
  final InvoiceSettingsModel settings;
  const _InvoiceSettingsSheet({required this.settings});

  @override
  State<_InvoiceSettingsSheet> createState() => _InvoiceSettingsSheetState();
}

class _InvoiceSettingsSheetState extends State<_InvoiceSettingsSheet> {
  late final TextEditingController _prefix;
  late final TextEditingController _nextNumber;
  late final TextEditingController _dueDays;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _prefix = TextEditingController(text: s.invoiceNumberPrefix);
    _nextNumber = TextEditingController(text: s.nextInvoiceSequence.toString());
    _dueDays = TextEditingController(text: s.defaultDueDays.toString());
  }

  @override
  void dispose() {
    _prefix.dispose();
    _nextNumber.dispose();
    _dueDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings
      ..invoiceNumberPrefix = _prefix.text.trim().isEmpty ? 'INV' : _prefix.text.trim().toUpperCase()
      ..nextInvoiceSequence = int.tryParse(_nextNumber.text) ?? widget.settings.nextInvoiceSequence
      ..defaultDueDays = int.tryParse(_dueDays.text) ?? 0;
    await widget.settings.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Invoice settings updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invoice Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        AppTextField(label: 'Invoice Number Prefix', controller: _prefix, hint: 'INV'),
        const SizedBox(height: 14),
        AppTextField(label: 'Next Invoice Number', controller: _nextNumber, keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        AppTextField(label: 'Default Due Days', controller: _dueDays, hint: '0 = Due on receipt', keyboardType: TextInputType.number),
        const SizedBox(height: 22),
        AppButton(label: 'Save Changes', icon: Icons.check_rounded, expand: true, onPressed: _save),
      ],
    );
  }
}

class _TaxSettingsSheet extends StatefulWidget {
  final InvoiceSettingsModel settings;
  const _TaxSettingsSheet({required this.settings});

  @override
  State<_TaxSettingsSheet> createState() => _TaxSettingsSheetState();
}

class _TaxSettingsSheetState extends State<_TaxSettingsSheet> {
  late final TextEditingController _percent;

  @override
  void initState() {
    super.initState();
    _percent = TextEditingController(text: widget.settings.defaultTaxPercent.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings.defaultTaxPercent = double.tryParse(_percent.text) ?? 0;
    await widget.settings.save();
    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.show(context, message: 'Tax settings updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tax Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Used as a default suggestion when adding new items.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 18),
        AppTextField(label: 'Default Tax (%)', controller: _percent, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 22),
        AppButton(label: 'Save Changes', icon: Icons.check_rounded, expand: true, onPressed: _save),
      ],
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  final String current;
  const _CurrencySheet({required this.current});

  @override
  Widget build(BuildContext context) {
    const currencies = ['Rp', '\$', '€', 'RM'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...currencies.map((c) {
          final accent = AppColors.themedPrimary(context);
          return PressableScale(
            scaleDown: 0.99,
            onTap: () => Navigator.pop(context, c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: c == current ? accent.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c == current ? accent : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Text(c, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(width: 12),
                  if (c == current) Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              const Text('Invoicely', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 4),
              const Text('Create. Send. Get Paid.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 14),
              const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('All data is stored locally on this device.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 18),
              AppButton(label: 'Close', expand: true, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
