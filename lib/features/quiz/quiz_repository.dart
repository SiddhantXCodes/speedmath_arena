// lib/features/quiz/quiz_repository.dart

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/hive_service.dart';
import '../../models/daily_score.dart';

/// 🚀 Clean, unified QuizRepository for new quiz system.
class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // 🟦 PRACTICE QUIZ → LOCAL ONLY
  // ===========================================================================
  Future<void> savePracticeScore(int score, int timeTakenSeconds) async {
    try {
      await HiveService.savePracticeScore(
        DailyScore(
          date: DateTime.now(),
          score: score,
          totalQuestions: score,
          timeTakenSeconds: timeTakenSeconds,
          isRanked: false,
        ),
      );
      dev.log("📘 Saved PRACTICE score → practice_scores");
    } catch (e, st) {
      dev.log("❌ Failed saving PRACTICE score: $e", stackTrace: st);
    }
  }

  // ===========================================================================
  // 🟨 MIXED QUIZ → LOCAL ONLY
  // ===========================================================================
  Future<void> saveMixedScore(int score, int timeTakenSeconds) async {
    try {
      await HiveService.saveMixedScore(
        DailyScore(
          date: DateTime.now(),
          score: score,
          totalQuestions: score,
          timeTakenSeconds: timeTakenSeconds,
          isRanked: false,
        ),
      );
      dev.log("📙 Saved MIXED score → mixed_scores");
    } catch (e, st) {
      dev.log("❌ Failed saving MIXED score: $e", stackTrace: st);
    }
  }

  // ===========================================================================
  // 🟥 RANKED QUIZ → FIREBASE + OFFLINE QUEUE
  // ===========================================================================
  Future<void> saveRankedScore(int score, int timeTakenSeconds) async {
    final user = _auth.currentUser;

    if (user == null) {
      dev.log("⚠️ User offline → queue ranked attempt");
      await _queueOfflineRanked(score, timeTakenSeconds);
      return;
    }

    try {
      await _uploadRankedToFirebase(user, score, timeTakenSeconds);
      dev.log("🔥 Ranked uploaded to Firebase");
    } catch (e, st) {
      dev.log(
        "❌ Ranked upload FAILED → queue offline",
        error: e,
        stackTrace: st,
      );
      await _queueOfflineRanked(score, timeTakenSeconds);
    }
  }

  // ===========================================================================
  // 🟩 INTERNAL — UPLOAD RANKED ATTEMPT (FIXED TIMESTAMP)
  // ===========================================================================
  Future<void> _uploadRankedToFirebase(
    User user,
    int score,
    int timeTakenSeconds,
  ) async {
    final today = DateTime.now();
    final todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // -----------------------------
    // 1️⃣ Save full attempt history
    // -----------------------------
    final attemptRef = _firestore
        .collection("ranked_attempts")
        .doc(user.uid)
        .collection("attempts")
        .doc();

    await attemptRef.set({
      "uid": user.uid,
      "score": score,
      "timeTaken": timeTakenSeconds,
      "timestamp": FieldValue.serverTimestamp(), // FIXED
    });

    dev.log("📌 Ranked attempt saved → ranked_attempts");

    // -----------------------------
    // 2️⃣ Update Daily Leaderboard
    // -----------------------------
    final dailyRef = _firestore
        .collection("daily_leaderboard")
        .doc(todayKey)
        .collection("entries")
        .doc(user.uid);

    await dailyRef.set({
      "uid": user.uid,
      "name": user.displayName ?? "Player",
      "photoUrl": user.photoURL ?? "",
      "score": score,
      "timeTaken": timeTakenSeconds,
      "timestamp": FieldValue.serverTimestamp(), // FIXED
    }, SetOptions(merge: true));

    dev.log("🏆 Daily leaderboard updated ($todayKey)");
  }

  // ===========================================================================
  // 🟨 OFFLINE QUEUE
  // ===========================================================================
  Future<void> _queueOfflineRanked(int score, int timeTakenSeconds) async {
    try {
      await HiveService.queueForSync("ranked_attempt", {
        "score": score,
        "timeTaken": timeTakenSeconds,
        "timestamp": DateTime.now().toIso8601String(),
      });
      dev.log("📥 Offline ranked attempt queued");
    } catch (e, st) {
      dev.log("❌ Failed queueing ranked attempt: $e", stackTrace: st);
    }
  }

  // ===========================================================================
  // 🔄 SYNC OFFLINE RANKED ATTEMPTS
  // ===========================================================================
  Future<void> syncOfflineRankedFromQueue(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _uploadRankedToFirebase(
        user,
        data["score"] ?? 0,
        data["timeTaken"] ?? 0,
      );
      dev.log("🔄 Offline ranked attempt synced");
    } catch (e, st) {
      dev.log("❌ Sync failed: $e", stackTrace: st);
    }
  }

  // ===========================================================================
  // 🟦 DAILY LEADERBOARD STREAM
  // ===========================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> getDailyLeaderboard() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);

    return _firestore
        .collection("daily_leaderboard")
        .doc(todayKey)
        .collection("entries")
        .orderBy("score", descending: true)
        .orderBy("timeTaken")
        .snapshots();
  }

  // ===========================================================================
  // 🔍 CHECK IF USER PLAYED TODAY
  // ===========================================================================
  Future<bool> hasPlayedToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      final doc = await _firestore
          .collection("daily_leaderboard")
          .doc(todayKey)
          .collection("entries")
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      dev.log("⚠️ hasPlayedToday error: $e");
      return false;
    }
  }
}
