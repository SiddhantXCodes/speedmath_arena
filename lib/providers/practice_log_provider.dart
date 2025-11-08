// lib/providers/practice_log_provider.dart
import 'package:flutter/material.dart';
import '../data/models/practice_log.dart';
import '../data/hive_service.dart';

class PracticeLogProvider extends ChangeNotifier {
  List<PracticeLog> _logs = [];

  List<PracticeLog> get logs => _logs;

  PracticeLogProvider() {
    _loadLogs();
  }

  // ----------------------------------------
  // Load all practice logs from Hive
  // ----------------------------------------
  Future<void> _loadLogs() async {
    _logs = HiveService.getPracticeLogs();
    notifyListeners();
  }

  // ----------------------------------------
  // Add a new practice session (after quiz ends)
  // Works for: Offline quizzes, Ranked quizzes, Smart practice, etc.
  // ----------------------------------------
  Future<void> addSession({
    required String topic,
    required String category,
    required int correct,
    required int incorrect,
    required int score,
    required int total,
    required double avgTime,
    required int timeSpentSeconds,
  }) async {
    try {
      final log = PracticeLog(
        date: DateTime.now(),
        topic: topic,
        category: category,
        correct: correct,
        incorrect: incorrect,
        score: score,
        total: total,
        avgTime: avgTime,
        timeSpentSeconds: timeSpentSeconds,
      );

      await HiveService.addPracticeLog(log);
      _logs.add(log);
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Failed to add session: $e");
    }
  }

  // ----------------------------------------
  // Get daily intensity map for HeatmapSection
  // ----------------------------------------
  Map<DateTime, int> getActivityMap() => HiveService.getActivityMap();

  // ----------------------------------------
  // Get detailed summary for a specific day
  // ----------------------------------------
  Map<String, dynamic>? getDaySummary(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final dayLogs = _logs.where(
      (log) =>
          log.date.year == key.year &&
          log.date.month == key.month &&
          log.date.day == key.day,
    );

    if (dayLogs.isEmpty) return null;

    int totalCorrect = 0;
    int totalIncorrect = 0;
    double totalTime = 0;

    for (var log in dayLogs) {
      totalCorrect += log.correct;
      totalIncorrect += log.incorrect;
      totalTime += log.avgTime;
    }

    return {
      'sessions': dayLogs.length,
      'correct': totalCorrect,
      'incorrect': totalIncorrect,
      'avgTime': totalTime / dayLogs.length,
    };
  }

  // ----------------------------------------
  // Clear all logs (testing / reset)
  // ----------------------------------------
  Future<void> clearAll() async {
    await HiveService.clearPracticeLogs();
    _logs.clear();
    notifyListeners();
  }
}
