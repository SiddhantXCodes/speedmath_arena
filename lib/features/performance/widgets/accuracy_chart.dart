//lib/features/performance/widgets/accuracy_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/practice_log_provider.dart';

class AccuracyChart extends StatelessWidget {
  final PracticeLogProvider log;
  const AccuracyChart({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    int totalCorrect = 0, totalIncorrect = 0;
    for (final l in log.logs) {
      totalCorrect += l.correct;
      totalIncorrect += l.incorrect;
    }

    final total = totalCorrect + totalIncorrect;
    if (total == 0) {
      return _empty(context, "No practice data yet");
    }

    final accuracy = (totalCorrect / total * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
            "Accuracy Overview",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                    color: accent,
                    value: totalCorrect.toDouble(),
                    title: "Correct",
                    radius: 46,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.redAccent,
                    value: totalIncorrect.toDouble(),
                    title: "Wrong",
                    radius: 42,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Overall Accuracy: $accuracy%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String msg) {
    final textColor = AppTheme.adaptiveText(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(msg, style: TextStyle(color: textColor)),
      ),
    );
  }
}
