// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _darkModeKey = 'isDarkMode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode
        ? ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF4CAF50),
              background: Color(0xFF0A0E27),
              surface: Color(0xFF1A237E),
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0E27),
          )
        : ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF4CAF50),
              background: Color(0xFFF5F7FA),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          );
  }
}