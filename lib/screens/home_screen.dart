import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/quick_stats.dart';
import '../widgets/heatmap_section.dart';
import '../widgets/features_section.dart';
import '../providers/performance_provider.dart';
import '../providers/practice_log_provider.dart';
import '../theme/app_theme.dart';
import '../app.dart';
import 'performance_screen.dart';
import 'mixed_practice/mixed_quiz_setup.dart'; // ✅ New import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final double cellSize = 12;
  final double cellSpacing = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _refreshActivityData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _refreshActivityData();

  Future<void> _refreshActivityData() async {
    try {
      final performance = Provider.of<PerformanceProvider>(
        context,
        listen: false,
      );
      await performance.loadFromStorage(forceReload: true);
      setState(() {});
    } catch (e) {
      debugPrint("⚠️ Failed to refresh data: $e");
    }
  }

  Color _colorForValue(int value) {
    switch (value.clamp(0, 4)) {
      case 0:
        return const Color(0xFFEBEDF0);
      case 1:
        return const Color(0xFF9BE9A8);
      case 2:
        return const Color(0xFF40C463);
      case 3:
        return const Color(0xFF30A14E);
      default:
        return const Color(0xFF216E39);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practiceLog = Provider.of<PracticeLogProvider>(context);
    final performance = Provider.of<PerformanceProvider>(context);

    final combinedActivity = _mergeActivityMaps(
      practiceLog.getActivityMap(),
      performance.dailyScores.keys.toList(),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: TopBar(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshActivityData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                QuickStatsSection(
                  isDarkMode: theme.brightness == Brightness.dark,
                ),
                const SizedBox(height: 20),
                HeatmapSection(
                  isDarkMode: theme.brightness == Brightness.dark,
                  activity: combinedActivity,
                  cellSize: cellSize,
                  cellSpacing: cellSpacing,
                  colorForValue: _colorForValue,
                ),
                const SizedBox(height: 24),

                // ✅ Performance Insights Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerformanceScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveCard(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Performance Insights",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.adaptiveText(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Track your progress & accuracy trends",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.adaptiveText(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.trending_up_rounded, size: 32),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ New: Mixed Practice Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MixedQuizSetupScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.adaptiveCard(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mixed Practice",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.adaptiveText(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Create your own quiz from multiple topics",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.adaptiveText(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.shuffle_rounded, size: 32),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                FeaturesSection(
                  isDarkMode: theme.brightness == Brightness.dark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<DateTime, int> _mergeActivityMaps(
    Map<DateTime, int> offline,
    List<DateTime> rankedDates,
  ) {
    final combined = Map<DateTime, int>.from(offline);
    for (final d in rankedDates) {
      final key = DateTime(d.year, d.month, d.day);
      combined[key] = (combined[key] ?? 0) + 1;
    }
    return combined.map((k, v) => MapEntry(k, v.clamp(0, 5)));
  }
}
