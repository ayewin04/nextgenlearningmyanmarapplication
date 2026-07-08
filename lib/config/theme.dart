// lib/config/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color secondaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(0xFF0A0E27);
  static const Color cardColor = Color(0xFF1A237E);
  static const Color textPrimary = Color(0xFFE8EAF6);
  static const Color textSecondary = Color(0xFF9FA8DA);

  static ThemeData darkBlueTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: Color(0xFF00E5FF),
      error: Color(0xFFEF5350),
      background: backgroundColor,
      surface: cardColor,
      onBackground: textPrimary,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: accentColor,
      unselectedItemColor: Color(0xFF5C6BC0),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    scaffoldBackgroundColor: backgroundColor,
  );
}