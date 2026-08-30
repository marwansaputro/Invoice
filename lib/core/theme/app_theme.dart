import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Static color tokens per the product spec. Used to build a consistent
/// Material 3 [ColorScheme] for both light and dark mode.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF344F68);
  static const secondary = Color(0xFFF46B6B);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF35B779);
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFE95B5B);

  static const darkBackground = Color(0xFF101418);
  static const darkSurface = Color(0xFF181D22);
  static const darkText = Color(0xFFF5F5F5);
  static const darkPrimary = Color(0xFF7DA4C7);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.10),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(color: Colors.black.withOpacity(0.06), space: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData(brightness: Brightness.dark).textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme.apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.darkText,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.darkPrimary.withOpacity(0.16),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.darkPrimary : Colors.white60,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.darkPrimary : Colors.white60);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Color(0xFF0B1116),
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08), space: 1),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
