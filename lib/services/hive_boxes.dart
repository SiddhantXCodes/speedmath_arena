//lib/services/hive_boxes.dart

import 'package:hive_flutter/hive_flutter.dart';

// 🧩 Core Models
import '../models/user_profile.dart';
import '../models/user_settings.dart';

// 🧩 Feature Models
import '../models/practice_log.dart';
import '../models/question_history.dart';
import '../models/daily_score.dart';
import '../models/daily_quiz_meta.dart';
import '../models/streak_data.dart';

/// 🚀 Central Hive initialization (ALL boxes + adapters)
class HiveBoxes {
  // ===========================================================================
  // INIT
  // ===========================================================================
  static Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters();
    await openEssentialBoxes();
    openBackgroundBoxes();
  }

  // ===========================================================================
  // ADAPTERS
  // ===========================================================================
  static void registerAdapters() {
    // Core
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(UserSettingsAdapter());

    // Practice Logs
    Hive.registerAdapter(PracticeLogAdapter());
    Hive.registerAdapter(QuestionHistoryAdapter());

    // Scores (old + new system)
    Hive.registerAdapter(DailyScoreAdapter());

    // Quiz Meta + Streak
    Hive.registerAdapter(DailyQuizMetaAdapter());
    Hive.registerAdapter(StreakDataAdapter());
  }

  // ===========================================================================
  // ESSENTIAL BOXES (must load before UI builds)
  // ===========================================================================
  static Future<void> openEssentialBoxes() async {
    await Hive.openBox<UserProfile>('user_profile');
    await Hive.openBox<UserSettings>('user_settings');
    await Hive.openBox<StreakData>('streak_data');

    // Activity + History
    await Hive.openBox<Map>('activity_data');
    await Hive.openBox<PracticeLog>('practice_logs');
    await Hive.openBox<QuestionHistory>('question_history');

    // OLD DailyScore (used for: heatmap + performance screen)
    await Hive.openBox<DailyScore>('daily_scores');

    // NEW separated score boxes (required for clean history)
    await Hive.openBox<DailyScore>('practice_scores');
    await Hive.openBox<DailyScore>('ranked_scores');
    await Hive.openBox<DailyScore>('mixed_scores');

    await Hive.openBox<DailyQuizMeta>('daily_quiz_meta');
    await Hive.openBox('leaderboard_cache');
    await Hive.openBox<Map>('sync_queue');
  }

  // ===========================================================================
  // BACKGROUND BOXES (optional future use)
  // ===========================================================================
  static Future<void> openBackgroundBoxes() async {
    Future.microtask(() async {
      // Keep empty for now – everything needed is in essential section.
    });
  }

  // ===========================================================================
  // ACCESSORS
  // ===========================================================================

  // Core
  static Box<UserProfile> get userProfileBox =>
      Hive.box<UserProfile>('user_profile');

  static Box<UserSettings> get userSettingsBox =>
      Hive.box<UserSettings>('user_settings');

  // Practice Logs
  static Box<PracticeLog> get practiceLogBox =>
      Hive.box<PracticeLog>('practice_logs');

  static Box<QuestionHistory> get questionHistoryBox =>
      Hive.box<QuestionHistory>('question_history');

  // OLD score system
  static Box<DailyScore> get dailyScoreBox =>
      Hive.box<DailyScore>('daily_scores');

  // NEW separated score storage
  static Box<DailyScore> get practiceScoreBox =>
      Hive.box<DailyScore>('practice_scores');

  static Box<DailyScore> get rankedScoreBox =>
      Hive.box<DailyScore>('ranked_scores');

  static Box<DailyScore> get mixedScoreBox =>
      Hive.box<DailyScore>('mixed_scores');

  // Streak + meta
  static Box<StreakData> get streakData => Hive.box<StreakData>('streak_data');

  static Box<DailyQuizMeta> get dailyQuizMeta =>
      Hive.box<DailyQuizMeta>('daily_quiz_meta');

  // Misc
  static Box get leaderboardCacheBox => Hive.box('leaderboard_cache');

  static Box<Map> get syncQueueBox => Hive.box<Map>('sync_queue');

  static Box<Map> get activityDataBox => Hive.box<Map>('activity_data');
}
