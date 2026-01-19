import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Dark Theme Colors
  static const Color primary = Color(0xFF137FEC);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color backgroundDark = Color(0xFF0A0A0B);
  static const Color cardDark = Color(0xFF161618);
  static const Color surfaceDark = Color(0xFF1A1A1C);

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);    // gray-100
  static const Color textSecondary = Color(0xFF9CA3AF);  // gray-400
  static const Color textMuted = Color(0xFF6B7280);      // gray-500
  static const Color textDisabled = Color(0xFF4B5563);   // gray-600

  // Border & Divider
  static const Color borderColor = Color(0x1AFFFFFF);    // white/10
  static const Color dividerColor = Color(0x0DFFFFFF);   // white/5

  // Legacy colors for backward compatibility
  static const Color paper = backgroundDark;
  static const Color ink = textPrimary;
  static const Color cream = cardDark;
  static const Color accent = accentTeal;
  static const Color border = borderColor;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: accentTeal,
      colorScheme: const ColorScheme.dark(
        primary: accentTeal,
        secondary: primary,
        surface: cardDark,
        onPrimary: backgroundDark,
        onSurface: textPrimary,
        onSecondary: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        displaySmall: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.publicSans(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w300,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.publicSans(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.publicSans(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.publicSans(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withAlpha(204), // 80% opacity
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.publicSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: accentTeal,
        unselectedItemColor: textDisabled,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.publicSans(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.publicSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }

  // Keep lightTheme for compatibility but redirect to darkTheme
  static ThemeData get lightTheme => darkTheme;
}
