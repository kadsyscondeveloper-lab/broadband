import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE31E24);
  static const Color primaryDark = Color(0xFFC01010);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color textLight = Color(0xFFB0B0B8);
  static const Color borderColor = Color(0xFFE0E0E8);
  static const Color reviewBg = Color(0xFFFFF8E7);
  static const Color reviewBorder = Color(0xFFF5C842);
  static const Color walletBg = Color(0xFF8B0000);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'SF Pro Display',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    useMaterial3: true,
  );
}
