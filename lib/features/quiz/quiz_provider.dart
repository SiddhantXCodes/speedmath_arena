//lib/features/quiz/quiz_provider.dart
import 'package:flutter/material.dart';
import 'usecase/save_quiz_result.dart';
import 'usecase/generate_questions.dart';
import 'screens/quiz_screen.dart';

class QuizProvider extends ChangeNotifier {
  final SaveQuizResult saveQuizResult;

  List<Question> questions = [];
  int currentIndex = 0;

  QuizProvider(this.saveQuizResult);

  /// Load quiz based on topic and range
  void loadQuiz(String topic, int min, int max, int count) {
    questions = QuestionGenerator.generate(topic, min, max, count);
    currentIndex = 0;
    notifyListeners();
  }

  /// Save results (to Firebase / Hive via usecase)
  Future<void> saveResult({
    required QuizMode mode,
    required Map<String, dynamic> result,
    required String? userId,
  }) async {
    await saveQuizResult.execute(mode: mode, result: result, userId: userId);
  }
}
