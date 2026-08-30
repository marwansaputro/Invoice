import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/invoice_widgets.dart';
import '../../core/widgets/widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/repositories.dart';
import '../../models/models.dart';

enum _SendState { idle, loading, success }

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  _SendState _sendState = _SendState.idle;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: AppDurations.slow)
      ..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Invoice? get _invoice =>
      ref.read(invoiceRepositoryProvider.notifier).byId(widget.invoiceId);

  Future<void> _handleSend() async {
    setState(() => _sendState = _SendState.loading);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sendState = _SendState.success);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppSnackbar.show(context,
        message: 'Invoice sent successfully',
        icon: Icons.check_circle_rounded,
        color: AppColors.success);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sendState = _SendState.idle);
  }

  Future<void> _openShareSheet() async {
    final invoice = _invoice;
    if (invoice == null) return;
    await showAppBottomSheet(context, child: _ShareSheet(invoice: invoice));
  }

  Future<void> _generateAndOpenPdf() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _generatingPdf = true);
    final customer =
        ref.read(customerRepositoryProvider.notifier).byId(invoice.customerId);
    final business = AppDatabase.business;

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PreparingPdfDialog(),
    ));

    final bytes = await PdfGenerator.generateInvoicePdf(
        invoice: invoice, customer: customer, business: business);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close preparing dialog
    setState(() => _generatingPdf = false);

    await showScaleFadeDialog(context,
        child:
            _PdfReadyDialog(file: file, invoiceNumber: invoice.invoiceNumber));
  }

  void unawaited(Future future) {}

  @override
  Widget build(BuildContext context) {
    ref.watch(invoiceRepositoryProvider);
    final invoice = _invoice;
    if (invoice == null) {
      return const Scaffold(body: Center(child: Text('Invoice not found')));
    }
    final customer =
        ref.watch(customerRepositoryProvider.notifier).byId(invoice.customerId);
    final business = AppDatabase.business;

    final logoAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: AppCurves.bounce),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F6),
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: _generatingPdf
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _generatingPdf ? null : _generateAndOpenPdf,
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                invoice.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(invoice.isFavorite),
                color: invoice.isFavorite ? AppColors.secondary : null,
              ),
            ),
            onPressed: () => ref
                .read(invoiceRepositoryProvider.notifier)
                .toggleFavorite(invoice.id),
          ),
        ],
      ),
      body: FadeTransition(
        opacity:
            CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.3)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
            children: [
              AnimatedBuilder(
                animation: _entrance,
                builder: (context, child) {
                  final t = CurvedAnimation(
                          parent: _entrance,
                          curve: const Interval(0.1, 0.7,
                              curve: AppCurves.standard))
                      .value;
                  return Opacity(
                    opacity: t.clamp(0, 1),
                    child: Transform.translate(
                        offset: Offset(0, (1 - t.clamp(0, 1)) * 40),
                        child: child),
                  );
                },
                child: ScaleTransition(
                  scale: logoAnim.drive(Tween(begin: 0.98, end: 1)),
                  child: InvoicePaper(
                      invoice: invoice, customer: customer, business: business),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = CurvedAnimation(
                  parent: _entrance,
                  curve: const Interval(0.55, 1, curve: AppCurves.bounce))
              .value
              .clamp(0.0, 1.0);
          return Transform.scale(
              scale: 0.7 + 0.3 * t, child: Opacity(opacity: t, child: child));
        },
        child: _SendFab(
            state: _sendState,
            onSend: () async {
              await _handleSend();
            },
            onShare: _openShareSheet),
      ),
    );
  }
}

class _SendFab extends StatelessWidget {
  final _SendState state;
  final VoidCallback onSend;
  final VoidCallback onShare;
  const _SendFab(
      {required this.state, required this.onSend, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.94,
      onTap: state == _SendState.idle
          ? () async {
              onSend();
              await Future.delayed(const Duration(milliseconds: 1600));
              if (context.mounted) onShare();
            }
          : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.normal,
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: RotationTransition(
                      turns: Tween<double>(begin: 0.85, end: 1).animate(anim),
                      child: child)),
              child: switch (state) {
                _SendState.idle => const Icon(Icons.send_rounded,
                    key: ValueKey('idle'), color: Colors.white, size: 20),
                _SendState.loading => const SizedBox(
                    key: ValueKey('loading'),
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  ),
                _SendState.success => const Icon(Icons.check_rounded,
                    key: ValueKey('success'), color: Colors.white, size: 22),
              },
            ),
            const SizedBox(width: 10),
            Text(
              switch (state) {
                _SendState.idle => 'Send',
                _SendState.loading => 'Sending...',
                _SendState.success => 'Sent!',
              },
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparingPdfDialog extends StatefulWidget {
  const _PreparingPdfDialog();

  @override
  State<_PreparingPdfDialog> createState() => _PreparingPdfDialogState();
}

class _PreparingPdfDialogState extends State<_PreparingPdfDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                  offset: Offset(0, -8 * _controller.value), child: child),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Icon(Icons.description_rounded,
                    color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Preparing invoice...',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Generating PDF...',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _PdfReadyDialog extends StatelessWidget {
  final File file;
  final String invoiceNumber;
  const _PdfReadyDialog({required this.file, required this.invoiceNumber});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('PDF ready',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('$invoiceNumber.pdf',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5)),
              const SizedBox(height: 20),
              AppButton(
                label: 'Open PDF',
                icon: Icons.open_in_new_rounded,
                expand: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(
                      onLayout: (format) async => file.readAsBytesSync());
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Share',
                type: AppButtonStyleType.outline,
                icon: Icons.ios_share_rounded,
                expand: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Invoice $invoiceNumber');
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Close',
                type: AppButtonStyleType.text,
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final Invoice invoice;
  const _ShareSheet({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('WhatsApp', Icons.chat_rounded, AppColors.success),
      ('Email', Icons.email_rounded, AppColors.primary),
      ('Telegram', Icons.send_rounded, const Color(0xFF29A9EA)),
      ('Other Apps', Icons.more_horiz_rounded, AppColors.textSecondary),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Send Invoice',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Share via',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: options
              .map((o) => PressableScale(
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(
                          'Here is your invoice ${invoice.invoiceNumber}, total ${invoice.total.toStringAsFixed(0)}.');
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                              color: o.$3.withOpacity(0.12),
                              shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(o.$2, color: o.$3, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(o.$1,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link_rounded, color: AppColors.primary),
          title: const Text('Copy Invoice Link',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          onTap: () {
            Navigator.pop(context);
            AppSnackbar.show(context, message: 'Invoice link copied');
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tag_rounded, color: AppColors.primary),
          title: const Text('Copy Invoice Number',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          onTap: () {
            Navigator.pop(context);
            AppSnackbar.show(context, message: 'Invoice number copied');
          },
        ),
      ],
    );
  }
}
