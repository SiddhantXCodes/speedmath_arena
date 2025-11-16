import 'package:flutter/material.dart';
import 'usecase/save_quiz_result.dart';
import 'screens/quiz_screen.dart';

class QuizProvider extends ChangeNotifier {
  final SaveQuizResult saveQuizResult;

  QuizProvider(this.saveQuizResult);

  /// Save results (to Firebase / Hive via usecase)
  Future<void> saveResult({
    required QuizMode mode,
    required int score,
    required int timeTakenSeconds,
  }) async {
    await saveQuizResult.execute(
      mode: mode,
      score: score,
      timeTakenSeconds: timeTakenSeconds,
    );
  }
}
