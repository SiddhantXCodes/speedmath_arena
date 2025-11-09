import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models/practice_log.dart';
import 'models/question_history.dart';
import 'models/streak_data.dart';
import 'models/user_settings.dart';
import 'models/user_profile.dart';
import 'models/daily_quiz_meta.dart';
import 'models/daily_score.dart';

/// 💾 Centralized Hive helper with safe async access.
/// Automatically re-opens any closed boxes.
class HiveService {
  // Box names
  static const _practiceBox = 'practice_logs';
  static const _historyBox = 'question_history';
  static const _streakBox = 'streak_data';
  static const _settingsBox = 'settings';
  static const _userBox = 'user_profile';
  static const _dailyQuizBox = 'daily_quiz_meta';
  static const _activityBox = 'activity_data';
  static const _statsBox = 'stats_cache';
  static const _dailyScoreBox = 'daily_scores';

  // Helper: safely open box (auto opens if missing)
  static Future<Box<T>> _safeBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      try {
        return await Hive.openBox<T>(name);
      } catch (e) {
        debugPrint('⚠️ HiveService: Failed to open box $name — $e');
        rethrow;
      }
    }
    return Hive.box<T>(name);
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // 🧩 PRACTICE LOGS
  // ---------------------------------------------------------------------------
  static Future<void> addPracticeLog(PracticeLog log) async {
    final box = await _safeBox<PracticeLog>(_practiceBox);
    await box.add(log);
    _incrementActivityForDate(log.date, 1);
    _recomputeStatsCache();
  }

  static List<PracticeLog> getPracticeLogs() {
    if (!Hive.isBoxOpen(_practiceBox)) return [];
    return Hive.box<PracticeLog>(_practiceBox).values.toList();
  }

  static Future<void> removePracticeLogsForDate(DateTime date) async {
    final box = await _safeBox<PracticeLog>(_practiceBox);
    final toDelete = <dynamic>[];

    for (final key in box.keys) {
      final PracticeLog? log = box.get(key);
      if (log == null) continue;
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate == DateTime(date.year, date.month, date.day))
        toDelete.add(key);
    }

    for (final k in toDelete) {
      await box.delete(k);
    }

    _recomputeStatsCache();
    await _rebuildActivityMap();
  }

  static Future<void> clearPracticeLogs() async {
    final box = await _safeBox<PracticeLog>(_practiceBox);
    await box.clear();

    if (Hive.isBoxOpen(_activityBox)) {
      final a = Hive.box<Map>(_activityBox);
      await a.delete('activity');
    }

    if (Hive.isBoxOpen(_statsBox)) {
      final s = Hive.box<Map>(_statsBox);
      await s.delete('stats');
    }
  }

  // ---------------------------------------------------------------------------
  // 🧮 QUESTION HISTORY
  // ---------------------------------------------------------------------------
  static Future<void> addQuestion(QuestionHistory q) async {
    final box = await _safeBox<QuestionHistory>(_historyBox);
    await box.add(q);
    if (!q.isCorrect) _recomputeStatsCache();
  }

  static List<QuestionHistory> getHistory() {
    if (!Hive.isBoxOpen(_historyBox)) return [];
    return Hive.box<QuestionHistory>(_historyBox).values.toList();
  }

  static Future<void> clearQuestionHistory() async {
    final box = await _safeBox<QuestionHistory>(_historyBox);
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // 🔥 STREAK
  // ---------------------------------------------------------------------------
  static Future<void> saveStreak(StreakData data) async {
    final box = await _safeBox<StreakData>(_streakBox);
    await box.put('streak', data);
  }

  static StreakData? getStreak() {
    if (!Hive.isBoxOpen(_streakBox)) return null;
    return Hive.box<StreakData>(_streakBox).get('streak');
  }

  static Future<void> clearStreak() async {
    final box = await _safeBox<StreakData>(_streakBox);
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // ⚙️ SETTINGS
  // ---------------------------------------------------------------------------
  static Future<void> saveSettings(UserSettings s) async {
    final box = await _safeBox<UserSettings>(_settingsBox);
    await box.put('settings', s);
  }

  static UserSettings? getSettings() {
    if (!Hive.isBoxOpen(_settingsBox)) return null;
    return Hive.box<UserSettings>(_settingsBox).get('settings');
  }

  static Future<void> clearSettings() async {
    final box = await _safeBox<UserSettings>(_settingsBox);
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // 👤 USER PROFILE
  // ---------------------------------------------------------------------------
  static Future<void> saveUser(UserProfile u) async {
    final box = await _safeBox<UserProfile>(_userBox);
    await box.put(u.uid, u);
  }

  static UserProfile? getUser(String uid) {
    if (!Hive.isBoxOpen(_userBox)) return null;
    return Hive.box<UserProfile>(_userBox).get(uid);
  }

  static Future<void> clearUser(String uid) async {
    final box = await _safeBox<UserProfile>(_userBox);
    await box.delete(uid);
  }

  // ---------------------------------------------------------------------------
  // 🗓️ DAILY QUIZ META
  // ---------------------------------------------------------------------------
  static Future<void> saveDailyQuizMeta(DailyQuizMeta meta) async {
    final box = await _safeBox<DailyQuizMeta>(_dailyQuizBox);
    await box.put(meta.date, meta);
  }

  static DailyQuizMeta? getDailyQuizMeta(String dateKey) {
    if (!Hive.isBoxOpen(_dailyQuizBox)) return null;
    return Hive.box<DailyQuizMeta>(_dailyQuizBox).get(dateKey);
  }

  // ---------------------------------------------------------------------------
  // 🔥 ACTIVITY MAP
  // ---------------------------------------------------------------------------
  static Future<void> _incrementActivityForDate(DateTime d, int by) async {
    final box = await _safeBox<Map>(_activityBox);
    const key = 'activity';
    final Map? raw = box.get(key);
    final Map<String, dynamic> activity = raw != null
        ? Map<String, dynamic>.from(raw)
        : {};
    final dateKey = _dateKey(d);
    final int existing = (activity[dateKey] ?? 0) as int;
    activity[dateKey] = existing + by;
    await box.put(key, activity);
  }

  static Future<void> _rebuildActivityMap() async {
    final logs = getPracticeLogs();
    final box = await _safeBox<Map>(_activityBox);
    final Map<String, int> rebuilt = {};
    for (final log in logs) {
      final key = _dateKey(log.date);
      rebuilt[key] = (rebuilt[key] ?? 0) + 1;
    }
    await box.put('activity', rebuilt);
  }

  static Map<DateTime, int> getActivityMap() {
    if (!Hive.isBoxOpen(_activityBox)) return {};
    final box = Hive.box<Map>(_activityBox);
    final Map? raw = box.get('activity');
    if (raw == null) return {};
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
    final Map<DateTime, int> out = {};
    m.forEach((k, v) {
      try {
        final p = k.split('-');
        out[DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))] =
            (v as num).toInt();
      } catch (_) {}
    });
    return out;
  }

  // ---------------------------------------------------------------------------
  // 📊 STATS CACHE
  // ---------------------------------------------------------------------------
  static Future<void> _recomputeStatsCache() async {
    final logs = getPracticeLogs();
    final box = await _safeBox<Map>(_statsBox);

    int sessions = logs.length;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    double totalTime = 0;

    for (final l in logs) {
      totalCorrect += l.correct;
      totalIncorrect += l.incorrect;
      totalTime += l.avgTime;
    }

    final Map<String, dynamic> stats = {
      'sessions': sessions,
      'totalCorrect': totalCorrect,
      'totalIncorrect': totalIncorrect,
      'avgTime': sessions > 0 ? totalTime / sessions : 0.0,
    };

    await box.put('stats', stats);
  }

  static Map<String, dynamic>? getStats() {
    if (!Hive.isBoxOpen(_statsBox)) return null;
    final box = Hive.box<Map>(_statsBox);
    final raw = box.get('stats');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  // ---------------------------------------------------------------------------
  // 🏆 DAILY SCORE
  // ---------------------------------------------------------------------------
  static Future<void> saveDailyScore(DailyScore score) async {
    final box = await _safeBox<DailyScore>(_dailyScoreBox);
    final key = _dateKey(score.date);
    await box.put(key, score);
  }

  static DailyScore? getDailyScore(DateTime date) {
    if (!Hive.isBoxOpen(_dailyScoreBox)) return null;
    final box = Hive.box<DailyScore>(_dailyScoreBox);
    final key = _dateKey(date);
    return box.get(key);
  }

  static List<DailyScore> getAllDailyScores() {
    if (!Hive.isBoxOpen(_dailyScoreBox)) return [];
    return Hive.box<DailyScore>(_dailyScoreBox).values.toList();
  }

  static Future<void> clearDailyScores() async {
    final box = await _safeBox<DailyScore>(_dailyScoreBox);
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // 🧹 CLEAR ALL
  // ---------------------------------------------------------------------------
  static Future<void> clearAllOfflineData() async {
    await clearPracticeLogs();
    await clearQuestionHistory();
    await clearStreak();
    await clearSettings();
    final dq = await _safeBox<DailyQuizMeta>(_dailyQuizBox);
    await dq.clear();
    final act = await _safeBox<Map>(_activityBox);
    await act.clear();
    final stats = await _safeBox<Map>(_statsBox);
    await stats.clear();
    await clearDailyScores();
  }

  static bool isBoxOpen(String name) => Hive.isBoxOpen(name);
}
