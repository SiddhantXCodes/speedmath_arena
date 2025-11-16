//lib/features/performance/widgets/trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/performance_provider.dart';

class TrendChart extends StatelessWidget {
  final PerformanceProvider perf;
  const TrendChart({super.key, required this.perf});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    final data = perf.dailyScores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return _emptyChart(context, "No ranked quiz data for the last 7 days");
    }

    return _chartContainer(
      context,
      "Ranked Quiz Progress",
      SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: accent,
                spots: data
                    .take(7)
                    .map(
                      (e) => FlSpot(
                        e.key.day.toDouble(),
                        e.value.toDouble(), // ✅ FIXED (was e.value.score)
                      ),
                    )
                    .toList(),
                belowBarData: BarAreaData(
                  show: true,
                  color: accent.withOpacity(0.15),
                ),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chartContainer(BuildContext context, String title, Widget child) {
    final textColor = AppTheme.adaptiveText(context);
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
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _emptyChart(BuildContext context, String message) {
    final textColor = AppTheme.adaptiveText(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: textColor)),
      ),
    );
  }
}
