import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ──
  static const Color bg = Color(0xFF06060B);
  static const Color surface = Color(0xFF0D0D1A);
  static const Color surface2 = Color(0xFF161625);
  static const Color surface3 = Color(0xFF1E1E35);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF1F1F1);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textTertiary = Color(0xFF5C5C72);
  static const Color userBubble = Color(0xFF1E1E35);
  static const Color aiBubble = Color(0xFF0D0D1A);
  static const Color danger = Color(0xFFEF4444);
  static const Color glowGold = Color(0x40F59E0B);
  static const Color glowPurple = Color(0x40A855F7);

  // ── Shadows & Glows ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withAlpha(80),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowGoldShadow => [
    BoxShadow(
      color: glowGold,
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get glowPurpleShadow => [
    BoxShadow(
      color: glowPurple,
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ── Gradients ──
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0D1A),
      Color(0xFF06060B),
    ],
  );

  static const LinearGradient agentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentPurple,
      accentGold,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
    ],
  );

  static const LinearGradient thinkingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40A855F7),
      Color(0x20F59E0B),
    ],
  );

  // ── Animation curves ──
  static const Curve easeOutExpo = Curves.easeOutCubic;
  static const Curve easeInOutExpo = Curves.easeInOutCubic;

  // ── Border radii ──
  static const double cardRadius = 16;
  static const double bubbleRadius = 20;
  static const double pillRadius = 24;

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
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A14),
        selectedItemColor: accentGold,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary, height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textSecondary, height: 1.5,
        ),
        labelSmall: TextStyle(
          color: textTertiary, fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
