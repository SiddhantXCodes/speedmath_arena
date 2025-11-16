//lib/features/practice/practice_repository.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/hive_service.dart';
import '../../models/practice_log.dart';
import '../../models/question_history.dart';

/// 🧠 PracticeRepository — Handles Practice Logic (offline + sync)
/// - Save sessions to Hive
/// - Fetch local sessions
/// - Queue offline logs for later sync
/// - Upload logs to Firestore when online
/// - Activity history for heatmap
class PracticeRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// ----------------------------------------------------------
  /// 💾 Save a Practice Session (Offline-First)
  /// ----------------------------------------------------------
  Future<void> savePracticeSession(PracticeLog entry) async {
    try {
      // 1) Always save offline
      await HiveService.addPracticeLog(entry);
      log("🧩 Practice saved offline: ${entry.topic}");

      // 2) Queue for sync if logged in
      final user = _auth.currentUser;
      if (user != null) {
        await HiveService.queueForSync("practice_logs", entry.toMap());
        log("📤 Queued for sync (user: ${user.uid})");
      }
    } catch (e, st) {
      log("⚠️ Failed to save practice session: $e", stackTrace: st);
    }
  }

  /// ----------------------------------------------------------
  /// 🧾 Get All Local Practice Sessions
  /// ----------------------------------------------------------
  List<PracticeLog> getAllLocalSessions() {
    try {
      return HiveService.getPracticeLogs();
    } catch (e, st) {
      log("⚠️ getAllLocalSessions error: $e", stackTrace: st);
      return [];
    }
  }

  /// 🔁 Added convenience method for provider
  List<Map<String, dynamic>> getAllSessions() {
    try {
      return HiveService.getPracticeLogs().map((e) => e.toMap()).toList();
    } catch (e, st) {
      log("⚠️ getAllSessions error: $e", stackTrace: st);
      return [];
    }
  }

  /// ----------------------------------------------------------
  /// 📜 Get Question History
  /// ----------------------------------------------------------
  List<QuestionHistory> getQuestionHistory() {
    try {
      return HiveService.getHistory();
    } catch (e, st) {
      log("⚠️ Failed to get question history: $e", stackTrace: st);
      return [];
    }
  }

  /// ----------------------------------------------------------
  /// 📤 Sync Pending Offline Practice Logs → Firebase
  /// ----------------------------------------------------------
  Future<int> syncPendingSessions() async {
    final user = _auth.currentUser;
    if (user == null) {
      log("⚠️ Not logged in → skipping sync");
      return 0;
    }

    try {
      final pending = HiveService.getPendingSyncs()
          .where((item) => item["type"] == "practice_logs")
          .toList();

      if (pending.isEmpty) {
        log("ℹ️ No pending practice logs");
        return 0;
      }

      int count = 0;

      for (final item in pending) {
        final data = Map<String, dynamic>.from(item["data"]);
        final id = DateTime.now().millisecondsSinceEpoch.toString();

        await _firestore
            .collection("users")
            .doc(user.uid)
            .collection("practice_sessions")
            .doc(id)
            .set(data, SetOptions(merge: true));

        log("☁️ Synced practice log → Firebase (id: $id)");

        count++;
      }

      // 🔥 Clear local pending syncs AFTER success
      await HiveService.clearPendingSyncsOfType("practice_logs");

      log("✅ Synced $count practice logs");
      return count;
    } catch (e, st) {
      log("⚠️ syncPendingSessions error: $e", stackTrace: st);
      return 0;
    }
  }

  /// ----------------------------------------------------------
  /// 🔄 Sync All Practice Data (used by SyncManager)
  /// ----------------------------------------------------------
  Future<void> syncData() async {
    try {
      await syncPendingSessions();
      log("✅ PracticeRepository sync completed");
    } catch (e, st) {
      log("⚠️ PracticeRepository sync failed: $e", stackTrace: st);
    }
  }

  /// ----------------------------------------------------------
  /// 🗓️ Heatmap Activity
  /// ----------------------------------------------------------
  Map<DateTime, int> getActivityMapFromHive() {
    try {
      return HiveService.getActivityMap();
    } catch (e, st) {
      log("⚠️ Failed to load activity map: $e", stackTrace: st);
      return {};
    }
  }

  /// ----------------------------------------------------------
  /// 🧹 Clear Local Practice Data
  /// ----------------------------------------------------------
  Future<void> clearAllLocalData() async {
    try {
      await HiveService.clearPracticeLogs();
      log("🧹 All local practice logs cleared");
    } catch (e, st) {
      log("⚠️ clearAllLocalData error: $e", stackTrace: st);
    }
  }
}
