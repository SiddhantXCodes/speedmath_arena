// lib/services/sync_manager.dart
import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

// Repository imports
import '../features/practice/practice_repository.dart';
import '../features/performance/performance_repository.dart';
import '../features/quiz/quiz_repository.dart';

import 'hive_service.dart';

/// 🌐 SyncManager — Central Hybrid Sync Layer
/// Handles:
/// • Sync queue (Hive) → Firebase
/// • Practice logs sync
/// • Performance sync (daily scores + streak)
/// • Ranked quiz offline → online sync
/// • Auto-sync on network reconnect
class SyncManager {
  // Singleton
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  // Dependencies
  final PracticeRepository practiceRepo = PracticeRepository();
  final PerformanceRepository perfRepo = PerformanceRepository();
  final QuizRepository quizRepo = QuizRepository();

  StreamSubscription<ConnectivityResult>? _connectionSub;

  bool _isSyncing = false;
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  // ---------------------------------------------------------------------------
  // 🚀 Start Sync Listener (AUTO SYNC)
  // ---------------------------------------------------------------------------
  Future<void> start() async {
    log("🔄 SyncManager starting...");

    _connectionSub = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      if (result == ConnectivityResult.none) {
        log("📴 Offline — sync paused.");
        return;
      }

      // Debounce — avoid multiple triggers
      final now = DateTime.now();
      if (now.difference(_lastSync).inSeconds < 8) return;
      _lastSync = now;

      log("🌐 Online — triggering sync...");
      await syncAll();
    });
  }

  // ---------------------------------------------------------------------------
  // 🛑 Stop Sync Listener
  // ---------------------------------------------------------------------------
  void stop() {
    _connectionSub?.cancel();
    log("🛑 SyncManager stopped.");
  }

  // ---------------------------------------------------------------------------
  // 🔁 Full Multi-Repo Sync
  // ---------------------------------------------------------------------------
  Future<void> syncAll() async {
    if (_isSyncing) {
      log("⚙️ Sync already running — skipping duplicate.");
      return;
    }

    _isSyncing = true;
    log("🚀 SyncManager: Sync starting...");

    try {
      // 1️⃣ Sync queued offline items
      await _syncQueuedOperations();

      // 2️⃣ Sync practice logs to Firebase
      await practiceRepo.syncData();

      // 3️⃣ Sync performance (streak + daily scores)
      await perfRepo.syncData();

      log("✅ SyncManager: All sync operations completed.");
    } catch (e, st) {
      log("❌ SyncManager error: $e", stackTrace: st);
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 📦 Sync items from Hive Sync Queue
  // ---------------------------------------------------------------------------
  Future<void> _syncQueuedOperations() async {
    log("📦 Checking Hive sync queue...");

    try {
      if (!Hive.isBoxOpen('sync_queue')) {
        try {
          await Hive.openBox('sync_queue');
        } catch (_) {
          log("⚠️ Unable to open sync_queue");
          return;
        }
      }

      final box = Hive.box('sync_queue');
      if (box.isEmpty) {
        log("ℹ️ No queued items.");
        return;
      }

      final keys = box.keys.toList();

      for (final key in keys) {
        final item = Map<String, dynamic>.from(box.get(key));
        final type = item['type'];
        final data = Map<String, dynamic>.from(item['data']);

        try {
          if (type == 'practice_logs') {
            // Already handled via PracticeRepository
            await practiceRepo.syncPendingSessions();
          } else if (type == 'ranked_quiz') {
            // Ranked quiz queued upload
            await quizRepo.syncOfflineRankedFromQueue(data);
          } else {
            log("⚠️ Unknown sync type: $type");
            continue;
          }

          // Remove once synced
          await box.delete(key);
          log("🧹 Synced and removed queue item: $type");
        } catch (e) {
          log("❌ Failed to sync item ($type): $e");
          continue;
        }
      }
    } catch (e, st) {
      log("❌ Failed to sync queue: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 🕓 Manual sync trigger (optional)
  // ---------------------------------------------------------------------------
  Future<void> syncPendingSessions() async {
    log("🔁 Manual sync trigger...");
    await syncAll();
  }
}
