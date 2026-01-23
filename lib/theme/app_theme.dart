import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Dark Theme Colors
  static const Color primaryDark = Color(0xFF2DD4BF); // Accent Teal as primary for dark mode
  static const Color primaryBlue = Color(0xFF137FEC); // Specific Blue from design
  static const Color backgroundDark = Color(0xFF0A0A0B); // Deep Charcoal #0a0a0b
  static const Color cardDark = Color(0xFF161618); // #161618
  static const Color surfaceDark = Color(0xFF161618);
  
  // Text Colors (Dark)
  static const Color textHighDark = Color(0xFFF2F2F2); // Near White
  static const Color textLowDark = Color(0xFF8E8E93);  // Muted Gray

  // New Light Theme Colors
  static const Color primaryLight = Color(0xFF2DD4BF); // Primary Teal
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure White #ffffff
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color softTealLight = Color(0xFFF0FDFA); // #f0fdfa
  static const Color textHighLight = Color(0xFF121214); // Charcoal #121214
  static const Color textLowLight = Color(0xFF636366);  // Medium Gray

  // Common Colors
  static const Color error = Color(0xFFEF4444);

  // Backward Compatibility / Aliases
  static const Color accentTeal = primaryDark;
  static const Color textPrimary = textHighDark;
  static const Color textSecondary = textLowDark;
  static const Color textMuted = textLowDark;
  static const Color textDisabled = Color(0xFF636366);
  static const Color borderColor = Color(0xFF242427); // #242427
    static const Color dividerColor = Color(0xFF242427);
  static const Color ink = textHighLight;
  static const Color paper = backgroundLight;
    static const Color border = borderColor;
  static const Color accent = accentTeal;
  static const Color cream = Color(0xFFFDFBF7);
  
  // Specific Opacity Colors for UI components
  static const Color bgWhite10 = Color(0x1AFFFFFF);
  static const Color bgWhite5 = Color(0x0DFFFFFF);
  static const Color borderWhite10 = Color(0x1AFFFFFF);

  static const BoxShadow shadowSoft = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 4),
    blurRadius: 20,
    spreadRadius: -2,
  );

  static const BoxShadow shadowFab = BoxShadow(
    color: Color(0x662DD4BF),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -4,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryDark,

      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: primaryBlue, // Use the blue as secondary
        surface: cardDark,
        background: backgroundDark,
        onPrimary: Color(0xFF000000), 
        onSurface: textHighDark,
        onBackground: textHighDark,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.publicSans(
          color: textHighDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.publicSans(
          color: textHighDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.publicSans(
          color: textHighDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.publicSans(
          color: textHighDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.publicSans(
          color: textLowDark,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.publicSans(
          color: textLowDark,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.publicSans( // Button text
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.publicSans( // Caption / Metadata
          color: textLowDark,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textLowDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.publicSans(
          color: textHighDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textLowDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Color(0xFF0A0A0A), // Dark text on teal
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: textLowDark,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: primaryLight,
        surface: cardLight,
        background: backgroundLight,
        onPrimary: Colors.white,
        onSurface: textHighLight,
        onBackground: textHighLight,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.publicSans(
          color: textHighLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.publicSans(
          color: textHighLight,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.publicSans(
          color: textHighLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.publicSans(
          color: textHighLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.publicSans(
          color: textLowLight,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.publicSans(
          color: textLowLight,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.publicSans(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.publicSans(
          color: textLowLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textLowLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.publicSans(
          color: textHighLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textLowLight),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04), // soft shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: textLowLight,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.05),
        thickness: 1,
      ),
      useMaterial3: true,
    );
  }
}
