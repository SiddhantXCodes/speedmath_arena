// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';

/// ✅ Controls global theme (light/dark) across the app
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners(); // 🚀 triggers UI rebuild
  }
}
