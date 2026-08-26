import 'package:flutter/material.dart';

abstract final class ScoutTheme {
  static const primarySeed = Color(0xFFE08BB4); // Dusty rose/pink
  static const scaffoldBg = Color(0xFFF7F5F2);   // Soft cream off-white

  static ThemeData get light => _theme();
  static ThemeData get dark => _theme(); // Keep unified light theme for consistent pastel aesthetic

  static ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: primarySeed,
      secondary: const Color(0xFFFFF099), // Soft yellow accent
      surface: Colors.white,
      onSurface: const Color(0xFF1E1E24),  // Dark slate
      outlineVariant: const Color(0xFFEAE7E2),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
          side: const BorderSide(color: Color(0xFFEAE7E2), width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFEAE7E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFEAE7E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primarySeed, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: const Color(0xFFF5B5D0), // Soft pink active pill
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF1E1E24));
          }
          return const IconThemeData(color: Color(0xFF75747C));
        }),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFFEAE7E2),
        selectedColor: const Color(0xFFF5B5D0),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E24),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
          color: Color(0xFF101012),
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.9,
          color: Color(0xFF101012),
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: Color(0xFF101012),
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: Color(0xFF1E1E24),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF5A5862),
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF75747C),
        ),
      ),
    );
  }
}
