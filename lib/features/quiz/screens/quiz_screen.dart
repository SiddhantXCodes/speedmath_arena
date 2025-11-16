import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../usecase/generate_questions.dart';
import '../../../theme/app_theme.dart';

// Repository
import '../quiz_repository.dart';

// Performance update (ranked only)
import '../../../providers/performance_provider.dart';

// Widgets
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

  /// When mixed practice, selected topics
  final List<String>? topics;

  final Future<void> Function(Map<String, dynamic>)? onFinish;

  const QuizScreen({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.count,
    this.mode = QuizMode.practice,
    this.timeLimitSeconds = 150,
    this.topics,
    this.onFinish,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _kAutoSubmitKey = 'auto_submit';
  static const _kLayoutKey = 'keyboard_layout';
  static const _kInputModeKey = 'input_mode';

  late Question currentQuestion;
  List<String> currentOptions = [];

  String typedAnswer = '';
  int score = 0;

  late int remainingTime;
  Timer? countdown;

  bool autoSubmit = true;
  KeyboardLayout layout = KeyboardLayout.normal123;
  InputMode inputMode = InputMode.keyboard;

  bool showFeedbackCorrect = false;

  SharedPreferences? _prefs;

  late Color primary;
  late Color bgColor;
  late Color cardColor;
  late Color textColor;
  late Color onPrimary;

  @override
  void initState() {
    super.initState();
    _startTimerCorrectly();
    _loadPrefs();
    _startNewQuiz();
  }

  @override
  void dispose() {
    countdown?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // TIMER
  // ----------------------------------------------------------------------
  void _startTimerCorrectly() {
    if (widget.timeLimitSeconds <= 0) {
      remainingTime = 999999; // unlimited
      return;
    }

    remainingTime = widget.timeLimitSeconds;

    countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (remainingTime <= 1) {
        timer.cancel();
        _finishQuiz();
        return;
      }

      setState(() => remainingTime--);
    });
  }

  // ----------------------------------------------------------------------
  // SETTINGS
  // ----------------------------------------------------------------------
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

  // ----------------------------------------------------------------------
  // TOGGLES (FIXED)
  // ----------------------------------------------------------------------
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

  // ----------------------------------------------------------------------
  // QUESTIONS
  // ----------------------------------------------------------------------
  void _startNewQuiz() {
    currentQuestion = _generateQuestion();
    typedAnswer = '';
    score = 0;
    currentOptions = _buildOptions(currentQuestion);
  }

  Question _generateQuestion() {
    // Mixed practice with topic selection
    if (widget.topics != null && widget.topics!.isNotEmpty) {
      return QuestionGenerator.randomFromTopics(
        widget.topics!,
        widget.min,
        widget.max,
      );
    }

    // Normal practice
    return QuestionGenerator.random(
      topic: widget.title,
      min: widget.min,
      max: widget.max,
    );
  }

  // ----------------------------------------------------------------------
  // INPUT / ANSWERS
  // ----------------------------------------------------------------------
  void _onKeyTap(String value) {
    setState(() {
      if (value == "BACK" && typedAnswer.isNotEmpty) {
        typedAnswer = typedAnswer.substring(0, typedAnswer.length - 1);
      } else if (value != "BACK") {
        typedAnswer += value;
      }
    });

    if (autoSubmit && inputMode == InputMode.keyboard) {
      _trySubmit();
    }
  }

  bool _isCorrect(String v) => v.trim() == currentQuestion.correctAnswer.trim();

  void _trySubmit() {
    if (_isCorrect(typedAnswer)) _submitCorrect();
  }

  void _submitCorrect() {
    setState(() {
      score++;
      showFeedbackCorrect = true;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        showFeedbackCorrect = false;
        typedAnswer = '';
        currentQuestion = _generateQuestion();
        currentOptions = _buildOptions(currentQuestion);
      });
    });
  }

  // ----------------------------------------------------------------------
  // BUILD OPTIONS
  // ----------------------------------------------------------------------
  List<String> _buildOptions(Question q) {
    final correct = q.correctAnswer;
    final rnd = Random();
    final opts = <String>{correct};

    while (opts.length < 4) {
      final cd = double.tryParse(correct);
      if (cd != null) {
        opts.add((cd + (rnd.nextInt(7) - 3)).toString());
      } else {
        opts.add(correct + rnd.nextInt(9).toString());
      }
    }

    final list = opts.toList();
    list.shuffle();
    return list;
  }

  // ----------------------------------------------------------------------
  // FINISH QUIZ (FULLY UPDATED)
  // ----------------------------------------------------------------------
  Future<void> _finishQuiz() async {
    countdown?.cancel();

    final timeSpent = widget.timeLimitSeconds <= 0
        ? 0
        : (widget.timeLimitSeconds - remainingTime);

    final repo = QuizRepository();

    switch (widget.mode) {
      case QuizMode.dailyRanked:
      case QuizMode.timedRanked:
        await repo.saveRankedScore(score, timeSpent);
        if (mounted) {
          await context.read<PerformanceProvider>().reloadAll();
        }
        break;

      case QuizMode.challenge:
        await repo.saveMixedScore(score, timeSpent);
        break;

      case QuizMode.practice:
      default:
        await repo.savePracticeScore(score, timeSpent);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: score,
          timeTakenSeconds: timeSpent,
          mode: widget.mode,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // EXIT HANDLER
  // ----------------------------------------------------------------------
  Future<bool> _onWillPop() async {
    final theme = Theme.of(context);

    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Exit Quiz?",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          "Your progress will be lost. Are you sure?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
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

    return exit ?? false;
  }

  // ----------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    primary = AppTheme.adaptiveAccent(context);
    bgColor = theme.scaffoldBackgroundColor;
    cardColor = AppTheme.adaptiveCard(context);
    textColor = AppTheme.adaptiveText(context);
    onPrimary = theme.colorScheme.onPrimary;

    final questionText =
        "${currentQuestion.expression.replaceAll('= ?', '')} = ";

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
                correct: score,
                incorrect: 0,
                timerText: remainingTime.toString(),
                current: 0,
                total: 0,
                textColor: textColor,
                cardColor: cardColor,
                isDark: theme.brightness == Brightness.dark,
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

                    if (showFeedbackCorrect)
                      const Positioned(
                        top: 0,
                        child: QuizFeedbackIcon(correct: true),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: inputMode == InputMode.keyboard
                    ? QuizKeyboard(
                        autoSubmit: autoSubmit,
                        isDark: theme.brightness == Brightness.dark,
                        primary: primary,
                        onKeyTap: _onKeyTap,
                        onSubmit: () {
                          if (_isCorrect(typedAnswer)) _submitCorrect();
                        },
                        isReversed: layout == KeyboardLayout.reversed789,
                      )
                    : QuizOptions(
                        options: currentOptions,
                        primary: primary,
                        onSelect: (opt) {
                          typedAnswer = opt;
                          _trySubmit();
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
