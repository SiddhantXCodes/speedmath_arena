import '../quiz_repository.dart';
import '../screens/quiz_screen.dart';

class SaveQuizResult {
  final QuizRepository repo;
  SaveQuizResult(this.repo);

  Future<void> execute({
    required QuizMode mode,
    required int score,
    required int timeTakenSeconds,
  }) async {
    if (mode == QuizMode.dailyRanked) {
      // 🔥 Save to Firebase leaderboard
      await repo.saveRankedScore(score, timeTakenSeconds);
    } else {
      // 📘 Save to local Hive storage
      await repo.savePracticeScore(score, timeTakenSeconds);
    }
  }
}
