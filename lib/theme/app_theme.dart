// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 🔥 Breakpoint classes
enum DeviceClass { phone, smallTablet, bigTablet }

class AppTheme {
  // ---------------------------------------------------------------------------
  // 🎨 COLOR TOKENS
  // ---------------------------------------------------------------------------

  // 🌞 LIGHT MODE
  static const Color lightPrimary = Color(0xFF004D40);
  static const Color lightSecondary = Color(0xFF26A69A);
  static const Color lightBackground = Color(0xFFF7FAF9);
  static const Color lightSurface = Colors.white;

  // 🌚 DARK MODE — Sapphire Variant
  static const Color darkPrimary = Color(0xFF3FA7D6);
  static const Color darkSecondary = Color(0xFF81C3F2);
  static const Color darkBackground = Color(0xFF1E2532);
  static const Color darkSurface = Color(0xFF27313F);

  // ✍️ Text
  static const Color darkTextStrong = Color(0xFFF3F7FC);
  static const Color darkTextMedium = Color(0xFFC9D4DD);

  // 🏅 Rank
  static const Color rankGold = Color(0xFFFFD700);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  // 🚦 Status Colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFCA28);
  static const Color danger = Color(0xFFE57373);

  // ===========================================================================
  // 🌞 LIGHT THEME
  // ===========================================================================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightPrimary,
      brightness: Brightness.light,
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      background: lightBackground,
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: lightSurface,
    iconTheme: const IconThemeData(color: lightPrimary),
    dividerColor: Colors.black12,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: lightSecondary,
    ),

    // ❗ NO ScreenUtil here (use raw numbers)
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );

  // ===========================================================================
  // 🌚 DARK THEME — Safe, static (NO .sp/.h/.w)
  // ===========================================================================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      background: darkBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextStrong,
      onBackground: darkTextStrong,
      onError: Colors.white,
      error: danger,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkTextStrong,
      elevation: 0,
      centerTitle: true,
    ),

    cardColor: darkSurface,
    dividerColor: Color(0xFF2E3A4A),
    iconTheme: const IconThemeData(color: darkPrimary),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: darkSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),

    // ❗ NO ScreenUtil here (use raw numbers)
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkTextStrong, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: darkTextStrong, fontSize: 14),
      bodySmall: TextStyle(color: darkTextMedium, fontSize: 12),
      titleMedium: TextStyle(
        color: darkTextStrong,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: darkTextStrong,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface.withOpacity(0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // 🔥 raw number only
        borderSide: BorderSide.none,
      ),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: darkSecondary,
    ),
  );

  // ===========================================================================
  // 🧠 GLOBAL RESPONSIVE HELPERS (SAFE)
  // ===========================================================================

  /// Screen Class
  static DeviceClass deviceClass(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= 599) return DeviceClass.phone;
    if (w <= 1023) return DeviceClass.smallTablet;
    return DeviceClass.bigTablet;
  }

  static bool isPhone(BuildContext context) =>
      deviceClass(context) == DeviceClass.phone;

  static bool isSmallTablet(BuildContext context) =>
      deviceClass(context) == DeviceClass.smallTablet;

  static bool isBigTablet(BuildContext context) =>
      deviceClass(context) == DeviceClass.bigTablet;

  // Responsive helpers (SAFE after ScreenUtilInit)
  static double text(double base) => base.sp;
  static double icon(double base) => base.sp;
  static double radius(double base) => base.r;
  static double gap(double base) => base.h;

  // Theme-based helpers
  static Color adaptiveText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color adaptiveCard(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color adaptiveAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  // Rank Colors
  static Color get gold => rankGold;
  static Color get silver => rankSilver;
  static Color get bronze => rankBronze;
  static Color get successColor => success;
  static Color get warningColor => warning;
  static Color get dangerColor => danger;
}
