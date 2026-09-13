import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';
import '../invoices/invoice_detail_screen.dart';
import '../invoices/invoices_screen.dart';
import '../settings/settings_screen.dart';

/// Greeting shown at the top of the dashboard, based on the time of day.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 00 && hour < 12) return 'Good morning 👋';
  if (hour >= 12 && hour < 17) return 'Good afternoon ☀️';
  if (hour >= 17 && hour < 21) return 'Good evening 🌆';
  return 'Good night 🌙';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceRepositoryProvider);
    final customers = ref.watch(customerRepositoryProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final recent = invoices.take(4).toList();

    String customerName(String id) {
      try {
        return customers.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return 'Walk-in Customer';
      }
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedEntry(
                offsetY: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('Manage your invoices easily',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5)),
                        ],
                      ),
                    ),
                    _IconBubble(
                        icon: Icons.notifications_none_rounded, onTap: () {}),
                    const SizedBox(width: 10),
                    _ProfileBadge(business: AppDatabase.business),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedEntry(
                delay: const Duration(milliseconds: 90),
                child: _RevenueCard(total: stats.total),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 18),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 148,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    AnimatedEntry(
                      delay: const Duration(milliseconds: 100),
                      offsetY: 16,
                      child: _StatChip(
                          label: 'Paid',
                          value: stats.paid,
                          total: stats.total,
                          color: AppColors.success,
                          icon: Icons.check_circle_rounded),
                    ),
                    const SizedBox(width: 12),
                    AnimatedEntry(
                      delay: const Duration(milliseconds: 180),
                      offsetY: 16,
                      child: _StatChip(
                          label: 'Pending',
                          value: stats.pending,
                          total: stats.total,
                          color: AppColors.warning,
                          icon: Icons.schedule_rounded),
                    ),
                    const SizedBox(width: 12),
                    AnimatedEntry(
                      delay: const Duration(milliseconds: 260),
                      offsetY: 16,
                      child: _StatChip(
                          label: 'Overdue',
                          value: stats.overdue,
                          total: stats.total,
                          color: AppColors.danger,
                          icon: Icons.error_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Invoices',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(SlideFadeRoute(page: const InvoicesScreen())),
                    child: const Text('See All',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          if (recent.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: EmptyState(
                  title: 'No invoices yet',
                  message:
                      'Create your first invoice and start tracking your payments.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              sliver: SliverList.separated(
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final invoice = recent[i];
                  return AnimatedEntry(
                    delay: Duration(milliseconds: 60 * i),
                    child: InvoiceListCard(
                      invoice: invoice,
                      customerName: customerName(invoice.customerId),
                      onTap: () => Navigator.of(context).push(SlideFadeRoute(
                          page: InvoiceDetailScreen(invoiceId: invoice.id))),
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

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileBadge extends StatefulWidget {
  final BusinessProfile business;
  const _ProfileBadge({required this.business});

  @override
  State<_ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends State<_ProfileBadge> {
  Future<void> _edit() async {
    await showAppBottomSheet(context,
        child: BusinessProfileSheet(business: widget.business));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logoBytes = widget.business.logoBytes;
    return PressableScale(
      onTap: _edit,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: logoBytes != null
            ? Image.memory(Uint8List.fromList(logoBytes),
                width: 42, height: 42, fit: BoxFit.cover)
            : Container(
                width: 42,
                height: 42,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: const Text('PE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double total;
  const _RevenueCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 26,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total Revenue',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppDurations.slow,
                curve: AppCurves.bounce,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.trending_up_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedNumber(
            value: total,
            duration: AppDurations.slow,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          AnimatedEntry(
            delay: const Duration(milliseconds: 260),
            offsetY: 10,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('+18.4%',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5)),
                ),
                const SizedBox(width: 8),
                const Text('Compared to last month',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  final IconData icon;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.total,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100).clamp(0, 100) : 0.0;
    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: color),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          AnimatedNumber(
              value: value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? pct / 100 : 0,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
