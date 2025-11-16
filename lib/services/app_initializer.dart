// lib/services/app_initializer.dart

import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'hive_boxes.dart';
import 'sync_manager.dart';

class AppInitializer {
  static bool _initialized = false;

  /// ---------------------------------------------------------------
  /// 1️⃣ Called from main.dart — safe wrapper
  /// ---------------------------------------------------------------
  static Future<void> ensureInitialized(void Function(String) onStatus) async {
    if (_initialized) {
      onStatus("🔁 Already initialized");
      return;
    }

    _initialized = true;
    await initialize(onStatus);
  }

  /// ---------------------------------------------------------------
  /// 2️⃣ Firebase, Hive, SyncManager
  /// ---------------------------------------------------------------
  static Future<void> initialize(void Function(String) onStatus) async {
    try {
      // Firebase
      onStatus("⚙️ Connecting to Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log("✅ Firebase initialized");

      // Hive
      onStatus("📦 Setting up local storage...");
      await HiveBoxes.init();
      log("✅ Hive initialized");

      // Leaderboard cache
      if (!Hive.isBoxOpen('leaderboard_cache')) {
        await Hive.openBox('leaderboard_cache');
        log("📄 Leaderboard cache box opened");
      }

      // Sync
      onStatus("🔄 Starting background sync...");
      SyncManager().start();
      log("🔁 Sync Manager started");

      onStatus("🚀 Setup complete");
    } catch (e, st) {
      log("❌ App initialization failed: $e", stackTrace: st);
      onStatus("❌ Initialization failed");
    }
  }

  /// ---------------------------------------------------------------
  /// ❌ REMOVE PRELOAD HERE — Providers must NOT be created here
  /// ---------------------------------------------------------------
  static Future<void> preloadAppData() async {
    // ❌ DO NOTHING HERE ANYMORE
    // Providers are created only once in main.dart then auto-load.
    log("ℹ️ preloadAppData skipped — using provider constructors instead");
  }
}
