import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import 'add_customer_sheet.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final result = await showAppBottomSheet<Map<String, String>>(context, child: const AddCustomerSheet());
    if (result != null) {
      ref.read(customerRepositoryProvider.notifier).add(
            name: result['name']!,
            phone: result['phone'] ?? '',
            email: result['email'] ?? '',
            address: result['address'] ?? '',
          );
      if (mounted) AppSnackbar.show(context, message: 'Customer added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerRepositoryProvider);
    final invoices = ref.watch(invoiceRepositoryProvider);

    List<Invoice> invoicesFor(String id) => invoices.where((i) => i.customerId == id).toList();

    final filtered = customers.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AnimatedEntry(
              offsetY: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Customers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Everyone you do business with', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  PressableScale(
                    onTap: _addCustomer,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(hintText: 'Search customer', border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: customers.isEmpty ? 'No customers yet' : 'No customers found',
                    message: customers.isEmpty
                        ? 'Add your first customer to start creating invoices.'
                        : 'Try a different search term.',
                    actionLabel: customers.isEmpty ? 'Add Customer' : null,
                    onAction: customers.isEmpty ? _addCustomer : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final customer = filtered[i];
                      final custInvoices = invoicesFor(customer.id);
                      final totalSpend = custInvoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);
                      return AnimatedEntry(
                        delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                        child: AppCard(
                          onTap: () => Navigator.of(context).push(SlideFadeRoute(page: CustomerDetailScreen(customerId: customer.id))),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.10),
                                child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    const SizedBox(height: 3),
                                    Text(customer.phone.isEmpty ? '—' : customer.phone,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${custInvoices.length} invoices',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  MoneyText(value: totalSpend, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
