// lib/screens/quiz/quiz_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/practice_log_provider.dart';
import '../../utils/question_generator.dart';
import '../../theme/app_theme.dart';
// sub-widgets
import 'quiz_keyboard.dart';
import 'quiz_options.dart';
import 'quiz_status_bar.dart';
import 'quiz_feedback.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String title;
  final int min;
  final int max;
  final int count;

  const QuizScreen({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.count,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

enum KeyboardLayout { normal123, reversed789 }

enum InputMode { keyboard, options }

class _QuizScreenState extends State<QuizScreen> {
  static const _kAutoSubmitKey = 'auto_submit';
  static const _kLayoutKey = 'keyboard_layout';
  static const _kInputModeKey = 'input_mode';

  List<Question> questions = [];
  final Map<int, String> userAnswers = {};

  List<String> currentOptions = [];
  bool optionsReady = false;

  bool autoSubmit = true;
  KeyboardLayout layout = KeyboardLayout.normal123;
  InputMode inputMode = InputMode.keyboard;

  int currentIndex = 0;
  String typedAnswer = '';
  int correctCount = 0;
  int incorrectCount = 0;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  String _timerText = '00:00';

  bool showFeedbackCorrect = false;
  bool showFeedbackIncorrect = false;

  SharedPreferences? _prefs;

  // theme colors
  late Color primary;
  late Color bgColor;
  late Color cardColor;
  late Color textColor;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _generateQuestions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentOptions = _buildOptionsForCurrent();
        optionsReady = true;
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

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final ms = _stopwatch.elapsedMilliseconds;
      final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
      setState(() => _timerText = '$minutes:$seconds');
    });
  }

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

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'BACK' && typedAnswer.isNotEmpty) {
        typedAnswer = typedAnswer.substring(0, typedAnswer.length - 1);
      } else if (value != 'BACK') {
        typedAnswer += value;
      }
    });
    if (inputMode == InputMode.keyboard) _maybeAutoSubmit();
  }

  void _maybeAutoSubmit() {
    if (!autoSubmit) return;
    final curr = questions[currentIndex];
    final expected = curr.correctAnswer.trim();
    if (typedAnswer.trim() == expected) return _submitCurrent();

    if (typedAnswer.length >= expected.length &&
        int.tryParse(typedAnswer) != null) {
      return _submitCurrent();
    }

    final typedDouble = double.tryParse(typedAnswer);
    final expectedDouble = double.tryParse(expected);
    if (typedDouble != null &&
        expectedDouble != null &&
        (typedDouble - expectedDouble).abs() < 1e-6) {
      _submitCurrent();
    }
  }

  bool _isCorrect(Question q, String given) {
    final expected = q.correctAnswer.trim();
    final g = given.trim();
    if (g == expected) return true;
    final gi = int.tryParse(g), ei = int.tryParse(expected);
    if (gi != null && ei != null && gi == ei) return true;
    final gd = double.tryParse(g), ed = double.tryParse(expected);
    return gd != null && ed != null && (gd - ed).abs() < 1e-6;
  }

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
      await _finishQuiz(); // ✅ wait for navigation
      return;
    }
    setState(() {
      currentIndex++;
      typedAnswer = '';
      currentOptions = _buildOptionsForCurrent();
      optionsReady = true;
    });
  }

  Future<void> _finishQuiz() async {
    _stopwatch.stop();
    _ticker?.cancel();

    try {
      final logProvider = Provider.of<PracticeLogProvider>(
        context,
        listen: false,
      );
      await logProvider.addSession(
        topic: widget.title,
        score: correctCount,
        total: questions.length,
        timeSpentSeconds: _stopwatch.elapsed.inSeconds,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to log session: $e');
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            title: widget.title,
            correct: correctCount,
            incorrect: incorrectCount,
            total: questions.length,
            time: _timerText,
            questions: questions,
            userAnswers: Map<int, String>.from(userAnswers),
          ),
        ),
      );
    }
  }

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

  List<String> _buildOptionsForCurrent() {
    if (questions.isEmpty) return [];
    final q = questions[currentIndex];
    final correct = q.correctAnswer;
    final rnd = Random();
    final Set<String> opts = {correct};
    int attempts = 0;

    while (opts.length < 4 && attempts < 30) {
      attempts++;
      final cd = double.tryParse(correct);
      if (cd != null) {
        final offset = rnd.nextInt(9) - 4;
        final candidate = (cd + offset).toStringAsFixed((cd % 1 == 0) ? 0 : 2);
        opts.add(candidate);
      } else {
        opts.add(correct + (rnd.nextBool() ? '' : ' '));
      }
    }

    final list = opts.toList()..shuffle();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    primary = AppTheme.adaptiveAccent(context);
    bgColor = Theme.of(context).scaffoldBackgroundColor;
    cardColor = AppTheme.adaptiveCard(context);
    textColor = AppTheme.adaptiveText(context);

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title), backgroundColor: primary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final q = questions[currentIndex];
    final questionText = '${q.expression.replaceAll('= ?', '')} = ';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _toggleAutoSubmit,
            icon: Icon(
              autoSubmit ? Icons.flash_on : Icons.flash_off,
              color: autoSubmit ? Colors.yellowAccent : Colors.white,
            ),
            tooltip: "Auto Submit",
          ),
          IconButton(
            onPressed: _cycleLayout,
            icon: Icon(
              layout == KeyboardLayout.normal123
                  ? Icons.format_list_numbered
                  : Icons.format_list_numbered_rtl,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _toggleInputMode,
            icon: Icon(
              inputMode == InputMode.keyboard
                  ? Icons.keyboard
                  : Icons.grid_view_rounded,
              color: Colors.white,
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
                          text: typedAnswer.isEmpty ? '?' : typedAnswer,
                          style: TextStyle(
                            color: typedAnswer.isEmpty
                                ? primary
                                : Colors.greenAccent.shade400,
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
                  : optionsReady
                  ? QuizOptions(
                      options: currentOptions,
                      primary: primary,
                      onSelect: (opt) {
                        setState(() => typedAnswer = opt);
                        _submitCurrent();
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
