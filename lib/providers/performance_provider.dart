import 'package:flutter/material.dart';
import '../data/models/daily_score.dart';
import '../data/hive_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerformanceProvider extends ChangeNotifier {
  final Map<DateTime, int> _dailyScores = {};
  bool _loaded = false;

  Map<DateTime, int> get dailyScores => _dailyScores;
  bool get loaded => _loaded;

  PerformanceProvider() {
    loadFromStorage();
  }

  // ----------------------------------------
  // Load all stored daily ranked quiz scores from Hive
  // ----------------------------------------
  Future<void> loadFromStorage({bool forceReload = false}) async {
    if (_loaded && !forceReload) return;

    _dailyScores.clear();
    final all = HiveService.getAllDailyScores();
    for (final score in all) {
      final dateKey = DateTime(
        score.date.year,
        score.date.month,
        score.date.day,
      );
      _dailyScores[dateKey] = score.score < 0 ? 0 : score.score;
    }

    _loaded = true;
    notifyListeners();
  }

  // ----------------------------------------
  // Save today's ranked quiz score (called after quiz ends)
  // ----------------------------------------
  Future<void> addTodayScore(int score) async {
    final today = DateTime.now();
    final safeScore = score < 0 ? 0 : score;
    final dailyScore = DailyScore(date: today, score: safeScore);

    await HiveService.saveDailyScore(dailyScore);
    _dailyScores[today] = safeScore;
    notifyListeners();
  }

  // ----------------------------------------
  // Retrieve last 7 days for chart/heatmap
  // ----------------------------------------
  List<Map<String, dynamic>> getLast7DaysDailyRankScores() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    return days.map((d) {
      final s = _dailyScores[d] ?? 0;
      return {'date': d, 'score': s, 'attempted': _dailyScores.containsKey(d)};
    }).toList();
  }

  // ----------------------------------------
  // Compute 7-day average
  // ----------------------------------------
  int get weeklyAverage {
    final data = getLast7DaysDailyRankScores();
    final attempted = data.where((d) => d['attempted'] == true).toList();
    if (attempted.isEmpty) return 0;
    final total = attempted.fold<int>(0, (sum, d) => sum + (d['score'] as int));
    return (total / attempted.length).round();
  }

  // ----------------------------------------
  // Mock all-time rank (placeholder until online)
  // ----------------------------------------
  int get allTimeRank => 23142;

  // ----------------------------------------
  // Mock today's rank — based on score
  // ----------------------------------------
  int? get todayRank {
    final today = DateTime.now();
    if (!_dailyScores.containsKey(today)) return null;
    final s = _dailyScores[today] ?? 0;
    if (s <= 0) return null;
    return (5000 - (s * 10)).clamp(1000, 5000).toInt();
  }

  /// Fetch recent online attempts for the currently signed-in user.
  /// Returns a list of maps with a unified shape used by the AttemptsHistory screen.
  Future<List<Map<String, dynamic>>> fetchOnlineAttempts({
    int limit = 200,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // collectionGroup('entries') reads the per-day entries documents (daily_leaderboard/{date}/entries/{uid})
      final query = await FirebaseFirestore.instance
          .collectionGroup('entries')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final List<Map<String, dynamic>> out = [];

      for (final doc in query.docs) {
        final data = doc.data();
        // Normalize fields into a consistent map
        final Timestamp? ts = data['timestamp'] as Timestamp?;
        final DateTime date = ts?.toDate() ?? DateTime.now();

        final int correct = (data['correct'] ?? 0) as int;
        final int incorrect = (data['incorrect'] ?? 0) as int;
        final int total =
            (data['total'] ?? (correct + incorrect)) as int? ??
            (correct + incorrect);
        final int score = (data['score'] ?? 0) as int;
        final int timeTaken =
            (data['timeTaken'] ?? data['timeSpent'] ?? 0) as int;

        out.add({
          'source': 'online',
          'date': date,
          'topic': data['topic'] ?? 'Daily Ranked',
          'category': data['category'] ?? 'Daily Ranked',
          'correct': correct,
          'incorrect': incorrect,
          'total': total,
          'score': score,
          'timeSpentSeconds': timeTaken,
          'questions':
              data['questions'] ?? [], // optional if server stored them
          'userAnswers':
              data['userAnswers'] ?? {}, // optional if server stored them
          'raw': data,
        });
      }

      return out;
    } catch (e, st) {
      debugPrint('⚠️ fetchOnlineAttempts failed: $e\n$st');
      return [];
    }
  }

  // ----------------------------------------
  // Clear all data (testing)
  // ----------------------------------------
  Future<void> clearAll() async {
    await HiveService.clearDailyScores();
    _dailyScores.clear();
    notifyListeners();
  }
}
