// lib/main.dart
// Providers are created + initialized BEFORE HomeScreen builds
// Ensures heatmap, stats, streak all load instantly

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'services/app_initializer.dart';
import 'widgets/boot_screen.dart';
import 'services/sync_manager.dart';
import 'app.dart';

// Providers
import 'providers/theme_provider.dart';
import 'features/auth/auth_provider.dart';
import 'providers/practice_log_provider.dart';
import 'providers/performance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  bool _isReady = false;

  // Message not shown on UI anymore, but kept for debug/log safety
  String _message = "Initializing…";

  // Provider instances created only ONCE
  late final ThemeProvider _themeProvider;
  late final AuthProvider _authProvider;
  late final PracticeLogProvider _practiceProvider;
  late final PerformanceProvider _performanceProvider;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// ---------------------------------------------------------
  /// 🚀 FULL APP INITIALIZATION PIPELINE
  /// ---------------------------------------------------------
  Future<void> _initialize() async {
    try {
      // Firebase + Hive + services
      await AppInitializer.ensureInitialized((status) {
        if (mounted) _message = status; // internal log only
      });

      // Create providers
      _themeProvider = ThemeProvider();
      _authProvider = AuthProvider();
      _practiceProvider = PracticeLogProvider();
      _performanceProvider = PerformanceProvider();

      // Wait for async provider init
      int retries = 0;
      while ((!_practiceProvider.initialized ||
              !_performanceProvider.initialized) &&
          retries < 60) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }

      // Sync offline → online
      await SyncManager().syncPendingSessions();

      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) _message = "❌ Initialization failed: $e";
    }
  }

  @override
  void dispose() {
    SyncManager().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BootScreen wrapped in MaterialApp (required)
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BootScreen(message: _message), // message not used anymore
      );
    }

    // Providers already initialized → instant UI
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _practiceProvider),
        ChangeNotifierProvider.value(value: _performanceProvider),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (_, __) => const SpeedMathApp(),
      ),
    );
  }
}
