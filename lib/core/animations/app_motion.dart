import 'package:flutter/material.dart';

/// Centralized animation durations used across the app so every
/// micro-interaction feels consistent.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 650);
}

/// Centralized curves used across the app.
class AppCurves {
  AppCurves._();
  static const Curve standard = Curves.easeOutCubic;
  static const Curve bounce = Curves.easeOutBack;
  static const Curve smooth = Curves.fastOutSlowIn;
}

/// A reusable "entry" animation: fades + slides a child upward as it
/// appears. Used for staggered list/card reveals throughout the app.
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  const AnimatedEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.medium,
    this.offsetY = 24,
  });

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: AppCurves.standard);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.standard));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps a list of children with a staggered [AnimatedEntry], giving each
/// item an increasing delay so they cascade into view.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;
  final Duration step;
  final Axis direction;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext, List<Widget>)? builder;

  const StaggeredList({
    super.key,
    required this.children,
    this.baseDelay = const Duration(milliseconds: 60),
    this.step = const Duration(milliseconds: 70),
    this.direction = Axis.vertical,
    this.padding,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final wrapped = <Widget>[
      for (int i = 0; i < children.length; i++)
        AnimatedEntry(
          delay: baseDelay + step * i,
          child: children[i],
        ),
    ];
    if (builder != null) return builder!(context, wrapped);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: direction == Axis.vertical
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: wrapped)
          : Row(children: wrapped),
    );
  }
}

/// A subtle "press" scale effect for any tappable widget — used across
/// buttons, cards and list rows for tactile feedback.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1.0;

  void _set(double v) => setState(() => _scale = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(widget.scaleDown),
      onTapUp: (_) => _set(1.0),
      onTapCancel: () => _set(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        curve: AppCurves.smooth,
        child: widget.child,
      ),
    );
  }
}

/// Custom page route: slide-in-from-right + fade, used for pushing new
/// screens (per spec section 27).
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SlideFadeRoute({required this.page})
      : super(
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.normal,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: AppCurves.smooth);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Custom modal route: scale + fade, used for dialogs/modals.
Future<T?> showScaleFadeDialog<T>(BuildContext context, {required Widget child}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: AppDurations.normal,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.bounce);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.standard),
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}
