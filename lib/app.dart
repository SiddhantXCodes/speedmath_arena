import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/performance_provider.dart';
import 'providers/practice_log_provider.dart';
import 'theme/app_theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners(); // 🚀 triggers rebuild instantly
  }
}

class SpeedMathApp extends StatelessWidget {
  const SpeedMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => PerformanceProvider()..loadFromStorage(),
        ),
        ChangeNotifierProvider(create: (_) => PracticeLogProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDark;

          // 🧠 Use AnimatedTheme for smooth cross-fade between themes
          return AnimatedTheme(
            data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            duration: const Duration(
              milliseconds: 300,
            ), // 🟢 theme animation speed
            curve: Curves.easeInOut,
            child: MaterialApp(
              title: 'SpeedMath',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              navigatorObservers: [routeObserver],

              // 🧩 Builder with ValueKey ensures new context on toggle (no delay)
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
