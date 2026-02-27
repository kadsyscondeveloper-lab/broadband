import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary      = Color(0xFFE31E24);
  static const Color primaryDark  = Color(0xFFC01010);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF2F2F7);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color textDark     = Color(0xFF1A1A2E);
  static const Color textGrey     = Color(0xFF8A8A8E);
  static const Color textLight    = Color(0xFFB0B0B8);
  static const Color borderColor  = Color(0xFFE0E0E8);
  static const Color reviewBg     = Color(0xFFFFF8E7);
  static const Color reviewBorder = Color(0xFFF5C842);
  static const Color walletBg     = Color(0xFF8B0000);
}

class AppTheme {
  static ThemeData get theme {
    final poppins = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3:            true,
      primaryColor:            AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      // ── Poppins everywhere ─────────────────────────────────────────────
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: poppins.copyWith(
        displayLarge:   poppins.displayLarge?.copyWith(color: AppColors.textDark,  fontWeight: FontWeight.w800),
        displayMedium:  poppins.displayMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w800),
        displaySmall:   poppins.displaySmall?.copyWith(color: AppColors.textDark,  fontWeight: FontWeight.w700),
        headlineLarge:  poppins.headlineLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
        headlineMedium: poppins.headlineMedium?.copyWith(color: AppColors.textDark,fontWeight: FontWeight.w700),
        headlineSmall:  poppins.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleLarge:     poppins.titleLarge?.copyWith(color: AppColors.textDark,    fontWeight: FontWeight.w600),
        titleMedium:    poppins.titleMedium?.copyWith(color: AppColors.textDark,   fontWeight: FontWeight.w600),
        titleSmall:     poppins.titleSmall?.copyWith(color: AppColors.textDark,    fontWeight: FontWeight.w500),
        bodyLarge:      poppins.bodyLarge?.copyWith(color: AppColors.textDark),
        bodyMedium:     poppins.bodyMedium?.copyWith(color: AppColors.textGrey),
        bodySmall:      poppins.bodySmall?.copyWith(color: AppColors.textLight),
        labelLarge:     poppins.labelLarge?.copyWith(color: AppColors.textDark,    fontWeight: FontWeight.w600),
        labelMedium:    poppins.labelMedium?.copyWith(color: AppColors.textGrey),
        labelSmall:     poppins.labelSmall?.copyWith(color: AppColors.textLight),
      ),

      // ── Color scheme ───────────────────────────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor:   AppColors.primary,
        primary:     AppColors.primary,
        surface:     AppColors.white,
        surfaceTint: Colors.transparent,
      ),

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
        centerTitle:     true,
        titleTextStyle: GoogleFonts.poppins(
          color:         AppColors.white,
          fontSize:      18,
          fontWeight:    FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      // ── ElevatedButton ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation:   2,
          shadowColor: AppColors.primary.withOpacity(0.35),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textGrey,
          side: const BorderSide(color: AppColors.borderColor, width: 1.5),
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── InputDecoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        hintStyle:  GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: AppColors.textGrey,  fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        filled:         true,
        fillColor:      AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── BottomNavigationBar ────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      AppColors.white,
        selectedItemColor:    AppColors.primary,
        unselectedItemColor:  AppColors.textLight,
        selectedLabelStyle:   GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:       AppColors.cardBg,
        elevation:   2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        labelStyle:      GoogleFonts.poppins(fontSize: 12),
        backgroundColor: AppColors.background,
        selectedColor:   AppColors.primary.withOpacity(0.12),
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.borderColor,
        thickness: 1,
        space:     1,
      ),
    );
  }
}