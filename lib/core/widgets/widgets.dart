import 'dart:ui';
import 'package:flutter/material.dart';
import '../animations/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../../models/models.dart';

/// ------------------------- BUTTON -------------------------

enum AppButtonStyleType { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyleType type;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.type = AppButtonStyleType.primary,
    this.loading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg, fg;
    BorderSide? border;
    switch (type) {
      case AppButtonStyleType.primary:
        bg = scheme.primary;
        fg = Colors.white;
        break;
      case AppButtonStyleType.secondary:
        bg = AppColors.secondary;
        fg = Colors.white;
        break;
      case AppButtonStyleType.outline:
        bg = Colors.transparent;
        fg = scheme.primary;
        border = BorderSide(color: scheme.primary.withOpacity(0.4));
        break;
      case AppButtonStyleType.text:
        bg = Colors.transparent;
        fg = scheme.primary;
        break;
      case AppButtonStyleType.danger:
        bg = AppColors.danger.withOpacity(0.12);
        fg = AppColors.danger;
        break;
    }

    final child = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
    );

    return PressableScale(
      onTap: loading ? null : onPressed,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border != null ? Border.fromBorderSide(border) : null,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// ------------------------- CARD -------------------------

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return PressableScale(onTap: onTap, scaleDown: 0.98, child: content);
  }
}

/// ------------------------- STATUS BADGE -------------------------

class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.success;
        break;
      case InvoiceStatus.unpaid:
        color = AppColors.warning;
        break;
      case InvoiceStatus.overdue:
        color = AppColors.danger;
        break;
      case InvoiceStatus.partial:
        color = AppColors.secondary;
        break;
      case InvoiceStatus.draft:
        color = AppColors.textSecondary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
      ),
    );
  }
}

/// ------------------------- MONEY TEXT -------------------------

class MoneyText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String symbol;
  const MoneyText({super.key, required this.value, this.style, this.symbol = 'Rp'});

  @override
  Widget build(BuildContext context) {
    return Text(AppFormatters.money(value, symbol: symbol), style: style);
  }
}

/// ------------------------- ANIMATED NUMBER -------------------------

class AnimatedNumber extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String symbol;
  final Duration duration;
  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.symbol = 'Rp',
    this.duration = AppDurations.medium,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppCurves.standard,
      builder: (context, animatedValue, _) {
        return Text(AppFormatters.money(animatedValue, symbol: symbol), style: style);
      },
    );
  }
}

/// ------------------------- EMPTY STATE -------------------------

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.receipt_long_rounded,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedEntry(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -6 * _controller.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 44, color: scheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedEntry(
              delay: const Duration(milliseconds: 100),
              child: Text(widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),
            AnimatedEntry(
              delay: const Duration(milliseconds: 160),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(height: 24),
              AnimatedEntry(
                delay: const Duration(milliseconds: 220),
                child: AppButton(label: widget.actionLabel!, icon: Icons.add, onPressed: widget.onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------------------- LOADING SKELETON (shimmer) -------------------------

class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry radius;
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
    final highlight = isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.10);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 + 3 * _controller.value, 0),
              end: Alignment(1 + 3 * _controller.value, 0),
            ).createShader(bounds);
          },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(color: base, borderRadius: widget.radius),
          ),
        );
      },
    );
  }
}

class InvoiceCardSkeleton extends StatelessWidget {
  const InvoiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const LoadingSkeleton(height: 44, width: 44, radius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LoadingSkeleton(height: 14, width: 120),
                SizedBox(height: 8),
                LoadingSkeleton(height: 12, width: 80),
              ],
            ),
          ),
          const LoadingSkeleton(height: 22, width: 60, radius: BorderRadius.all(Radius.circular(20))),
        ],
      ),
    );
  }
}

/// ------------------------- SNACKBAR -------------------------

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? const Color(0xFF232B33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: scheme.secondary,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}

/// ------------------------- BOTTOM SHEET -------------------------

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomSheetShell(child: child),
  );
}

class AppBottomSheetShell extends StatelessWidget {
  final Widget child;
  const AppBottomSheetShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -8)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------- TEXT FIELD -------------------------

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint, prefixIcon: prefix),
        ),
      ],
    );
  }
}

/// Frosted glass container — used sparingly per spec ("subtle glass/blur
/// only if needed"), e.g. behind modal overlays.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadiusGeometry radius;
  const GlassContainer({super.key, required this.child, this.blur = 12, this.radius = const BorderRadius.all(Radius.circular(20))});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
            borderRadius: radius,
          ),
          child: child,
        ),
      ),
    );
  }
}
