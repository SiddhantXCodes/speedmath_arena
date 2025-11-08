// lib/data/hive_service.dart
import 'package:hive/hive.dart';
import 'models/practice_log.dart';
import 'models/question_history.dart';
import 'models/streak_data.dart';
import 'models/user_settings.dart';
import 'models/user_profile.dart';
import 'models/daily_quiz_meta.dart';
import 'models/daily_score.dart';

/// Centralized Hive helper used throughout the app.
/// - All box names are defined here for consistency.
/// - Date keys are normalized as yyyy-MM-dd strings.
class HiveService {
  // Box names (single source of truth)
  static const String _practiceBoxName = 'practice_logs';
  static const String _historyBoxName = 'question_history';
  static const String _streakBoxName = 'streak_data';
  static const String _settingsBoxName = 'settings';
  static const String _userBoxName = 'user_profile';
  static const String _dailyQuizBoxName = 'daily_quiz_meta';
  static const String _activityBoxName = 'activity_data';
  static const String _statsBoxName = 'stats_cache';
  static const String _dailyScoreBoxName = 'daily_scores';

  // Helpers to access boxes (assumes opened in main.dart)
  static Box<PracticeLog> get _practiceBox =>
      Hive.box<PracticeLog>(_practiceBoxName);
  static Box<QuestionHistory> get _historyBox =>
      Hive.box<QuestionHistory>(_historyBoxName);
  static Box<StreakData> get _streakBox => Hive.box<StreakData>(_streakBoxName);
  static Box<UserSettings> get _settingsBox =>
      Hive.box<UserSettings>(_settingsBoxName);
  static Box<UserProfile> get _userBox => Hive.box<UserProfile>(_userBoxName);
  static Box<DailyQuizMeta> get _dailyQuizBox =>
      Hive.box<DailyQuizMeta>(_dailyQuizBoxName);
  static Box<Map> get _activityBox => Hive.box<Map>(_activityBoxName);
  static Box<Map> get _statsBox => Hive.box<Map>(_statsBoxName);
  static Box<DailyScore> get _dailyScoreBox =>
      Hive.box<DailyScore>(_dailyScoreBoxName);

  // -------------------------
  // Date key formatting
  // -------------------------
  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // -------------------------
  // Practice Log (per session)
  // -------------------------
  static Future<void> addPracticeLog(PracticeLog log) async {
    await _practiceBox.add(log);
    // Update daily heatmap activity
    _incrementActivityForDate(log.date, 1);
    _recomputeStatsCache();
  }

  static List<PracticeLog> getPracticeLogs() => _practiceBox.values.toList();

  /// 🧹 Remove all practice logs for a specific date (used in streak toggle)
  static Future<void> removePracticeLogsForDate(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final toDelete = <dynamic>[];

    for (final key in _practiceBox.keys) {
      final PracticeLog? log = _practiceBox.get(key);
      if (log == null) continue;
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate == dateKey) {
        toDelete.add(key);
      }
    }

    for (final k in toDelete) {
      await _practiceBox.delete(k);
    }

