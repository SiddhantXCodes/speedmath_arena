import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'quiz_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../providers/performance_provider.dart';

class DailyRankedQuizEntry extends StatelessWidget {
  const DailyRankedQuizEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // Start quiz immediately WITHOUT showing popup again
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            title: "Daily Ranked Quiz",
            min: 1,
            max: 50,
            count: 10,
            mode: QuizMode.dailyRanked,
            timeLimitSeconds: 150,

            onFinish: (result) async {
              await Future.delayed(const Duration(milliseconds: 300));

              if (context.mounted) {
                await context.read<PerformanceProvider>().reloadAll();
              }

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
      );
    });

    return const SizedBox.shrink();
  }
}
