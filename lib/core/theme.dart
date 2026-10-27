import 'package:flutter/material.dart';

/// Colours taken from the InvoiceFlow UI design (purple brand + lavender panels).
abstract final class AppColors {
  static const purple = Color(0xFF7B3A96);
  static const purpleDark = Color(0xFF5E2A73);
  static const lavender = Color(0xFFD3AEDB);
  static const lavenderLight = Color(0xFFF3E8F6);
  static const background = Color(0xFFFAF8FB);
  static const ink = Color(0xFF241E29);
  static const muted = Color(0xFF756D78);
  static const line = Color(0xFFE7E0E9);
  static const green = Color(0xFF2C8A62);
  static const amber = Color(0xFFB36B16);
  static const red = Color(0xFFB64C58);
  static const blue = Color(0xFF3B6FB6);
}

ThemeData buildAppTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.lavender),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
