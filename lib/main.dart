import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/dummy_data.dart';
import 'data/repositories/repositories.dart';
import 'routes/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
