// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class SpeedMathApp extends StatelessWidget {
  const SpeedMathApp({super.key});

  /// 🔥 Exit Confirmation Dialog
  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: EdgeInsets.all(AppTheme.gap(18)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radius(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_bottom_rounded,
                        size: AppTheme.icon(42),
                        color: Theme.of(context).colorScheme.primary,
                      ),

                      SizedBox(height: AppTheme.gap(14)),

                      Text(
                        "Leaving already?",
                        style: TextStyle(
                          fontSize: AppTheme.text(19),
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      SizedBox(height: AppTheme.gap(10)),

                      Text(
                        "Just 5 more minutes can sharpen your\nmind, boost accuracy, and grow your\nmath momentum!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTheme.text(14),
                          height: 1.45,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),

                      SizedBox(height: AppTheme.gap(20)),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppTheme.gap(10),
                                ),
                              ),
                              child: Text(
                                "Stay",
                                style: TextStyle(
                                  fontSize: AppTheme.text(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppTheme.gap(10),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radius(12),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Exit",
                                style: TextStyle(
                                  fontSize: AppTheme.text(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Providers are already created in main.dart - just consume them here
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'SpeedMath Pro',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],

          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          home: WillPopScope(
            onWillPop: () => _confirmExit(context),
            child: HomeScreen(key: ValueKey(themeProvider.isDark)),
          ),
        );
      },
    );
  }
}
