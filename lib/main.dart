import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/practice_log.dart';
import 'data/models/question_history.dart';
import 'data/models/streak_data.dart';
import 'data/models/user_settings.dart';
import 'data/models/user_profile.dart';
import 'data/models/daily_quiz_meta.dart';
import 'data/models/daily_score.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  // Register all Hive adapters
  Hive.registerAdapter(PracticeLogAdapter());
  Hive.registerAdapter(QuestionHistoryAdapter());
  Hive.registerAdapter(StreakDataAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(DailyQuizMetaAdapter());
  Hive.registerAdapter(DailyScoreAdapter());
  // Open boxes
  await Hive.openBox<PracticeLog>('practice_logs');
  await Hive.openBox<QuestionHistory>('question_history');
  await Hive.openBox<StreakData>('streak_data');
  await Hive.openBox<UserSettings>('settings');
  await Hive.openBox<UserProfile>('user_profile');
  await Hive.openBox<DailyQuizMeta>('daily_quiz_meta');
  await Hive.openBox<Map>('activity_data');
  await Hive.openBox<Map>('stats_cache');
  // Smooth animations
  GestureBinding.instance.resamplingEnabled = false;

  runApp(const SpeedMathApp());
}
