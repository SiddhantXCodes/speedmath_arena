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
    List<Map<String, dynamic>>? questions, // ✅ new optional param
    Map<int, String>? userAnswers, // ✅ new optional param
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
        questions: questions ?? [],
        userAnswers: userAnswers ?? {},
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
  // Return all sessions as maps for History Screen
  // Includes both summary and stored question data
  // ----------------------------------------
  List<Map<String, dynamic>> getAllSessions() {
    return _logs.map((log) {
      return {
        'source': 'offline',
        'date': log.date,
        'topic': log.topic,
        'category': log.category,
        'correct': log.correct,
        'incorrect': log.incorrect,
        'total': log.total,
        'score': log.score,
        'timeSpentSeconds': log.timeSpentSeconds,
        // ✅ Defensive fix: in case old Hive logs don't have these fields
        'questions': log.questions ?? [],
        'userAnswers': log.userAnswers ?? {},
        'raw': log,
      };
    }).toList();
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
