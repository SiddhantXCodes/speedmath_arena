// lib/providers/practice_log_provider.dart

import 'package:flutter/material.dart';
import '../models/practice_log.dart';
import '../features/practice/practice_repository.dart';

/// 🧠 PracticeLogProvider — Bridges UI ↔ Repository
/// FIXED: Adds `initialized` flag so HomeScreen waits until data loads.
class PracticeLogProvider extends ChangeNotifier {
  final PracticeRepository _repository = PracticeRepository();

  List<PracticeLog> _logs = [];
  List<PracticeLog> get logs => _logs;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 🌟 MAIN FIX → HomeScreen waits for this
  bool initialized = false;

  /// 🌟 In-memory activity map (fast + correct)
  Map<DateTime, int> _activityMap = {};
  Map<DateTime, int> get activityMap => _activityMap;

  PracticeLogProvider() {
    _init(); // async load
  }

  // --------------------------------------------------------------
  // 🔥 FIX: Load logs BEFORE HomeScreen builds its heatmap
  // --------------------------------------------------------------
  Future<void> _init() async {
    await loadLogs();
    initialized = true; // <-- MAIN FIX
    notifyListeners(); // notify after complete load
  }

  // --------------------------------------------------------------
  // 📦 Load all local logs (Hive)
  // --------------------------------------------------------------
  Future<void> loadLogs() async {
    _logs = _repository.getAllLocalSessions();
    _activityMap = _repository.getActivityMapFromHive();
    notifyListeners();
  }

  // --------------------------------------------------------------
  // ➕ Add new session (offline-first)
  // --------------------------------------------------------------
  Future<void> addSession({
    required String topic,
    required String category,
    required int correct,
    required int incorrect,
    required int score,
    required int total,
    required double avgTime,
    required int timeSpentSeconds,
    List<Map<String, dynamic>>? questions,
    Map<int, String>? userAnswers,
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

      await _repository.savePracticeSession(log);

      _logs.add(log);

      // 🔥 Update heatmap instantly
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      _activityMap[day] = (_activityMap[day] ?? 0) + 1;

      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Failed to add practice session: $e");
    }
  }

  // --------------------------------------------------------------
  // 🔄 Sync pending logs to Firebase
  // --------------------------------------------------------------
  Future<void> syncPending() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _repository.syncPendingSessions();
    } catch (e) {
      debugPrint("⚠️ Practice sync failed: $e");
    }

    _isSyncing = false;
    notifyListeners();
  }

  // --------------------------------------------------------------
  // 🗓 Activity map
  // --------------------------------------------------------------
  Map<DateTime, int> getActivityMap() => _activityMap;

  // --------------------------------------------------------------
  // 📊 Day summary
  // --------------------------------------------------------------
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

    for (final log in dayLogs) {
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

  // --------------------------------------------------------------
  // 📜 Unified list for history
  // --------------------------------------------------------------
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
        'questions': log.questions,
        'userAnswers': log.userAnswers,
        'raw': log,
      };
    }).toList();
  }

  // --------------------------------------------------------------
  // 🧹 Clear all local practice logs
  // --------------------------------------------------------------
  Future<void> clearAll() async {
    await _repository.clearAllLocalData();
    _logs.clear();
    _activityMap.clear();
    notifyListeners();
  }
}
