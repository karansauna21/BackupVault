import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Custom Colors
  static const Color primaryColor = Color(0xFF0D9488); // Emerald Teal
  static const Color primaryLightColor = Color(0xFF2DD4BF);
  static const Color primaryDarkColor = Color(0xFF115E59);

  static const Color accentColor = Color(0xFF3B82F6); // Blue Accent
  
  // Light Theme Colors
  static const Color lightBgColor = Color(0xFFF8FAFC); // Soft Slate White
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightOnBgColor = Color(0xFF0F172A); // Dark Slate Text
  static const Color lightOnSurfaceColor = Color(0xFF1E293B);
  static const Color lightBorderColor = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color darkBgColor = Color(0xFF090D16); // Deep Obsidian Blue/Black
  static const Color darkSurfaceColor = Color(0xFF151D30); // Deep Slate Blue
  static const Color darkOnBgColor = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceColor = Color(0xFFF1F5F9);
  static const Color darkBorderColor = Color(0xFF1E293B);

  // Success, Warning, Error
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightOnSurfaceColor,
      ),
      scaffoldBackgroundColor: lightBgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurfaceColor,
        foregroundColor: lightOnBgColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderColor,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightOnBgColor, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightOnBgColor, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: lightOnBgColor),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightOnBgColor),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightOnBgColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF334155)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF475569)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF64748B)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkOnSurfaceColor,
      ),
      scaffoldBackgroundColor: darkBgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkOnBgColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLightColor,
          side: const BorderSide(color: primaryLightColor, width: 1.5),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLightColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkOnBgColor, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkOnBgColor, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: darkOnBgColor),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkOnBgColor),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkOnBgColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFFCBD5E1)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF64748B)),
      ),
    );
  }
}
