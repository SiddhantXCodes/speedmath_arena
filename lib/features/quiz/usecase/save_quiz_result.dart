//lib/features/quiz/usecase/save_quiz_result.dart
import '../quiz_repository.dart';
import '../../../models/quiz_session_model.dart';
import '../screens/quiz_screen.dart';

class SaveQuizResult {
  final QuizRepository repo;
  SaveQuizResult(this.repo);

  Future<void> execute({
    required QuizMode mode,
    required Map<String, dynamic> result,
    required String? userId,
  }) async {
    if (mode == QuizMode.dailyRanked && userId != null) {
      final session = QuizSessionModel(
        topic: result['topic'] ?? 'Daily Quiz',
        category: result['category'] ?? 'Ranked',
        correct: result['correct'] ?? 0,
        incorrect: result['incorrect'] ?? 0,
        score: result['score'] ?? result['correct'] ?? 0,
        total: result['total'] ?? 10,
        avgTime: (result['avgTime'] ?? 0).toDouble(),
        timeSpentSeconds: result['timeSpentSeconds'] ?? 0,
        questions: List<Map<String, dynamic>>.from(result['questions'] ?? []),
        userAnswers: Map<int, String>.from(result['userAnswers'] ?? {}),
        difficulty: result['difficulty'] ?? 'normal',
      );

      await repo.saveRankedResult(session); // ✅ pass whole model
    } else {
      await repo.saveOfflineResult(result); // ✅ for offline
    }
  }
}
