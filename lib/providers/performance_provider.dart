// lib/providers/performance_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceProvider extends ChangeNotifier {
  final Map<DateTime, int> _dailyScores = {}; // date → score
  bool _loaded = false;

  Map<DateTime, int> get dailyScores => _dailyScores;
  bool get loaded => _loaded;

  /// Loads all stored daily ranked quiz scores from SharedPreferences.
  Future<void> loadFromStorage({bool forceReload = false}) async {
    if (_loaded && !forceReload) return;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('daily_score_'));
    _dailyScores.clear();

    for (final k in keys) {
      final dateStr = k.replaceFirst('daily_score_', '');
      final date = DateTime.tryParse(dateStr);
      final score = prefs.getInt(k) ?? 0;
      if (date != null) {
        _dailyScores[DateTime(date.year, date.month, date.day)] = score < 0
            ? 0
            : score;
      }
    }

    _loaded = true;
    notifyListeners();
  }

  /// Save today’s daily ranked quiz score (clamped to ≥0)
  Future<void> addTodayScore(int score) async {
    final today = DateTime.now();
    final dateKey = DateTime(
      today.year,
      today.month,
      today.day,
    ); // strip time portion
    final keyStr = 'daily_score_${today.toIso8601String().substring(0, 10)}';
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(keyStr, score < 0 ? 0 : score);
    _dailyScores[dateKey] = score < 0 ? 0 : score;
    notifyListeners();
  }

  /// Return structured list for the last 7 days for charting
  List<Map<String, dynamic>> getLast7DaysDailyRankScores() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];

    // Last 7 days including today
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    for (final day in days) {
      final entry = _dailyScores.entries.firstWhere(
        (e) => _sameDate(e.key, day),
        orElse: () => MapEntry(day, 0),
      );
      result.add({
        'date': day,
        'score': entry.value < 0 ? 0 : entry.value,
        'attempted': _dailyScores.containsKey(entry.key),
      });
    }

    return result;
  }

  /// Compute 7-day average (excluding skipped days)
  int get weeklyAverage {
    final data = getLast7DaysDailyRankScores();
    final attempted = data.where((d) => d['attempted'] == true).toList();
    if (attempted.isEmpty) return 0;
    final total = attempted.fold<int>(
      0,
      (sum, d) => sum + ((d['score'] ?? 0) as num).toInt(),
    );
    return (total / attempted.length).round();
  }

  /// Placeholder for all-time rank (you can replace with real server data later)
  int get allTimeRank => 23142;

  /// Mock today's rank — based on today's score
  int? get todayRank {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    if (!_dailyScores.containsKey(todayKey)) return null;

    final score = _dailyScores[todayKey] ?? 0;
    if (score <= 0) return null;

    // Compute fake rank: higher score → lower rank
    final rank = (5000 - (score * 10)).clamp(1000, 5000).toInt();
    return rank;
  }

  /// Retrieve the last 7 numeric scores (for compatibility with old charts)
  List<int> getLast7DaysScores() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    return days.map((d) {
      final key = DateTime(d.year, d.month, d.day);
      final match = _dailyScores.entries.firstWhere(
        (e) => _sameDate(e.key, key),
        orElse: () => MapEntry(key, 0),
      );
      return match.value < 0 ? 0 : match.value;
    }).toList();
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
