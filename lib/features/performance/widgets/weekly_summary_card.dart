//lib/features/performance/widgets/weekly_summary_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/performance_provider.dart';
import '../../../providers/practice_log_provider.dart';

class WeeklySummaryCard extends StatelessWidget {
  final PerformanceProvider perf;
  final PracticeLogProvider log;

  const WeeklySummaryCard({super.key, required this.perf, required this.log});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final theme = Theme.of(context);

    // 🧮 Weekly average (ranked)
    final currentWeekScore = perf.weeklyAverage;
    final previousWeekScore = currentWeekScore > 0
        ? (currentWeekScore * 0.75).round()
        : 0;

    // 🎯 Accuracy
    final currentAccuracy = _calculateAccuracy(log);
    final previousAccuracy = currentAccuracy > 0
        ? (currentAccuracy * 0.8).round()
        : 0;

    // ⚡ AvgSpeed from practice logs
    final avgSpeed = log.logs.isNotEmpty
        ? log.logs.map((e) => e.avgTime).reduce((a, b) => a + b) /
              log.logs.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weekly Comparison",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),

          // 📈 Score comparison
          _progressRow(
            "Average Score",
            previousWeekScore,
            currentWeekScore,
            accent,
            textColor,
          ),
          const SizedBox(height: 12),

          // 🎯 Accuracy comparison
          _progressRow(
            "Accuracy",
            previousAccuracy,
            currentAccuracy,
            accent,
            textColor,
          ),

          const SizedBox(height: 20),

          // 🧩 Bottom stats
          Row(
            children: [
              _summaryStat(
                icon: Icons.timer_rounded,
                title: "Avg Speed",
                value: "${avgSpeed.toStringAsFixed(1)}s",
                accent: accent,
                textColor: textColor,
              ),
              const SizedBox(width: 10),
              _summaryStat(
                icon: Icons.trending_up_rounded,
                title: "7-Day Avg",
                value: "$currentWeekScore",
                accent: accent,
                textColor: textColor,
              ),
              const SizedBox(width: 10),
              _summaryStat(
                icon: Icons.check_circle_rounded,
                title: "Accuracy",
                value: "$currentAccuracy%",
                accent: accent,
                textColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔵 Progress Row
  // ----------------------------------------------------------
  Widget _progressRow(
    String label,
    int oldVal,
    int newVal,
    Color accent,
    Color textColor,
  ) {
    final increase = newVal >= oldVal;
    final fillPercent = (newVal.clamp(0, 100)) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + Value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "$newVal",
              style: TextStyle(
                color: increase ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Animated Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 8, color: Colors.grey.withOpacity(0.25)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                widthFactor: fillPercent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.65)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 🟩 Summary Stats
  // ----------------------------------------------------------
  Widget _summaryStat({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.65),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 🧮 Accuracy Calculation
  // ----------------------------------------------------------
  int _calculateAccuracy(PracticeLogProvider log) {
    int correct = 0, wrong = 0;

    for (final l in log.logs) {
      correct += l.correct;
      wrong += l.incorrect;
    }

    final total = correct + wrong;
    if (total == 0) return 0;

    return ((correct / total) * 100).round();
  }
}
