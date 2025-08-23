import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores personalizados
  static const Color primaryBlue = Color(0xFF4CA2FE);
  static const Color secondaryDark = Color(0xFF1E2936);
  static const Color lightBackground = Color(0xFFFAF9F5);
  static const Color darkBackground = Color(0xFF161E27);

  // Tema claro
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,

    // Colores principales
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryDark,
      surface: Colors.white,
      error: Color(0xFFE53E3E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: secondaryDark,
      onError: Colors.white,
    ),

    // Tipografía con Inter
    textTheme: GoogleFonts.workSansTextTheme().copyWith(
      displayLarge: GoogleFonts.workSans(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: secondaryDark,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.workSans(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: secondaryDark,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.workSans(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: secondaryDark,
        height: 1.22,
      ),
      headlineLarge: GoogleFonts.workSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: secondaryDark,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.workSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: secondaryDark,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.workSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: secondaryDark,
        height: 1.33,
      ),
      titleLarge: GoogleFonts.workSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: secondaryDark,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryDark,
        height: 1.50,
      ),
      titleSmall: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryDark,
        height: 1.43,
      ),
      bodyLarge: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: secondaryDark,
        height: 1.50,
      ),
      bodyMedium: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryDark.withOpacity(0.8),
        height: 1.43,
      ),
      bodySmall: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryDark.withOpacity(0.6),
        height: 1.33,
      ),
      labelLarge: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.workSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.45,
      ),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: secondaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.workSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: secondaryDark,
      ),
      iconTheme: const IconThemeData(color: secondaryDark),
    ),

    // Botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryDark,
        side: const BorderSide(color: secondaryDark, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: secondaryDark.withOpacity(0.1)),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: secondaryDark.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: secondaryDark.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      hintStyle: GoogleFonts.workSans(
        color: secondaryDark.withOpacity(0.5),
        fontSize: 16,
      ),
    ),
  );

  // Tema oscuro
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,

    // Colores principales
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: secondaryDark,
      surface: Color(0xFF1E2936),
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),

    // Tipografía con Inter
    textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.workSans(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.12,
          ),
          displayMedium: GoogleFonts.workSans(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.16,
          ),
          displaySmall: GoogleFonts.workSans(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.22,
          ),
          headlineLarge: GoogleFonts.workSans(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.25,
          ),
          headlineMedium: GoogleFonts.workSans(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.29,
          ),
          headlineSmall: GoogleFonts.workSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.33,
          ),
          titleLarge: GoogleFonts.workSans(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.27,
          ),
          titleMedium: GoogleFonts.workSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.50,
          ),
          titleSmall: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.43,
          ),
          bodyLarge: GoogleFonts.workSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.50,
          ),
          bodyMedium: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.8),
            height: 1.43,
          ),
          bodySmall: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.6),
            height: 1.33,
          ),
          labelLarge: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.43,
          ),
          labelMedium: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.33,
          ),
          labelSmall: GoogleFonts.workSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.45,
          ),
        ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.workSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: const Color(0xFF1E2936),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E2936),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      hintStyle: GoogleFonts.workSans(
        color: Colors.white.withOpacity(0.5),
        fontSize: 16,
      ),
    ),
  );
}
