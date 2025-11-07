import 'package:flutter/material.dart';

class AppTheme {
  // -------------------------------
  // Color tokens (single source)
  // -------------------------------

  // Dark mode teal family (used as primary in dark theme — matches leaderboard look)
  static const Color darkTealMain = Color(0xFF00796B); // deep teal
  static const Color darkTealLight = Color(0xFF26A69A);
  static const Color darkTealAccent = Color(0xFF00BFA5);

  // Light mode aqua/teal family (complements dark teal)
  static const Color lightTealMain = Color(
    0xFF26C6DA,
  ); // aqua-teal for light mode
  static const Color lightTealDark = Color(0xFF00ACC1);

  // Neutral backgrounds
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color darkBackground = Color(0xFF121212);

  // Surface / cards
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Leaderboard / highlight tokens (use these for rank badges, medals, etc.)
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  // Generic feedback
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFEF5350);

  // -------------------------------
  // LIGHT THEME
  // -------------------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightTealMain,
      brightness: Brightness.light,
      primary: lightTealMain,
      secondary: lightTealDark,
      surface: lightSurface,
      background: lightBackground,
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    cardColor: lightSurface,
    iconTheme: const IconThemeData(color: lightTealMain),
    dividerColor: Colors.black12,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightTealMain,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: lightTealDark,
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
      seedColor: darkTealMain,
      brightness: Brightness.dark,
      primary: darkTealMain,
      secondary: darkTealAccent,
      surface: darkSurface,
      background: darkBackground,
      onPrimary: Colors.white,
      onSurface: Colors.white70,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: darkSurface,
    iconTheme: const IconThemeData(color: darkTealAccent),
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
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: darkTealLight,
    ),
  );

  // -------------------------------
  // Helper utilities
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

  // Expose rank colors for global reuse (keeps leaderboard look consistent)
  static Color get gold => rankGold;
  static Color get silver => rankSilver;
  static Color get bronze => rankBronze;
  static Color get successColor => success;
  static Color get warningColor => warning;
  static Color get dangerColor => danger;
}
