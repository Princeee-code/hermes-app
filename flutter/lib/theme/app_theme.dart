import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ──
  static const Color bg = Color(0xFF0A0A0F);        // deep dark
  static const Color surface = Color(0xFF121218);     // elevated surface
  static const Color surface2 = Color(0xFF1A1A24);    // card surface
  static const Color accentGold = Color(0xFFF59E0B);  // gold
  static const Color accentPurple = Color(0xFFA855F7);// amethyst purple
  static const Color accentDeep = Color(0xFF1E064D);  // deep amethyst
  static const Color textPrimary = Color(0xFFF1F1F1);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color userBubble = Color(0xFF1A1A2E);
  static const Color aiBubble = Color(0xFF1E064D);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentPurple,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: bg,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
    );
  }
}
