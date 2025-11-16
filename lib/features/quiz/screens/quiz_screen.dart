//lib/features/quiz/screens/quiz_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../usecase/generate_questions.dart';
import '../../../theme/app_theme.dart';

// 🧱 Repository + Models
import '../quiz_repository.dart';
import '../../../models/quiz_session_model.dart';

// 📊 Performance (Ranked Score + Streak)
import '../../../providers/performance_provider.dart';

// 🧩 Widgets
import '../widgets/quiz_keyboard.dart';
import '../widgets/quiz_options.dart';
import '../widgets/quiz_status_bar.dart';
import '../widgets/quiz_feedback.dart';
import 'result_screen.dart';

enum KeyboardLayout { normal123, reversed789 }

enum InputMode { keyboard, options }

enum QuizMode { practice, dailyRanked, timedRanked, challenge }

class QuizScreen extends StatefulWidget {
  final String title;
  final int min;
  final int max;
  final int count;
  final QuizMode mode;
  final int timeLimitSeconds;
  final Future<void> Function(Map<String, dynamic>)? onFinish;

  const QuizScreen({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.count,
    this.mode = QuizMode.practice,
    this.timeLimitSeconds = 0,
    this.onFinish,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _kAutoSubmitKey = 'auto_submit';
  static const _kLayoutKey = 'keyboard_layout';
  static const _kInputModeKey = 'input_mode';

  // Quiz State
  List<Question> questions = [];
  final Map<int, String> userAnswers = {};
  List<String> currentOptions = [];

  bool autoSubmit = true;
  KeyboardLayout layout = KeyboardLayout.normal123;
  InputMode inputMode = InputMode.keyboard;

  int currentIndex = 0;
  String typedAnswer = '';
  int correctCount = 0;
  int incorrectCount = 0;

  // Timer
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  String _timerText = "00:00";

  bool showFeedbackCorrect = false;
  bool showFeedbackIncorrect = false;

  SharedPreferences? _prefs;

  // Colors
  late Color primary;
  late Color bgColor;
  late Color cardColor;
  late Color textColor;
  late Color onPrimary;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _generateQuestions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentOptions = _buildOptionsForCurrent();
      });
    });

    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // LOAD / SAVE SETTINGS
  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      autoSubmit = _prefs?.getBool(_kAutoSubmitKey) ?? true;
      layout = KeyboardLayout.values[_prefs?.getInt(_kLayoutKey) ?? 0];
      inputMode = InputMode.values[_prefs?.getInt(_kInputModeKey) ?? 0];
    });
  }

  Future<void> _savePrefs() async {
    await _prefs?.setBool(_kAutoSubmitKey, autoSubmit);
    await _prefs?.setInt(_kLayoutKey, layout.index);
    await _prefs?.setInt(_kInputModeKey, inputMode.index);
  }

  // TIMER
  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;

      final ms = _stopwatch.elapsedMilliseconds;
      final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');

      setState(() => _timerText = "$minutes:$seconds");

      if (widget.timeLimitSeconds > 0 &&
          _stopwatch.elapsed.inSeconds >= widget.timeLimitSeconds) {
        _finishQuiz();
      }
    });
  }

  // GENERATE QUESTIONS
  void _generateQuestions() {
    questions = QuestionGenerator.generate(
      widget.title,
      widget.min,
      widget.max,
      widget.count,
    );
    currentIndex = 0;
    typedAnswer = '';
    correctCount = 0;
    incorrectCount = 0;
    userAnswers.clear();
  }

  // INPUT
  void _onKeyTap(String value) {
    setState(() {
      if (value == "BACK" && typedAnswer.isNotEmpty) {
        typedAnswer = typedAnswer.substring(0, typedAnswer.length - 1);
      } else if (value != "BACK") {
        typedAnswer += value;
      }
    });

    if (inputMode == InputMode.keyboard) _maybeAutoSubmit();
  }

  void _maybeAutoSubmit() {
    if (!autoSubmit) return;

    final curr = questions[currentIndex];
    final expected = curr.correctAnswer.trim();

    // If exact match → submit
    if (typedAnswer.trim() == expected) return _submitCurrent();

    // If same length → assume final answer
    if (typedAnswer.length >= expected.length &&
        int.tryParse(typedAnswer) != null) {
      return _submitCurrent();
    }

    // Float comparison
    final d1 = double.tryParse(typedAnswer);
    final d2 = double.tryParse(expected);
    if (d1 != null && d2 != null && (d1 - d2).abs() < 1e-6) {
      return _submitCurrent();
    }
  }

  bool _isCorrect(Question q, String given) {
    final e = q.correctAnswer.trim();
    final g = given.trim();

    if (g == e) return true;

    final gi = int.tryParse(g);
    final ei = int.tryParse(e);
    if (gi != null && ei != null && gi == ei) return true;

    final gd = double.tryParse(g);
    final ed = double.tryParse(e);
    return (gd != null && ed != null && (gd - ed).abs() < 1e-6);
  }

  // SUBMIT CURRENT QUESTION
  void _submitCurrent() {
    if (typedAnswer.trim().isEmpty) return;

    final curr = questions[currentIndex];
    final correct = _isCorrect(curr, typedAnswer);

    userAnswers[currentIndex] = typedAnswer;

    setState(() {
      if (correct) {
        correctCount++;
        showFeedbackCorrect = true;
      } else {
        incorrectCount++;
        showFeedbackIncorrect = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        showFeedbackCorrect = false;
        showFeedbackIncorrect = false;
      });
      _nextQuestion();
    });
  }

  Future<void> _nextQuestion() async {
    if (currentIndex + 1 >= questions.length) {
      return _finishQuiz();
    }

    setState(() {
      currentIndex++;
      typedAnswer = '';
      currentOptions = _buildOptionsForCurrent();
    });
  }

  // ⭐⭐⭐ FINISH QUIZ — Firebase ONLY (perfect version)
  Future<void> _finishQuiz() async {
    if (!mounted) return;

    _stopwatch.stop();
    _ticker?.cancel();

    final total = questions.length;
    final avgTime = total > 0 ? _stopwatch.elapsed.inSeconds / total : 0.0;

    final questionMaps = questions
        .map(
          (q) => {'expression': q.expression, 'correctAnswer': q.correctAnswer},
        )
        .toList();

    final session = QuizSessionModel(
      topic: widget.title,
      category: widget.mode.name,
      correct: correctCount,
      incorrect: incorrectCount,
      score: correctCount,
      total: total,
      avgTime: avgTime,
      timeSpentSeconds: _stopwatch.elapsed.inSeconds,
      questions: questionMaps,
      userAnswers: Map<int, String>.from(userAnswers),
      difficulty: 'normal',
    );

    final repo = QuizRepository();

    if (widget.mode == QuizMode.dailyRanked) {
      // 1) Save results → Firebase
      await repo.saveRankedResult(session);

      // 2) Refresh streak + today's attempt from Firebase ONLY
      if (mounted) {
        await context.read<PerformanceProvider>().reloadAll();
      }
    } else {
      // Offline only
      await repo.saveOfflineResult({
        'topic': session.topic,
        'category': session.category,
        'correct': session.correct,
        'incorrect': session.incorrect,
        'score': session.score,
        'total': session.total,
        'avgTime': session.avgTime,
        'timeSpentSeconds': session.timeSpentSeconds,
        'questions': session.questions,
        'userAnswers': session.userAnswers,
      });
    }

    // Optional callback
    if (widget.onFinish != null) {
      await widget.onFinish!({
        "correct": correctCount,
        "incorrect": incorrectCount,
        "total": total,
        "timeText": _timerText,
        "questions": questions,
        "userAnswers": Map<int, String>.from(userAnswers),
        "mode": widget.mode.toString(),
      });
    }

    // Go to result screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            title: widget.title,
            total: total,
            score: correctCount,
            correct: correctCount,
            incorrect: incorrectCount,
            timeTakenSeconds: _stopwatch.elapsed.inSeconds,
            userAnswers: Map<int, String>.from(userAnswers),
            questions: questions,
            mode: widget.mode,
          ),
        ),
      );
    }
  }

  // BACK HANDLER
  Future<bool> _onWillPop() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Exit Quiz?",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Your progress will be lost. Are you sure?",
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppTheme.warningColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text("Exit"),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  // SETTINGS
  void _toggleAutoSubmit() {
    setState(() => autoSubmit = !autoSubmit);
    _savePrefs();
  }

  void _cycleLayout() {
    setState(() {
      layout = layout == KeyboardLayout.normal123
          ? KeyboardLayout.reversed789
          : KeyboardLayout.normal123;
    });
    _savePrefs();
  }

  void _toggleInputMode() {
    setState(() {
      inputMode = inputMode == InputMode.keyboard
          ? InputMode.options
          : InputMode.keyboard;
    });
    _savePrefs();
  }

  // OPTIONS BUILDER
  List<String> _buildOptionsForCurrent() {
    final q = questions[currentIndex];
    final correct = q.correctAnswer;

    final rnd = Random();
    final Set<String> opts = {correct};

    while (opts.length < 4) {
      final cd = double.tryParse(correct);
      if (cd != null) {
        final offset = rnd.nextInt(9) - 4;
        opts.add((cd + offset).toString());
      } else {
        opts.add("${correct}${rnd.nextInt(5)}");
      }
    }

    final list = opts.toList()..shuffle();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    primary = AppTheme.adaptiveAccent(context);
    bgColor = theme.scaffoldBackgroundColor;
    cardColor = AppTheme.adaptiveCard(context);
    textColor = AppTheme.adaptiveText(context);
    onPrimary = theme.colorScheme.onPrimary;

    final q = questions[currentIndex];
    final questionText = "${q.expression.replaceAll('= ?', '')} = ";

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(
              color: onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: onPrimary),
            onPressed: () async {
              final exit = await _onWillPop();
              if (exit && mounted) Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              onPressed: _toggleAutoSubmit,
              icon: Icon(
                autoSubmit ? Icons.flash_on : Icons.flash_off,
                color: autoSubmit ? AppTheme.warningColor : onPrimary,
              ),
            ),
            IconButton(
              onPressed: _cycleLayout,
              icon: Icon(
                layout == KeyboardLayout.normal123
                    ? Icons.format_list_numbered
                    : Icons.format_list_numbered_rtl,
                color: onPrimary,
              ),
            ),
            IconButton(
              onPressed: _toggleInputMode,
              icon: Icon(
                inputMode == InputMode.keyboard
                    ? Icons.keyboard
                    : Icons.grid_view_rounded,
                color: onPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              QuizStatusBar(
                correct: correctCount,
                incorrect: incorrectCount,
                timerText: _timerText,
                current: currentIndex + 1,
                total: questions.length,
                textColor: textColor,
                cardColor: cardColor,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(text: questionText),
                          TextSpan(
                            text: typedAnswer.isEmpty ? "?" : typedAnswer,
                            style: TextStyle(
                              color: typedAnswer.isEmpty
                                  ? primary
                                  : AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (showFeedbackCorrect || showFeedbackIncorrect)
                      Positioned(
                        top: 0,
                        child: QuizFeedbackIcon(correct: showFeedbackCorrect),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: inputMode == InputMode.keyboard
                    ? QuizKeyboard(
                        autoSubmit: autoSubmit,
                        isDark: isDark,
                        primary: primary,
                        onKeyTap: _onKeyTap,
                        onSubmit: _submitCurrent,
                        isReversed: layout == KeyboardLayout.reversed789,
                      )
                    : QuizOptions(
                        options: currentOptions,
                        primary: primary,
                        onSelect: (opt) {
                          setState(() => typedAnswer = opt);
                          _submitCurrent();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
