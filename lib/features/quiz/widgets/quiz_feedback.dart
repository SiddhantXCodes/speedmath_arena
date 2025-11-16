//lib/features/quiz/widgets/quiz_feedback.dart
import 'package:flutter/material.dart';

class QuizFeedbackIcon extends StatelessWidget {
  final bool correct;
  const QuizFeedbackIcon({super.key, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Icon(
      correct ? Icons.check_circle : Icons.cancel,
      color: correct ? Colors.green : Colors.red,
      size: 36,
    );
  }
}
