import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
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
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  bool _isReady = false;
  String _message = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase asynchronously
      setState(() => _message = "Connecting to Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Hive
      setState(() => _message = "Preparing local storage...");
      await Hive.initFlutter();

      // Register adapters only if not registered yet
      if (!Hive.isAdapterRegistered(0))
        Hive.registerAdapter(PracticeLogAdapter());
      if (!Hive.isAdapterRegistered(1))
        Hive.registerAdapter(QuestionHistoryAdapter());
      if (!Hive.isAdapterRegistered(2))
        Hive.registerAdapter(StreakDataAdapter());
      if (!Hive.isAdapterRegistered(3))
        Hive.registerAdapter(UserSettingsAdapter());
      if (!Hive.isAdapterRegistered(4))
        Hive.registerAdapter(UserProfileAdapter());
      if (!Hive.isAdapterRegistered(5))
        Hive.registerAdapter(DailyQuizMetaAdapter());
      if (!Hive.isAdapterRegistered(6))
        Hive.registerAdapter(DailyScoreAdapter());

      // Open only the most important boxes immediately
      await Future.wait([
        Hive.openBox<UserSettings>('settings'),
        Hive.openBox<UserProfile>('user_profile'),
      ]);

      // Open heavy boxes in background (non-blocking)
      Future(() async {
        await Hive.openBox<PracticeLog>('practice_logs');
        await Hive.openBox<QuestionHistory>('question_history');
        await Hive.openBox<StreakData>('streak_data');
        await Hive.openBox<DailyQuizMeta>('daily_quiz_meta');
        await Hive.openBox<Map>('activity_data');
        await Hive.openBox<Map>('stats_cache');
      });

      GestureBinding.instance.resamplingEnabled = false;

      setState(() => _isReady = true);
    } catch (e) {
      setState(() => _message = "❌ Initialization failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return const SpeedMathApp();
  }
}
