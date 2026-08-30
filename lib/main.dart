import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/dummy_data.dart';
import 'data/repositories/repositories.dart';
import 'routes/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Container(
        color: Colors.red,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          details.exceptionAsString(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print('FLUTTER ERROR: ${details.exceptionAsString()}\n${details.stack}');
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('PLATFORM ERROR: $error\n$stack');
    return true;
  };
  await AppDatabase.init();
  await DummyData.seedIfEmpty();
  runApp(const ProviderScope(child: InvoicelyApp()));
}

class InvoicelyApp extends ConsumerWidget {
  const InvoicelyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    ThemeMode mode;
    switch (themeMode) {
      case 1:
        mode = ThemeMode.light;
        break;
      case 2:
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }
    return MaterialApp(
      title: 'Invoicely',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const RootShell(),
    );
  }
}
