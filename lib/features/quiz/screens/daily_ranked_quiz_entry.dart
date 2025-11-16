// lib/features/quiz/screens/daily_ranked_quiz_entry.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'quiz_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../providers/performance_provider.dart';

class DailyRankedQuizEntry extends StatelessWidget {
  const DailyRankedQuizEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return QuizScreen(
      title: "Daily Ranked Quiz",
      min: 1,
      max: 50,
      count: 10,
      mode: QuizMode.dailyRanked,
      timeLimitSeconds: 180,

      /// 🚀 MAIN PART: Called automatically when quiz is finished
      onFinish: (result) async {
        // ⚠️ The QuizScreen already uploads:
        // - score
        // - streak
        // - attempt flag
        // - daily leaderboard entry
        // So we do NOT upload again here.

        // 🔄 Wait for Firebase write to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // 🔄 Reload streak + today's attempt + all scores
        if (context.mounted) {
          await context.read<PerformanceProvider>().reloadAll();
        }

        // ⬅️ Go directly to HomeScreen AND refresh UI
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      },
    );
  }
}