    // Refresh aggregates after removal
    _recomputeStatsCache();
    await _rebuildActivityMap();
  }

  static Future<void> clearPracticeLogs() async {
    await _practiceBox.clear();
    await _activityBox.delete('activity');
    await _statsBox.delete('stats');
  }

  // -------------------------
  // Question History (per question)
  // -------------------------
  static Future<void> addQuestion(QuestionHistory q) async {
    await _historyBox.add(q);
    if (!q.isCorrect) {
      _recomputeStatsCache();
    }
  }

  static List<QuestionHistory> getHistory() => _historyBox.values.toList();

  static Future<void> clearQuestionHistory() async => _historyBox.clear();

  // -------------------------
  // Streak
  // -------------------------
  static Future<void> saveStreak(StreakData data) async {
    await _streakBox.put('streak', data);
  }

  static StreakData? getStreak() => _streakBox.get('streak');

  static Future<void> clearStreak() async => _streakBox.clear();

  // -------------------------
  // User settings
  // -------------------------
  static Future<void> saveSettings(UserSettings s) async =>
      _settingsBox.put('settings', s);
  static UserSettings? getSettings() => _settingsBox.get('settings');
  static Future<void> clearSettings() async => _settingsBox.clear();

  // -------------------------
  // User profile (cached from Firebase)
  // -------------------------
  static Future<void> saveUser(UserProfile u) async =>
      await _userBox.put(u.uid, u);
  static UserProfile? getUser(String uid) => _userBox.get(uid);
  static Future<void> clearUser(String uid) async => await _userBox.delete(uid);

  // -------------------------
  // Daily Quiz Meta (cached per-date)
  // -------------------------
  static Future<void> saveDailyQuizMeta(DailyQuizMeta meta) async {
    await _dailyQuizBox.put(meta.date, meta);
  }

  static DailyQuizMeta? getDailyQuizMeta(String dateKey) =>
      _dailyQuizBox.get(dateKey);

  // -------------------------
  // Activity map (heatmap aggregation)
  // stored as Map<String(DateKey) -> int(count)>
  // -------------------------
  static void _incrementActivityForDate(DateTime d, int by) {
    const key = 'activity';
    final Map? raw = _activityBox.get(key);
    final Map<String, dynamic> activity = raw != null
        ? Map<String, dynamic>.from(raw)
        : {};
    final dateKey = _dateKey(d);
    final int existing = (activity[dateKey] ?? 0) as int;
    activity[dateKey] = existing + by;
    _activityBox.put(key, activity);
  }

  static Future<void> _rebuildActivityMap() async {
    final Map<String, int> rebuilt = {};
    for (final log in getPracticeLogs()) {
      final key = _dateKey(log.date);
      rebuilt[key] = (rebuilt[key] ?? 0) + 1;
    }
    await _activityBox.put('activity', rebuilt);
  }

  static Map<DateTime, int> getActivityMap() {
    final Map? raw = _activityBox.get('activity');
    if (raw == null) return {};
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
    final Map<DateTime, int> out = {};
    m.forEach((k, v) {
      try {
        final parts = k.split('-');
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        out[dt] = (v as num).toInt();
      } catch (_) {}
    });
    return out;
  }

  static Future<void> saveActivityMap(Map<String, dynamic> activityMap) async {
    await _activityBox.put('activity', activityMap);
  }

  // -------------------------
  // Stats cache (quick derived metrics)
  // -------------------------
  static void _recomputeStatsCache() {
    final logs = getPracticeLogs();
    int sessions = logs.length;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    double totalTime = 0.0;

    for (final l in logs) {
      totalCorrect += l.correct;
      totalIncorrect += l.incorrect;
      totalTime += l.avgTime;
    }

    final Map<String, dynamic> stats = {
      'sessions': sessions,
      'totalCorrect': totalCorrect,
      'totalIncorrect': totalIncorrect,
      'avgTime': sessions > 0 ? (totalTime / sessions) : 0.0,
    };

    _statsBox.put('stats', stats);
  }

  static Map<String, dynamic>? getStats() {
    final raw = _statsBox.get('stats');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> saveStats(Map<String, dynamic> stats) async =>
      await _statsBox.put('stats', stats);

  // -------------------------
  // Daily ranked scores (cached locally too)
  // -------------------------
  static Future<void> saveDailyScore(DailyScore score) async {
    final key = _dateKey(score.date);
    await _dailyScoreBox.put(key, score);
  }

  static DailyScore? getDailyScore(DateTime date) {
    final key = _dateKey(date);
    return _dailyScoreBox.get(key);
  }

  static List<DailyScore> getAllDailyScores() => _dailyScoreBox.values.toList();

  static Future<void> clearDailyScores() async => await _dailyScoreBox.clear();

  // -------------------------
  // Debug / QA helpers
  // -------------------------
  static void dumpPracticeLogs() {
    final logs = getPracticeLogs();
    for (var l in logs) {
      print(
        'PracticeLog - ${l.date.toIso8601String()} | ${l.category} | c:${l.correct} i:${l.incorrect} t:${l.avgTime}',
      );
    }
  }

  static Future<void> clearAllOfflineData() async {
    await clearPracticeLogs();
    await clearQuestionHistory();
    await clearStreak();
    await clearSettings();
    await _dailyQuizBox.clear();
    await _activityBox.clear();
    await _statsBox.clear();
    await clearDailyScores();
  }

  // -------------------------
  // Extra safe helpers
  // -------------------------
  static bool isBoxOpen(String name) => Hive.isBoxOpen(name);
}
