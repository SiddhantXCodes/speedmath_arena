import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Brand & accent colors
  static const MaterialAccentColor lightAccent = Colors.blueAccent;

  // Softer blue-teal for dark mode (eye-comfort optimized)
  static const MaterialAccentColor darkTealAccent = MaterialAccentColor(
    0xFF64B5F6, // main tone
    <int, Color>{
      100: Color(0xFF4FC3F7),
      200: Color(0xFF29B6F6),
      400: Color(0xFF039BE5),
      700: Color(0xFF0288D1),
    },
  );

  // Neutral backgrounds
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color darkBackground = Color(0xFF121212);

  // Core brand color (used for highlights and consistency)
  static const Color primaryColor = Colors.deepPurple;

  // -------------------------------
  // LIGHT THEME
  // -------------------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: lightAccent,
      surface: Colors.white,
      background: lightBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    cardColor: Colors.white,
    iconTheme: IconThemeData(color: lightAccent),
    dividerColor: Colors.black12,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  // -------------------------------
  // DARK THEME
  // -------------------------------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkTealAccent,
      brightness: Brightness.dark,
      primary: darkTealAccent,
      secondary: darkTealAccent,
      surface: const Color(0xFF1E1E1E),
      background: darkBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: const Color(0xFF1E1E1E),
    iconTheme: IconThemeData(color: darkTealAccent),
    dividerColor: Colors.white24,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTealAccent,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  // -------------------------------
  // Helper utilities (fully reactive)
  // -------------------------------

  /// Dynamically adapts to the active theme's onSurface color.
  static Color adaptiveText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Adapts card color (based on surface background tone).
  static Color adaptiveCard(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Adapts accent/primary color (used for icons or highlights).
  static Color adaptiveAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Adapts divider color to theme brightness.
  static Color divider(BuildContext context) => Theme.of(context).dividerColor;
}
