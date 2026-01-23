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
  static const Color borderColor = Color(0x14FFFFFF);    // white/8 (border-subtle)
  static const Color dividerColor = Color(0x0DFFFFFF);   // white/5
  static const Color borderWhite10 = Color(0x1AFFFFFF);  // white/10
  static const Color bgWhite10 = Color(0x1AFFFFFF);      // white/10
  static const Color bgWhite5 = Color(0x0DFFFFFF);        // white/5

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
        shape: const Border(
          bottom: BorderSide(color: dividerColor), // white/5
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

  // Light Theme Colors (Updated based on Reference)
  static const Color backgroundLight = Color(0xFFF9F9F8); // background-warm
  static const Color cardLight = Color(0xFFFFFFFF);       // white
  static const Color surfaceLight = Color(0xFFF3F4F6);    // gray-100 (fallback)

  // Light Theme Text Colors
  static const Color textPrimaryLight = Color(0xFF1A1A1C);   // text-charcoal
  static const Color textSecondaryLight = Color(0xFF6B7280); // gray-500
  static const Color textMutedLight = Color(0xFF9CA3AF);     // gray-400
  static const Color textDisabledLight = Color(0xFFD1D5DB);  // gray-300

  // Light Theme Border
  static const Color borderColorLight = Color(0x0F000000);   // border-soft (black/6%)
  static const Color dividerColorLight = Color(0x08000000);  // black/3%

  // Light Theme Specifics
  static const BoxShadow shadowSoft = BoxShadow(
    color: Color(0x0A000000), // 0 4px 20px -2px rgba(0, 0, 0, 0.04)
    offset: Offset(0, 4),
    blurRadius: 20,
    spreadRadius: -2,
  );
  
  static const BoxShadow shadowFab = BoxShadow(
    color: Color(0x662DD4BF), // 0 8px 24px -4px rgba(45, 212, 191, 0.4)
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -4,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: accentTeal,
      colorScheme: const ColorScheme.light(
        primary: accentTeal,
        secondary: primary,
        surface: cardLight,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
        onSecondary: textPrimaryLight,
        outline: borderColorLight,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        displaySmall: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 15, // Adjusted to match reference h3
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.publicSans(
          color: textSecondaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.publicSans(
          color: textSecondaryLight, // gray-500
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.publicSans(
          color: textMutedLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.publicSans(
          color: textMutedLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0, 
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondaryLight, // gray-500
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight.withOpacity(0.8), // translucent
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textSecondaryLight), // gray-500
        titleTextStyle: GoogleFonts.publicSans(
          color: textPrimaryLight,
          fontSize: 20, // text-xl
          fontWeight: FontWeight.w700, // font-bold
          letterSpacing: -0.5, // tracking-tight
        ),
        shape: const Border(bottom: BorderSide(color: dividerColorLight)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundLight,
        selectedItemColor: accentTeal,
        unselectedItemColor: textDisabledLight,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04), // soft shadow base
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderColorLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColorLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColorLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.publicSans(
          color: textMutedLight,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          elevation: 4, 
          shadowColor: const Color(0x662DD4BF), // shadow-fab
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.publicSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondaryLight,
          textStyle: GoogleFonts.publicSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
