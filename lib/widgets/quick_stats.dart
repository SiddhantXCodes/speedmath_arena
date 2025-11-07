// lib/widgets/quick_stats.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/performance_provider.dart';
import '../theme/app_theme.dart';
import '../screens/daily_ranked_quiz_screen.dart';

class QuickStatsSection extends StatelessWidget {
  final bool isDarkMode;
  const QuickStatsSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final accent = AppTheme.adaptiveAccent(context);
    final divider = Theme.of(context).dividerColor;

    final performance = Provider.of<PerformanceProvider>(context);
    final weekData = performance.getLast7DaysDailyRankScores();
    final avg = performance.weeklyAverage;
    final allTimeRank = performance.allTimeRank;
    final todayRank = performance.todayRank;

    // Prepare chart points based on attempted days
    final spots = <FlSpot>[];
    for (int i = 0; i < weekData.length; i++) {
      final entry = weekData[i];
      if (entry['attempted'] == true) {
        spots.add(FlSpot(i.toDouble(), (entry['score'] ?? 0).toDouble()));
      }
    }

    // Add 2 upcoming blank days (future)
    spots.add(FlSpot((weekData.length).toDouble(), 0));
    spots.add(FlSpot((weekData.length + 1).toDouble(), 0));

    final double maxY =
        (spots.isEmpty
                ? 100
                : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10))
            .toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: divider.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Quick Stats",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: accent),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("All-Time Rank", "#$allTimeRank", textColor),
              _statItem("Weekly Avg", "$avg pts", textColor),
              todayRank == null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyRankedQuizScreen(),
                          ),
                        );
                      },
                      child: _ctaItem(
                        "Today's Rank",
                        "Take Daily Quiz →",
                        accent,
                      ),
                    )
                  : _statItem("Today's Rank", "#$todayRank", textColor),
            ],
          ),
          const SizedBox(height: 16),

          // Chart (Scrollable)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FullStatsGraphScreen()),
            ),
            child: SizedBox(
              height: 150,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 700,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 8.5, // 7 days + 2 placeholders
                      minY: 0,
                      maxY: maxY,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (value, _) {
                              final labels = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                                'Next',
                                'Future',
                              ];
                              final i = value.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox();
                              }
                              return Text(
                                labels[i],
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ✅ Correct tooltip for all fl_chart versions
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => cardColor.withOpacity(0.95),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                "${spot.y.round()} pts",
                                TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),

                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: accent,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                                  radius: 3.5,
                                  color: accent,
                                  strokeWidth: 1,
                                  strokeColor: accent.withOpacity(0.3),
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: accent.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _ctaItem(String title, String label, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accent,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Full-screen graph screen
// ─────────────────────────────────────────────
class FullStatsGraphScreen extends StatelessWidget {
  const FullStatsGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final perf = Provider.of<PerformanceProvider>(context);
    final data = perf.getLast7DaysDailyRankScores();

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i]['attempted'] == true) {
        spots.add(FlSpot(i.toDouble(), (data[i]['score'] ?? 0).toDouble()));
      }
    }

    final double maxY =
        (spots.isEmpty
                ? 100
                : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 10))
            .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Performance Graph"),
        backgroundColor: accent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: data.length.toDouble(),
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(show: true),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cardColor.withOpacity(0.9),
                getTooltipItems: (spots) {
                  return spots.map((e) {
                    return LineTooltipItem(
                      "${e.y.round()} pts",
                      TextStyle(color: accent, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: accent,
                barWidth: 2.5,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: accent.withOpacity(0.18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
