import 'package:flutter/material.dart';
import '../data/models/daily_score.dart';
import '../data/hive_service.dart';

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

  // ----------------------------------------
  // Clear all data (testing)
  // ----------------------------------------
  Future<void> clearAll() async {
    await HiveService.clearDailyScores();
    _dailyScores.clear();
    notifyListeners();
  }
}
