//lib/features/quiz/quiz_repository.dart
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/hive_service.dart';
import '../../models/quiz_session_model.dart';
import '../../models/practice_log.dart';
import '../../models/daily_score.dart';
import '../../models/daily_quiz_meta.dart';

/// QuizRepository – Firebase controls streak ONLY.
/// No local streak logic here.
class QuizRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // 💾 OFFLINE STORAGE
  // ---------------------------------------------------------------------------
  Future<void> saveOfflineResult(Map<String, dynamic> result) async {
    try {
      final logData = PracticeLog(
        date: DateTime.now(),
        topic: result['topic'] ?? 'Practice',
        category: result['category'] ?? 'General',
        correct: result['correct'] ?? 0,
        incorrect: result['incorrect'] ?? 0,
        score: result['score'] ?? 0,
        total: result['total'] ?? 10,
        avgTime: (result['avgTime'] ?? 0).toDouble(),
        timeSpentSeconds: result['timeSpentSeconds'] ?? 0,
        questions: List<Map<String, dynamic>>.from(result['questions'] ?? []),
        userAnswers: Map<int, String>.from(result['userAnswers'] ?? {}),
      );

      await HiveService.addPracticeLog(logData);
      dev.log("✅ Offline quiz result saved");
    } catch (e, st) {
      dev.log("⚠️ Failed to save offline quiz result: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 💾 QUEUE OFFLINE RANKED SESSION
  // ---------------------------------------------------------------------------
  Future<void> saveOfflineSession(QuizSessionModel session) async {
    try {
      await HiveService.addDailyScore(
        DailyScore(
          date: DateTime.now(),
          score: session.score,
          totalQuestions: session.total,
          timeTakenSeconds: session.timeSpentSeconds,
          isRanked: true,
        ),
      );

      await HiveService.saveDailyQuizMeta(
        DailyQuizMeta(
          date: DateTime.now().toIso8601String().substring(0, 10),
          totalQuestions: session.total,
          score: session.score,
          difficulty: session.difficulty ?? 'normal',
        ),
      );

      await HiveService.queueForSync('ranked_quiz', session.toMap());
      dev.log("📥 Ranked session queued for sync");
    } catch (e, st) {
      dev.log("⚠️ Failed to queue offline ranked: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // ☁️ SAVE RANKED RESULT ONLINE
  // ---------------------------------------------------------------------------
  Future<void> saveRankedResult(QuizSessionModel session) async {
    final user = _auth.currentUser;

    if (user == null) {
      dev.log("⚠️ No user logged in — saving offline only");
      await saveOfflineResult(session.toMap());
      return;
    }

    try {
      await _uploadRankedToFirebase(user, session);
      dev.log("🔥 Ranked quiz uploaded successfully");
    } catch (e, st) {
      dev.log(
        "❌ Firebase upload failed — queued offline",
        error: e,
        stackTrace: st,
      );
      await saveOfflineSession(session);
    }
  }

  // ---------------------------------------------------------------------------
  // 🔥 INTERNAL FIREBASE UPLOAD
  // ---------------------------------------------------------------------------
  Future<void> _uploadRankedToFirebase(
    User user,
    QuizSessionModel session,
  ) async {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);

    // ---------------- DAILY LEADERBOARD ----------------
    final dailyRef = _firestore
        .collection('daily_leaderboard')
        .doc(todayKey)
        .collection('entries')
        .doc(user.uid);

    await dailyRef.set({
      'uid': user.uid,
      'name': user.displayName ?? 'Player',
      'photoUrl': user.photoURL ?? '',
      'score': session.score,
      'correct': session.correct,
      'incorrect': session.incorrect,
      'total': session.total,
      'timeTaken': session.timeSpentSeconds,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    dev.log("✅ Daily leaderboard updated");

    // ---------------- ALL-TIME LEADERBOARD ----------------
    final allRef = _firestore.collection('alltime_leaderboard').doc(user.uid);
    final allSnap = await allRef.get();

    if (allSnap.exists) {
      final old = allSnap.data()!;
      await allRef.update({
        'name': user.displayName ?? 'Player',
        'photoUrl': user.photoURL ?? '',
        'totalScore': (old['totalScore'] ?? 0) + session.score,
        'quizzesTaken': (old['quizzesTaken'] ?? 0) + 1,
        'bestDailyScore': session.score > (old['bestDailyScore'] ?? 0)
            ? session.score
            : old['bestDailyScore'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      await allRef.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Player',
        'photoUrl': user.photoURL ?? '',
        'totalScore': session.score,
        'quizzesTaken': 1,
        'bestDailyScore': session.score,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    dev.log("✅ All-time leaderboard updated");

    // ---------------- LOCAL CACHE (NO STREAK!!) ----------------
    await HiveService.addDailyScore(
      DailyScore(
        date: DateTime.parse(todayKey),
        score: session.score,
        totalQuestions: session.total,
        timeTakenSeconds: session.timeSpentSeconds,
        isRanked: true,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔥 REQUIRED BY SYNC MANAGER — Upload queued ranked quiz
  // ---------------------------------------------------------------------------
  Future<void> syncOfflineRankedFromQueue(Map<String, dynamic> data) async {
    try {
      final session = QuizSessionModel.fromMap(data);
      final user = _auth.currentUser;

      if (user == null) {
        dev.log("❌ Cannot sync ranked quiz — no logged in user");
        return;
      }

      await _uploadRankedToFirebase(user, session);
      dev.log("✅ Synced queued ranked session");
    } catch (e, st) {
      dev.log("❌ Failed to sync queued ranked session: $e", stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 LEADERBOARD STREAMS
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getDailyLeaderboard() {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    return _firestore
        .collection('daily_leaderboard')
        .doc(todayKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .orderBy('timeTaken')
        .limit(50)
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
  // 🔍 UTILITY
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
