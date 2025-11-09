import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/practice_log_provider.dart';
import '../../utils/question_generator.dart';
import '../../theme/app_theme.dart';
import '../quiz/quiz_keyboard.dart';
import '../quiz/quiz_options.dart';
import '../quiz/quiz_status_bar.dart';
import '../quiz/quiz_feedback.dart';
import '../quiz/quiz_result_screen.dart';

enum KeyboardLayout { normal123, reversed789 }

enum InputMode { keyboard, options }

class MixedQuizScreen extends StatefulWidget {
  final List<String> topics;
  final int questionCount;
  final bool useTimer;
  final int timerSeconds;

  const MixedQuizScreen({
    super.key,
    required this.topics,
    required this.questionCount,
    required this.useTimer,
    required this.timerSeconds,
  });

  @override
  State<MixedQuizScreen> createState() => _MixedQuizScreenState();
}

class _MixedQuizScreenState extends State<MixedQuizScreen> {
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
  bool quizEnded = false;

  // Theme colors
  late Color primary;
  late Color bgColor;
  late Color cardColor;
  late Color textColor;
  late Color onPrimary;

  @override
  void initState() {
    super.initState();
    _generateMixedQuestions();
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

  void _generateMixedQuestions() {
    final perTopic = (widget.questionCount / widget.topics.length).ceil();
    for (final topic in widget.topics) {
      questions.addAll(QuestionGenerator.generate(topic, 1, 50, perTopic));
    }
    questions.shuffle(Random());
  }

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final ms = _stopwatch.elapsedMilliseconds;
      final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
      setState(() => _timerText = '$minutes:$seconds');

      if (widget.useTimer &&
          _stopwatch.elapsed.inSeconds >= widget.timerSeconds) {
        _finishQuiz();
      }
    });
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

    Future.delayed(const Duration(milliseconds: 300), () {
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
      await _finishQuiz();
      return;
    }
    setState(() {
      currentIndex++;
      typedAnswer = '';
      currentOptions = _buildOptionsForCurrent();
      optionsReady = true;
    });
  }

  // ✅ UPDATED to include full question and answer data
  Future<void> _finishQuiz() async {
    if (quizEnded) return;
    quizEnded = true;
    _stopwatch.stop();
    _ticker?.cancel();

    final total = questions.length;
    final score = (correctCount * 4) - incorrectCount;
    final avgTime = total > 0 ? _stopwatch.elapsed.inSeconds / total : 0.0;

    // 🔹 Convert to simple map list for Hive
    final questionMaps = questions
        .map(
          (q) => {'expression': q.expression, 'correctAnswer': q.correctAnswer},
        )
        .toList();

    try {
      final logProvider = Provider.of<PracticeLogProvider>(
        context,
        listen: false,
      );

      await logProvider.addSession(
        topic: widget.topics.join(", "),
        category: 'Mixed Practice',
        correct: correctCount,
        incorrect: incorrectCount,
        score: score,
        total: total,
        avgTime: avgTime,
        timeSpentSeconds: _stopwatch.elapsed.inSeconds,
        questions: questionMaps, // ✅ Added
        userAnswers: Map<int, String>.from(userAnswers), // ✅ Added
      );
    } catch (e) {
      debugPrint("⚠️ Failed to log mixed session: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          title: 'Mixed Practice',
          correct: correctCount,
          incorrect: incorrectCount,
          total: total,
          time: _timerText,
          questions: questions,
          userAnswers: Map<int, String>.from(userAnswers),
        ),
      ),
    );
  }

  void _toggleAutoSubmit() => setState(() => autoSubmit = !autoSubmit);
  void _cycleLayout() => setState(() {
    layout = layout == KeyboardLayout.normal123
        ? KeyboardLayout.reversed789
        : KeyboardLayout.normal123;
  });
  void _toggleInputMode() => setState(() {
    inputMode = inputMode == InputMode.keyboard
        ? InputMode.options
        : InputMode.keyboard;
  });

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
    onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mixed Practice'),
          backgroundColor: primary,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(primary),
          ),
        ),
      );
    }

    final q = questions[currentIndex];
    final questionText = '${q.expression.replaceAll('= ?', '')} = ';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixed Practice'),
        backgroundColor: primary,
        actions: [
          IconButton(
            onPressed: _toggleAutoSubmit,
            icon: Icon(
              autoSubmit ? Icons.flash_on : Icons.flash_off,
              color: autoSubmit ? AppTheme.warningColor : colorScheme.onPrimary,
            ),
          ),
          IconButton(
            onPressed: _cycleLayout,
            icon: Icon(
              layout == KeyboardLayout.normal123
                  ? Icons.format_list_numbered
                  : Icons.format_list_numbered_rtl,
              color: colorScheme.onPrimary,
            ),
          ),
          IconButton(
            onPressed: _toggleInputMode,
            icon: Icon(
              inputMode == InputMode.keyboard
                  ? Icons.keyboard
                  : Icons.grid_view_rounded,
              color: colorScheme.onPrimary,
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
                  : optionsReady
                  ? QuizOptions(
                      options: currentOptions,
                      primary: primary,
                      onSelect: (opt) {
                        setState(() => typedAnswer = opt);
                        _submitCurrent();
                      },
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
