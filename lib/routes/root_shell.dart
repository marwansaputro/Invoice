import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/animations/app_motion.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/repositories.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/invoices/invoices_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/invoice_create/create_invoice_screen.dart';

/// Root shell hosting the 4-tab bottom navigation (Dashboard, Invoices,
/// Customers, Settings) plus the global "Create Invoice" FAB.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    InvoicesScreen(),
    CustomersScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const showFab = true;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              switchInCurve: AppCurves.standard,
              switchOutCurve: AppCurves.standard,
              transitionBuilder: (child, animation) {
                final fade = FadeTransition(opacity: animation, child: child);
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
                    child: fade,
                  ),
                );
              },
              child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: _FloatingNavBar(
                index: _index,
                showFab: showFab,
                onSelect: (i) => setState(() => _index = i),
                onCreateInvoice: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating pill-shaped bottom bar with a raised circular "Create Invoice"
/// button embedded in its center notch, per the reference design.
class _FloatingNavBar extends ConsumerWidget {
  final int index;
  final bool showFab;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreateInvoice;

  const _FloatingNavBar({
    required this.index,
    required this.showFab,
    required this.onSelect,
    required this.onCreateInvoice,
  });

  static const _items = [
    (icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard_rounded),
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded),
    (icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt_rounded),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppStrings(ref.watch(localeProvider));
    final labels = [l10n.navDashboard, l10n.navInvoices, l10n.navCustomers, l10n.navSettings];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.68),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.10 : 0.6)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.08), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _navItem(0, labels[0])),
                      Expanded(child: _navItem(1, labels[1])),
                      const SizedBox(width: 68),
                      Expanded(child: _navItem(2, labels[2])),
                      Expanded(child: _navItem(3, labels[3])),
                    ],
                  ),
                );
              }),
            ),
          ),
          Positioned(
            top: -22,
            child: _CreateInvoiceFab(visible: showFab, onOpened: onCreateInvoice),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int i, String label) {
    final item = _items[i];
    final selected = index == i;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return PressableScale(
      onTap: () => onSelect(i),
      child: SizedBox(
        height: 68,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular "Create Invoice" button that sits raised in the bottom bar's
/// center notch, with an entrance animation, a pulsing glow halo, and a
/// brief loading state before opening Create Invoice.
class _CreateInvoiceFab extends StatefulWidget {
  final bool visible;
  final VoidCallback onOpened;
  const _CreateInvoiceFab({required this.visible, required this.onOpened});

  @override
  State<_CreateInvoiceFab> createState() => _CreateInvoiceFabState();
}

class _CreateInvoiceFabState extends State<_CreateInvoiceFab> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: AppDurations.slow, value: widget.visible ? 1 : 0);
    if (widget.visible) _entrance.forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void didUpdateWidget(covariant _CreateInvoiceFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _entrance.forward() : _entrance.reverse();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(SlideFadeRoute(page: const CreateInvoiceScreen()));
    widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _entrance, curve: AppCurves.bounce);
    return AnimatedBuilder(
      animation: Listenable.merge([curved, _pulse]),
      builder: (context, child) {
        final t = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.7 + 0.3 * t,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 1 + 0.35 * _pulse.value,
                    child: Opacity(
                      opacity: (1 - _pulse.value) * 0.35,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: PressableScale(
        scaleDown: 0.9,
        onTap: _loading ? null : _handleTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 4),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.add_rounded, key: ValueKey('icon'), color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
