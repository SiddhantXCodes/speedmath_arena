//lib/features/performance/screens/performance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/performance_provider.dart';
import '../../../providers/practice_log_provider.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/accuracy_chart.dart';
import '../widgets/performance_heatmap.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ fixed method name
      context.read<PerformanceProvider>().fetchLeaderboardHeader();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perf = context.watch<PerformanceProvider>();
    final log = context.watch<PracticeLogProvider>();
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Dashboard"),
        backgroundColor: accent,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LeaderboardHeader(provider: perf),
            const SizedBox(height: 20),
            WeeklySummaryCard(perf: perf, log: log),
            const SizedBox(height: 20),
            TrendChart(perf: perf),
            const SizedBox(height: 20),
            AccuracyChart(log: log),
            const SizedBox(height: 20),
            PerformanceHeatmap(perf: perf, log: log),
          ],
        ),
      ),
    );
  }
}
