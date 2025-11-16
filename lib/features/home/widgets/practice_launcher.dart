//lib/features/home/widgets/practice_launcher.dart
import 'package:flutter/material.dart';
import '../../quiz/screens/quiz_screen.dart';

void startPracticeQuiz(
  BuildContext context, {
  required String topic,
  int min = 1,
  int max = 10,
  int count = 10,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QuizScreen(
        title: topic,
        min: min,
        max: max,
        count: count,
        mode: QuizMode.practice,
        timeLimitSeconds: 0,
      ),
    ),
  );
}
