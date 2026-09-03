import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF3730A3);
  static const bgDark = Color(0xFF1A1A2E);
  static const bgDark2 = Color(0xFF16213E);
  static const bgDark3 = Color(0xFF0F3460);
  static const cardBlue = Color(0xFF1E3A5F);
  static const cardGreen = Color(0xFF14422A);
  static const cardAmber = Color(0xFF3D2800);
  static const cardPurple = Color(0xFF2D1B6E);

  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);

  static const surface = Color(0xFFF4F4F8);
  static const surface2 = Color(0xFFEEEEF3);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const borderColor = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: Colors.white,
        background: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderColor,
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
        primary: AppColors.primaryLight,
        surface: const Color(0xFF1E1E2E),
        background: const Color(0xFF111120),
      ),
      scaffoldBackgroundColor: const Color(0xFF111120),
    );
  }
}
