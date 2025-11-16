// lib/features/quiz/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../usecase/generate_questions.dart';
import 'leaderboard_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../practice/screens/attempts_history_screen.dart';
import 'quiz_screen.dart';
import '../../../providers/performance_provider.dart';

class ResultScreen extends StatelessWidget {
  final String title;
  final int total;
  final int score;
  final int correct;
  final int incorrect;
  final int timeTakenSeconds;
  final Map<int, String> userAnswers;
  final List<Question> questions;
  final QuizMode mode;

  const ResultScreen({
    super.key,
    required this.title,
    required this.total,
    required this.score,
    required this.correct,
    required this.incorrect,
    required this.timeTakenSeconds,
    required this.userAnswers,
    required this.questions,
    this.mode = QuizMode.practice,
  });

  bool get isRanked => mode == QuizMode.dailyRanked;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final theme = Theme.of(context);

    // ⭐ For ranked → ONLY refresh from Firebase (no local streak update)
    if (isRanked) {
      Future.microtask(() {
        final perf = Provider.of<PerformanceProvider>(context, listen: false);
        perf.reloadAll(); // Firebase updates streak & today's status
      });
    }

    // Format timer
    final mins = (timeTakenSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (timeTakenSeconds % 60).toString().padLeft(2, '0');

    // Data used by Full Review screen
    final attemptData = {
      'topic': title,
      'category': isRanked ? 'Ranked' : 'Practice',
      'date': DateTime.now(),
      'correct': correct,
      'incorrect': incorrect,
      'total': total,
      'score': score,
      'timeSpentSeconds': timeTakenSeconds,
      'questions': questions,
      'userAnswers': userAnswers,
    };

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(isRanked ? "Ranked Result" : "Quiz Result"),
          backgroundColor: accent,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🏆 Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: isRanked ? Colors.amber : accent,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your Score",
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "$score",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Correct: $correct | Incorrect: $incorrect",
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Time Taken: $mins:$secs",
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔘 Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_rounded, color: Colors.white),
                      label: const Text(
                        "Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  if (isRanked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.leaderboard_rounded),
                        label: const Text(
                          "Leaderboard",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: accent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // 🧠 Full Review Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AttemptReviewScreen(attempt: attemptData),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Full Review",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(
                height: 30,
                thickness: 1,
                color: textColor.withOpacity(0.2),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Question Review",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 📄 List of Q/A
              Expanded(
                child: ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final userAns = userAnswers[index];
                    final correctAns = q.correctAnswer.trim();
                    final isCorrect =
                        userAns != null && userAns.trim() == correctAns;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.08)
                            : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.4)
                              : Colors.red.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${q.expression}",
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Your answer: ${userAns ?? '-'}",
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Correct answer: $correctAns",
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
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
