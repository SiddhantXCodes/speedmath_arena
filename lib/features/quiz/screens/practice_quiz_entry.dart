//lib/features/quiz/screens/practice_quiz_entry.dart
import 'package:flutter/material.dart';
import 'quiz_screen.dart';

/// 🧮 Offline Practice Zone Entry
/// Uses the same logic, UI, and structure as the Daily Ranked Quiz,
/// but runs fully offline (no leaderboard or Firebase sync).
class PracticeQuizEntry extends StatelessWidget {
  const PracticeQuizEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return QuizScreen(
      title: "Practice Quiz",
      min: 1, // same as ranked quiz range
      max: 50,
      count: 10, // number of questions
      mode: QuizMode.practice, // 👈 key difference (offline only)
      timeLimitSeconds: 0, // no time limit for practice
    );
  }
}
