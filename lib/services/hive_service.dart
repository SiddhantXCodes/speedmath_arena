//lib/services/hive_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

// HiveBoxes import
import 'hive_boxes.dart';

// Models
import '../models/practice_log.dart';
import '../models/question_history.dart';
import '../models/streak_data.dart';
import '../models/daily_quiz_meta.dart';
import '../models/daily_score.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

class HiveService {
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Box<T>> _safeBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }

  // ---------------------------------------------------------------------------
  // PRACTICE LOGS
  // ---------------------------------------------------------------------------

  static Future<void> addPracticeLog(PracticeLog log) async {
    final box = HiveBoxes.practiceLogBox;
    await box.add(log);
    await _incrementActivityForDate(log.date, 1);
  }

  static List<PracticeLog> getPracticeLogs() {
    if (!Hive.isBoxOpen('practice_logs')) return [];
    return HiveBoxes.practiceLogBox.values.toList();
  }

  static Future<void> clearPracticeLogs() async {
    await HiveBoxes.practiceLogBox.clear();
    if (Hive.isBoxOpen('activity_data')) {
      await Hive.box<Map>('activity_data').delete('activity');
    }
  }

  // ---------------------------------------------------------------------------
  // QUESTION HISTORY
  // ---------------------------------------------------------------------------

  static Future<void> addQuestion(QuestionHistory q) async {
    final box = HiveBoxes.questionHistoryBox;
    await box.add(q);
  }

  static List<QuestionHistory> getHistory() {
    if (!Hive.isBoxOpen('question_history')) return [];
    return HiveBoxes.questionHistoryBox.values.toList();
  }

  // ---------------------------------------------------------------------------
  // STREAK / USER / SETTINGS
  // ---------------------------------------------------------------------------

  static Future<void> saveStreak(StreakData data) async {
    final box = await _safeBox<StreakData>('streak_data');
    await box.put('streak', data);
  }

  static StreakData? getStreak() {
    if (!Hive.isBoxOpen('streak_data')) return null;
    return Hive.box<StreakData>('streak_data').get('streak');
  }

  static Future<void> saveSettings(UserSettings settings) async {
    final box = await _safeBox<UserSettings>('user_settings');
    await box.put('settings', settings);
  }

  static UserSettings? getSettings() {
    if (!Hive.isBoxOpen('user_settings')) return null;
    return Hive.box<UserSettings>('user_settings').get('settings');
  }

  static Future<void> saveUser(UserProfile user) async {
    final box = await _safeBox<UserProfile>('user_profile');
    await box.put(user.uid, user);
  }

  static UserProfile? getUser(String uid) {
    if (!Hive.isBoxOpen('user_profile')) return null;
    return Hive.box<UserProfile>('user_profile').get(uid);
  }

  // ---------------------------------------------------------------------------
  // DAILY QUIZ META + SCORES
  // ---------------------------------------------------------------------------

  static Future<void> saveDailyQuizMeta(DailyQuizMeta meta) async {
    final box = await _safeBox<DailyQuizMeta>('daily_quiz_meta');
    await box.put(meta.date, meta);
  }

  static DailyQuizMeta? getDailyQuizMeta(String dateKey) {
    if (!Hive.isBoxOpen('daily_quiz_meta')) return null;
    return Hive.box<DailyQuizMeta>('daily_quiz_meta').get(dateKey);
  }

  static Future<void> addDailyScore(DailyScore score) async {
    final box = await _safeBox<DailyScore>('daily_scores');
    await box.put(_dateKey(score.date), score);
  }

  static List<DailyScore> getAllDailyScores() {
    if (!Hive.isBoxOpen('daily_scores')) return [];
    return Hive.box<DailyScore>('daily_scores').values.toList();
  }

  /// 🔥 FIXED — REQUIRED BY PerformanceRepository
  static Future<void> clearDailyScores() async {
    final box = await _safeBox<DailyScore>('daily_scores');
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY MAP
  // ---------------------------------------------------------------------------

  static Future<void> _incrementActivityForDate(DateTime d, int by) async {
    final box = await _safeBox<Map>('activity_data');
    final raw = box.get('activity');
    final data = raw != null ? Map<String, dynamic>.from(raw) : {};
    final k = _dateKey(d);

    data[k] = (data[k] ?? 0) + by;

    await box.put('activity', data);
  }

  static Map<DateTime, int> getActivityMap() {
    if (!Hive.isBoxOpen('activity_data')) return {};
    final raw = Hive.box<Map>('activity_data').get('activity');
    if (raw == null) return {};

    final out = <DateTime, int>{};

    Map<String, dynamic>.from(raw).forEach((k, v) {
      try {
        final p = k.split('-');
        out[DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))] =
            (v as num).toInt();
      } catch (_) {}
    });

    return out;
  }

  // ---------------------------------------------------------------------------
  // STATS
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> getStats() {
    if (!Hive.isBoxOpen('practice_logs')) return {};

    final logs = HiveBoxes.practiceLogBox.values.toList();
    if (logs.isEmpty) return {};

    int correct = 0, wrong = 0;
    double totalAvg = 0;

    for (final l in logs) {
      correct += l.correct;
      wrong += l.incorrect;
      totalAvg += l.avgTime;
    }

    return {
      'sessions': logs.length,
      'totalCorrect': correct,
      'totalIncorrect': wrong,
      'avgTime': logs.isNotEmpty ? totalAvg / logs.length : 0.0,
    };
  }

  // ---------------------------------------------------------------------------
  // SYNC QUEUE
  // ---------------------------------------------------------------------------

  static Future<void> queueForSync(
    String type,
    Map<String, dynamic> data,
  ) async {
    final box = await _safeBox<Map>('sync_queue');
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {'id': id, 'type': type, 'data': data});
  }

  static List<Map<String, dynamic>> getPendingSyncs() {
    if (!Hive.isBoxOpen('sync_queue')) return [];
    return Hive.box<Map>(
      'sync_queue',
    ).values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearPendingSyncsOfType(String type) async {
    final box = await _safeBox<Map>('sync_queue');

    final keysToDelete = box.keys.where((k) {
      final item = box.get(k);
      return item != null && item['type'] == type;
    }).toList();

    for (final k in keysToDelete) {
      await box.delete(k);
    }
  }

  static Future<void> clearSynced(String id) async {
    final box = await _safeBox<Map>('sync_queue');
    await box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // CLEAR EVERYTHING
  // ---------------------------------------------------------------------------

  static Future<void> clearAllOfflineData() async {
    await HiveBoxes.practiceLogBox.clear();
    await HiveBoxes.questionHistoryBox.clear();
    await HiveBoxes.dailyScoreBox.clear();
    await (await _safeBox<DailyQuizMeta>('daily_quiz_meta')).clear();
    await (await _safeBox<Map>('activity_data')).clear();
    await (await _safeBox<Map>('sync_queue')).clear();
  }

  static bool isBoxOpen(String name) => Hive.isBoxOpen(name);
}
