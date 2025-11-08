// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/performance_provider.dart';
import 'providers/practice_log_provider.dart';
import 'theme/app_theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// ✅ ThemeProvider — controls light/dark mode across app
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners(); // 🚀 triggers full rebuild
  }
}

/// ✅ Root app
class SpeedMathApp extends StatelessWidget {
  const SpeedMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // global theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // app-specific providers
        ChangeNotifierProvider(
          create: (_) => PerformanceProvider()..loadFromStorage(),
        ),
        ChangeNotifierProvider(create: (_) => PracticeLogProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDark;

          return AnimatedTheme(
            data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            child: MaterialApp(
              title: 'SpeedMaths Pro',
              debugShowCheckedModeBanner: false,

              // 🧠 Attach theme data
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              navigatorObservers: [routeObserver],

              // 🧩 Builder + ValueKey ensures instant redraw on toggle
              home: Builder(
                key: ValueKey(isDark),
                builder: (_) => const HomeScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
