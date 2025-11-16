// lib/features/quiz/screens/practice_quiz_entry.dart

import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import '../../home/screens/home_screen.dart';

class PracticeQuizEntry extends StatelessWidget {
  const PracticeQuizEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately start the practice quiz (popup is shown earlier)
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            title: "Practice Quiz",
            min: 1,
            max: 50,
            count: 10,
            mode: QuizMode.practice,
            timeLimitSeconds: 150,
          ),
        ),
      );
    });

    return const SizedBox.shrink();
  }
}
