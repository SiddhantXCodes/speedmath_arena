// lib/screens/daily_ranked_quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/question_generator.dart';
import '../providers/performance_provider.dart';
import '../providers/practice_log_provider.dart';
import '../theme/app_theme.dart';
import '../screens/daily_ranked_quiz_result.dart';
import '../screens/leaderboard_screen.dart';
import 'quiz/quiz_keyboard.dart';

class DailyRankedQuizScreen extends StatefulWidget {
  const DailyRankedQuizScreen({super.key});

  @override
  State<DailyRankedQuizScreen> createState() => _DailyRankedQuizScreenState();
}

class _DailyRankedQuizScreenState extends State<DailyRankedQuizScreen>
    with SingleTickerProviderStateMixin {
  List<Question> questions = [];
  int currentIndex = 0;
  String typedAnswer = '';
  int score = 0;
  int correct = 0;
  int incorrect = 0;
  Timer? _timer;
  int remainingSeconds = 180;
  bool quizEnded = false;
  bool _alreadyAttempted = false;

  final Map<int, String> userAnswers = {};
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_progressController);
    _checkIfAttempted();
  }

  /// 🔍 Check if user already played today's quiz
  Future<void> _checkIfAttempted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _generateLocalQuestions();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('daily_leaderboard')
          .doc(_todayKey)
          .collection('entries')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        setState(() => _alreadyAttempted = true);
      } else {
        _generateLocalQuestions();
      }
    } catch (e) {
      debugPrint("⚠️ Firestore check failed: $e");
      _generateLocalQuestions(); // fallback to local
    }
  }

  void _generateLocalQuestions() {
    questions = List.generate(
      5,
      (i) => Question(expression: "5 + $i = ?", correctAnswer: "${5 + i}"),
    );
    _animateProgress();
    _startTimer();
    setState(() {});
  }

  void _animateProgress() {
    if (questions.isEmpty) return;
    final nextValue = (currentIndex + 1) / questions.length;
    _progressAnimation =
        Tween<double>(begin: _progressAnimation.value, end: nextValue).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );
    _progressController
      ..reset()
      ..forward();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        _finishQuiz();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  bool _isCorrect(Question q, String ans) =>
      ans.trim() == q.correctAnswer.trim();

  void _onKeyTap(String val) {
    if (quizEnded) return;
    setState(() {
      if (val == 'BACK' && typedAnswer.isNotEmpty) {
        typedAnswer = typedAnswer.substring(0, typedAnswer.length - 1);
      } else if (val != 'BACK') {
        typedAnswer += val;
      }
    });
  }

  void _onSubmit() {
    if (typedAnswer.isEmpty) return;
    final curr = questions[currentIndex];
    final given = typedAnswer.trim();
    userAnswers[currentIndex] = given;

    final isRight = _isCorrect(curr, given);
    if (isRight) {
      correct++;
      score += 4;
    } else {
      incorrect++;
      score -= 1;
    }

    setState(() {
      typedAnswer = '';
      if (currentIndex + 1 >= questions.length) {
        _finishQuiz();
      } else {
        currentIndex++;
        _animateProgress();
      }
    });
  }

  Future<void> _finishQuiz() async {
    if (quizEnded) return;
    quizEnded = true;
    _timer?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final safeScore = score < 0 ? 0 : score; // ✅ never negative

    await prefs.setInt('daily_score_${_todayKey}', safeScore);
    await prefs.setInt('daily_correct_${_todayKey}', correct);
    await prefs.setInt('daily_incorrect_${_todayKey}', incorrect);

    // 🔹 Online sync
    if (user != null) {
      try {
        final uid = user.uid;
        final userName = user.displayName ?? "Player";
        final photoUrl = user.photoURL ?? "";

        final dailyRef = FirebaseFirestore.instance
            .collection('daily_leaderboard')
            .doc(_todayKey)
            .collection('entries')
            .doc(uid);

        final allTimeRef = FirebaseFirestore.instance
            .collection('alltime_leaderboard')
            .doc(uid);

        // ✅ Write to daily leaderboard
        await dailyRef.set({
          'uid': uid,
          'name': userName,
          'photoUrl': photoUrl,
          'score': safeScore,
          'correct': correct,
          'incorrect': incorrect,
          'timeTaken': 180 - remainingSeconds,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ✅ Write or update all-time leaderboard
        final allSnap = await allTimeRef.get();
        if (allSnap.exists) {
          final prev = allSnap.data()!;
          await allTimeRef.update({
            'name': userName,
            'photoUrl': photoUrl,
            'totalScore': (prev['totalScore'] ?? 0) + safeScore,
            'quizzesTaken': (prev['quizzesTaken'] ?? 0) + 1,
            'bestDailyScore': safeScore > (prev['bestDailyScore'] ?? 0)
                ? safeScore
                : (prev['bestDailyScore'] ?? 0),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          await allTimeRef.set({
            'uid': uid,
            'name': userName,
            'photoUrl': photoUrl,
            'totalScore': safeScore,
            'quizzesTaken': 1,
            'bestDailyScore': safeScore,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("❌ Firestore write failed: $e");
      }
    }

    // 🔹 Offline sync (Hive Providers)
    try {
      final performance = Provider.of<PerformanceProvider>(
        context,
        listen: false,
      );
      await performance.addTodayScore(safeScore);

      final logProvider = Provider.of<PracticeLogProvider>(
        context,
        listen: false,
      );

      // ✅ Add ranked session to offline logs
      final totalTime = 180 - remainingSeconds;
      final avgTime = (questions.isNotEmpty)
          ? (totalTime / questions.length)
          : 0.0;

      await logProvider.addSession(
        topic: 'Daily Ranked Quiz',
        category: 'Ranked',
        correct: correct,
        incorrect: incorrect,
        score: safeScore,
        total: questions.length,
        avgTime: avgTime,
        timeSpentSeconds: totalTime,
      );
    } catch (e) {
      debugPrint("⚠️ Local provider failed: $e");
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DailyRankedResultScreen(
          total: questions.length,
          score: safeScore,
          correct: correct,
          incorrect: incorrect,
          answers: userAnswers,
          questions: questions,
          timeTaken: 180 - remainingSeconds,
        ),
      ),
    );
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final theme = Theme.of(context);

    if (_alreadyAttempted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Daily Ranked Quiz")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, size: 60, color: accent),
              const SizedBox(height: 12),
              Text(
                "You've already played today's quiz!",
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                ),
                icon: const Icon(Icons.leaderboard_rounded),
                label: const Text("View Leaderboard"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = questions[currentIndex];
    final time = _formatTime(remainingSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Ranked Quiz"),
        backgroundColor: accent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        color: accent,
                        backgroundColor: theme.dividerColor.withOpacity(0.2),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${currentIndex + 1}/${questions.length}",
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Score: $score",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "⏱ $time",
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: q.expression.replaceAll('= ?', '= ')),
                      TextSpan(
                        text: typedAnswer.isEmpty ? '?' : typedAnswer,
                        style: TextStyle(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            QuizKeyboard(
              autoSubmit: false,
              isDark: theme.brightness == Brightness.dark,
              primary: accent,
              onKeyTap: _onKeyTap,
              onSubmit: _onSubmit,
              isReversed: false,
            ),
          ],
        ),
      ),
    );
  }
}
