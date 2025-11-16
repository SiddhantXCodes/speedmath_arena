// lib/features/performance/performance_repository.dart

import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/hive_service.dart';
import '../../models/daily_score.dart';

/// 📊 PerformanceRepository — handles all ranked & practice score logic
/// Production uses real Firebase, but tests inject mocks.
class PerformanceRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // --------------------------------------------------------------------------
  // 🔥 NORMAL CONSTRUCTOR (Production)
  // --------------------------------------------------------------------------
  PerformanceRepository()
    : _auth = FirebaseAuth.instance,
      _firestore = FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // 🧪 TEST CONSTRUCTOR (Mocks)
  // --------------------------------------------------------------------------
  PerformanceRepository.test(FirebaseAuth mockAuth, FirebaseFirestore mockStore)
    : _auth = mockAuth,
      _firestore = mockStore;

  // --------------------------------------------------------------------------
  // 🧠 Leaderboard Header
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchLeaderboardHeader() async {
    final user = _auth.currentUser;
    if (user == null) {
      log("⚠️ No logged-in user, returning empty leaderboard");
      return {};
    }

    final uid = user.uid;
    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    int? todayRank;
    int? allTimeRank;
    int? bestScore;
    int? totalScore;
    int? totalUsers;

    try {
      // 🟦 Fetch today's leaderboard
      final dailySnap = await _firestore
          .collection('daily_leaderboard')
          .doc(todayKey)
          .collection('entries')
          .orderBy('score', descending: true)
          .orderBy('timeTaken', descending: false)
          .get();

      int rank = 1;
      for (final doc in dailySnap.docs) {
        if (doc.id == uid) {
          todayRank = rank;
          break;
        }
        rank++;
      }

      // 🟩 All-time leaderboard
      final allSnap = await _firestore
          .collection('alltime_leaderboard')
          .orderBy('totalScore', descending: true)
          .get();

      totalUsers = allSnap.size;

      rank = 1;
      for (final doc in allSnap.docs) {
        if (doc.id == uid) {
          allTimeRank = rank;

          final data = doc.data();
          bestScore =
              (data['bestDailyScore'] ?? data['bestScore'] ?? 0) as int?;
          totalScore = (data['totalScore'] ?? 0) as int?;

          break;
        }
        rank++;
      }

      // Cache offline
      final cacheBox = await Hive.openBox('leaderboard_cache');
      await cacheBox.put('header', {
        'todayRank': todayRank,
        'allTimeRank': allTimeRank,
        'totalUsers': totalUsers,
        'bestScore': bestScore,
        'totalScore': totalScore,
        'lastFetched': DateTime.now().toIso8601String(),
      });

      return {
        'todayRank': todayRank,
        'allTimeRank': allTimeRank,
        'totalUsers': totalUsers,
        'bestScore': bestScore,
        'totalScore': totalScore,
      };
    } catch (e, st) {
      log("⚠️ Leaderboard fetch failed: $e", stackTrace: st);

      final cacheBox = await Hive.openBox('leaderboard_cache');
      final cached = cacheBox.get('header');

      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }

      return {};
    }
  }

  // --------------------------------------------------------------------------
  // 📈 Ranked Quiz Trend
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRankedQuizTrend() async {
    try {
      final localScores = HiveService.getAllDailyScores();

      if (localScores.isEmpty) return [];

      localScores.sort((a, b) => b.date.compareTo(a.date));
      final recent = localScores.take(7).toList().reversed.toList();

      return recent
          .map(
            (score) => {
              'date': score.date,
              'score': score.score,
              'isRanked': score.isRanked,
            },
          )
          .toList();
    } catch (e, st) {
      log("⚠️ Failed to fetch ranked trend: $e", stackTrace: st);
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // 💾 Save DailyScore
  // --------------------------------------------------------------------------
  Future<void> saveDailyScore(DailyScore score) async {
    try {
      await HiveService.addDailyScore(score);
    } catch (e, st) {
      log("⚠️ Failed to save DailyScore: $e", stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // ☁️ Sync local DailyScores → Firebase
  // --------------------------------------------------------------------------
  Future<void> syncLocalScoresToFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final scores = HiveService.getAllDailyScores();

      for (final score in scores) {
        if (!score.isRanked) continue;

        final dateKey =
            "${score.date.year}-${score.date.month.toString().padLeft(2, '0')}-${score.date.day.toString().padLeft(2, '0')}";

        await _firestore
            .collection('daily_leaderboard')
            .doc(dateKey)
            .collection('entries')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'email': user.email,
              'score': score.score,
              'totalQuestions': score.totalQuestions,
              'timeTakenSeconds': score.timeTakenSeconds,
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e, st) {
      log("⚠️ Failed to sync local scores: $e", stackTrace: st);
    }
  }

  Future<void> syncData() async {
    await syncLocalScoresToFirebase();
  }

  // --------------------------------------------------------------------------
  // 🧾 Online Attempts History
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchOnlineAttempts({
    int limit = 200,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ranked_attempts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'date': (d['date'] as Timestamp?)?.toDate(),
          'score': d['score'] ?? 0,
          'totalQuestions': d['totalQuestions'] ?? 0,
          'timeTakenSeconds': d['timeTakenSeconds'] ?? 0,
        };
      }).toList();
    } catch (e, st) {
      log("⚠️ fetchOnlineAttempts failed: $e", stackTrace: st);
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // 🧹 Clear local Performance data
  // --------------------------------------------------------------------------
  Future<void> clearAllLocalData() async {
    try {
      await HiveService.clearDailyScores();
      final cache = await Hive.openBox('leaderboard_cache');
      await cache.clear();
    } catch (e, st) {
      log("⚠️ Failed to clear local performance data: $e", stackTrace: st);
    }
  }
}
