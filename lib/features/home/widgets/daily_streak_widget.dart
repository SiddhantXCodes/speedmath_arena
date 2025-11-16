import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../providers/performance_provider.dart';
import '../../quiz/screens/daily_ranked_quiz_entry.dart';
import '../../quiz/quiz_repository.dart';

class DailyStreakWidget extends StatefulWidget {
  const DailyStreakWidget({super.key});

  @override
  State<DailyStreakWidget> createState() => _DailyStreakWidgetState();
}

class _DailyStreakWidgetState extends State<DailyStreakWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;

  static const streakGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// PURE ONLINE LOGIC
  /// - check from Firebase (repo.hasPlayedToday)
  /// - open quiz
  /// - reload streak from Firebase
  Future<void> _handleStreakTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final perf = context.read<PerformanceProvider>();
    final repo = QuizRepository();

    // 🔄 Always fetch REAL status from Firebase
    final hasPlayedToday = await repo.hasPlayedToday();

    if (!hasPlayedToday) {
      // Open Ranked Quiz
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyRankedQuizEntry()),
      );

      // Refresh streak + leaderboard + ranks
      await perf.reloadAll();
    } else {
      // Already played
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔥 You’ve already completed today's ranked quiz!"),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<PerformanceProvider>().currentStreak;
    final textColor = AppTheme.adaptiveText(context);

    return GestureDetector(
      onTap: _handleStreakTap,
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseController,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => streakGradient.createShader(bounds),
              child: const Icon(Icons.local_fire_department_rounded, size: 26),
            ),
          ),

          const SizedBox(width: 4),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              "$streak",
              key: ValueKey<int>(streak),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: streak > 0
                    ? const Color(0xFFFF5722)
                    : textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
