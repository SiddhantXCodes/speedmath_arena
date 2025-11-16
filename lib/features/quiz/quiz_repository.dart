import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/hive_service.dart';
import '../../models/daily_score.dart';

/// New simplified QuizRepository for new quiz system.
/// - Score only
/// - Time taken only
/// - No wrong/correct breakdown
/// - No saved questions
/// - Leaderboard = score + time taken
class QuizRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // 🟦 PRACTICE MODE → LOCAL (Hive: practice_scores)
  // ---------------------------------------------------------------------------
  Future<void> savePracticeScore(int score, int timeTakenSeconds) async {
    try {
      final entry = DailyScore(
        date: DateTime.now(),
        score: score,
        totalQuestions: score,
        timeTakenSeconds: timeTakenSeconds,
        isRanked: false,
      );

      await HiveService.savePracticeScore(entry);

      dev.log("📘 Practice score saved (practice_scores)");
    } catch (e, st) {
      dev.log("❌ Failed to save practice score: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟨 MIXED PRACTICE MODE → LOCAL (Hive: mixed_scores)
  // ---------------------------------------------------------------------------
  Future<void> saveMixedScore(int score, int timeTakenSeconds) async {
    try {
      final entry = DailyScore(
        date: DateTime.now(),
        score: score,
        totalQuestions: score,
        timeTakenSeconds: timeTakenSeconds,
        isRanked: false,
      );

      await HiveService.saveMixedScore(entry);

      dev.log("📗 Mixed practice score saved (mixed_scores)");
    } catch (e, st) {
      dev.log("❌ Failed to save mixed score: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟥 RANKED MODE → FIREBASE + LOCAL CACHE
  // ---------------------------------------------------------------------------
  Future<void> saveRankedScore(int score, int timeTakenSeconds) async {
    final user = _auth.currentUser;

    if (user == null) {
      dev.log("⚠️ User not logged in → queue ranked offline");
      await _queueOfflineRanked(score, timeTakenSeconds);
      return;
    }

    try {
      await _uploadRankedToFirebase(user, score, timeTakenSeconds);
      dev.log("🔥 Ranked result uploaded");
    } catch (e, st) {
      dev.log("❌ Upload failed — queued offline", error: e, stackTrace: st);
      await _queueOfflineRanked(score, timeTakenSeconds);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟩 INTERNAL: Push ranked score to Firestore
  // ---------------------------------------------------------------------------
  Future<void> _uploadRankedToFirebase(
    User user,
    int score,
    int timeTakenSeconds,
  ) async {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);

    final entryRef = _firestore
        .collection('daily_leaderboard')
        .doc(todayKey)
        .collection('entries')
        .doc(user.uid);

    await entryRef.set({
      'uid': user.uid,
      'name': user.displayName ?? 'Player',
      'photoUrl': user.photoURL ?? '',
      'score': score,
      'timeTaken': timeTakenSeconds,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    dev.log("🏆 Daily leaderboard updated");

    // Save ranked result locally
    await HiveService.saveRankedScore(
      DailyScore(
        date: DateTime.now(),
        score: score,
        totalQuestions: score,
        timeTakenSeconds: timeTakenSeconds,
        isRanked: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟨 OFFLINE QUEUE FOR RANKED
  // ---------------------------------------------------------------------------
  Future<void> _queueOfflineRanked(int score, int timeTakenSeconds) async {
    try {
      await HiveService.queueForSync('ranked_quiz', {
        'score': score,
        'timeTaken': timeTakenSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      dev.log("📥 Ranked result queued offline");
    } catch (e, st) {
      dev.log("❌ Failed queue ranked: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 🟧 SYNC QUEUED RANKED SCORE
  // ---------------------------------------------------------------------------
  Future<void> syncOfflineRankedFromQueue(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final score = data['score'] ?? 0;
      final timeTaken = data['timeTaken'] ?? 0;

      await _uploadRankedToFirebase(user, score, timeTaken);

      dev.log("🔄 Offline ranked synced");
    } catch (e, st) {
      dev.log("❌ Rank sync failed: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // LEADERBOARD STREAMS
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getDailyLeaderboard() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    return _firestore
        .collection('daily_leaderboard')
        .doc(todayKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .orderBy('timeTaken')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllTimeLeaderboard() {
    return _firestore
        .collection('alltime_leaderboard')
        .orderBy('totalScore', descending: true)
        .limit(50)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // CHECK IF USER HAS PLAYED TODAY
  // ---------------------------------------------------------------------------
  Future<bool> hasPlayedToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      final doc = await _firestore
          .collection('daily_leaderboard')
          .doc(todayKey)
          .collection('entries')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      dev.log("⚠️ hasPlayedToday error: $e");
      return false;
    }
  }
}
