import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../invoices/invoice_detail_screen.dart';
import 'add_customer_sheet.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerRepositoryProvider);
    final invoices = ref.watch(invoiceRepositoryProvider);
    Customer? customer;
    try {
      customer = customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      customer = null;
    }
    if (customer == null) {
      return const Scaffold(body: Center(child: Text('Customer not found')));
    }

    final custInvoices = invoices.where((i) => i.customerId == customerId).toList();
    final paidCount = custInvoices.where((i) => i.status == InvoiceStatus.paid).length;
    final pendingCount = custInvoices.where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partial).length;
    final totalRevenue = custInvoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              bool deleted = false;
              final result = await showAppBottomSheet<Map<String, String>>(
                context,
                child: AddCustomerSheet(
                  existing: customer,
                  onDelete: () {
                    ref.read(customerRepositoryProvider.notifier).delete(customer!.id);
                    deleted = true;
                  },
                ),
              );
              if (deleted) {
                if (context.mounted) Navigator.of(context).pop();
                return;
              }
              if (result != null) {
                customer!.name = result['name']!;
                customer.phone = result['phone'] ?? '';
                customer.email = result['email'] ?? '';
                customer.address = result['address'] ?? '';
                ref.read(customerRepositoryProvider.notifier).update(customer);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            AnimatedEntry(
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.themedPrimary(context).withOpacity(0.16),
                      child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                          style: TextStyle(color: AppColors.themedPrimary(context), fontWeight: FontWeight.w800, fontSize: 26)),
                    ),
                    const SizedBox(height: 12),
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedEntry(
              delay: const Duration(milliseconds: 80),
              child: AppCard(
                child: Column(
                  children: [
                    _ContactRow(icon: Icons.call_rounded, label: 'Phone', value: customer.phone.isEmpty ? '—' : customer.phone),
                    const Divider(height: 22),
                    _ContactRow(icon: Icons.email_rounded, label: 'Email', value: customer.email.isEmpty ? '—' : customer.email),
                    const Divider(height: 22),
                    _ContactRow(icon: Icons.location_on_rounded, label: 'Address', value: customer.address.isEmpty ? '—' : customer.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedEntry(
              delay: const Duration(milliseconds: 140),
              child: Row(
                children: [
                  Expanded(child: _StatBox(label: 'Total Invoice', value: '${custInvoices.length}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(label: 'Paid', value: '$paidCount', color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(label: 'Pending', value: '$pendingCount', color: AppColors.warning)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedEntry(
              delay: const Duration(milliseconds: 180),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Revenue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    MoneyText(value: totalRevenue, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.themedPrimary(context))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Invoices', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            if (custInvoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No invoices yet', style: TextStyle(color: AppColors.textSecondary))),
              )
            else
              ...custInvoices.take(6).toList().asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnimatedEntry(
                        delay: Duration(milliseconds: 60 * e.key),
                        child: InvoiceListCard(
                          invoice: e.value,
                          customerName: customer!.name,
                          onTap: () => Navigator.of(context).push(SlideFadeRoute(page: InvoiceDetailScreen(invoiceId: e.value.id))),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.themedPrimary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
