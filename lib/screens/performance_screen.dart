// lib/screens/performance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/performance_provider.dart';
import '../providers/practice_log_provider.dart';
import '../widgets/heatmap_section.dart';
import '../theme/app_theme.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  String selectedCategory = "All";
  late AnimationController _fadeController;

  // Leaderboard header state
  int? todaysRank;
  int? allTimeRankFromServer;
  int? totalUsersCount;
  int? bestDailyScore;
  int? totalScore;
  bool _loadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchLeaderboardHeader(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboardHeader() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final perf = Provider.of<PerformanceProvider>(context, listen: false);

      allTimeRankFromServer = perf.allTimeRank;

      if (user == null) {
        setState(() => _loadingLeaderboard = false);
        return;
      }

      final uid = user.uid;
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      // Fetch today's rank
      try {
        final dailySnap = await FirebaseFirestore.instance
            .collection('daily_leaderboard')
            .doc(todayKey)
            .collection('entries')
            .orderBy('score', descending: true)
            .orderBy('timeTaken')
            .get();

        int rank = 1;
        for (final doc in dailySnap.docs) {
          if (doc.id == uid) {
            todaysRank = rank;
            break;
          }
          rank++;
        }
      } catch (_) {}

      // Fetch all-time rank
      try {
        final allSnap = await FirebaseFirestore.instance
            .collection('alltime_leaderboard')
            .orderBy('totalScore', descending: true)
            .get();

        totalUsersCount = allSnap.size;
        int rank = 1;
        for (final doc in allSnap.docs) {
          if (doc.id == uid) {
            allTimeRankFromServer = rank;
            final data = doc.data();
            bestDailyScore =
                (data['bestDailyScore'] ?? data['bestScore'] ?? 0) as int?;
            totalScore = (data['totalScore'] ?? 0) as int?;
            break;
          }
          rank++;
        }
      } catch (_) {}

      if (allTimeRankFromServer == null) {
        allTimeRankFromServer = perf.allTimeRank;
      }
    } catch (e) {
      debugPrint("⚠️ Leaderboard header fetch failed: $e");
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final performance = Provider.of<PerformanceProvider>(context);
    final practice = Provider.of<PracticeLogProvider>(context);

    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final offlineMap = practice.getActivityMap();
    final onlineMap = Map<DateTime, int>.fromEntries(
      performance.dailyScores.keys.map((d) => MapEntry(d, 1)),
    );
    final mergedActivity = _mergeActivity(offlineMap, onlineMap);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        title: const Text("Performance Dashboard"),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeaderboardHeader(context, textColor, accent),
              const SizedBox(height: 16),
              _buildSummaryRow(context, performance, practice, accent),
              const SizedBox(height: 20),
              _buildCompareWeek(context, performance, practice, accent),
              const SizedBox(height: 20),
              _buildTrendChart(context, performance, accent, textColor),
              const SizedBox(height: 20),
              _buildAccuracyChart(context, practice, accent, textColor),
              const SizedBox(height: 20),
              Text(
                "Overall Activity (Offline + Ranked)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              HeatmapSection(
                isDarkMode: isDark,
                activity: mergedActivity,
                cellSize: 12,
                cellSpacing: 3,
                colorForValue: (v) {
                  switch (v.clamp(0, 4)) {
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
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader(
    BuildContext context,
    Color textColor,
    Color accent,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Player';
    final avatar = user?.photoURL;

    final percentile =
        (allTimeRankFromServer != null &&
            totalUsersCount != null &&
            totalUsersCount! > 0)
        ? (((totalUsersCount! - allTimeRankFromServer!) / totalUsersCount!) *
                  100)
              .clamp(0, 100)
              .toStringAsFixed(0)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.95), accent.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: avatar != null
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar == null
                        ? Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (_loadingLeaderboard)
                    const Positioned(
                      bottom: -6,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $displayName",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statPill(
                      "Today",
                      todaysRank != null ? "#$todaysRank" : "—",
                    ),
                    const SizedBox(width: 8),
                    _statPill(
                      "All-time",
                      allTimeRankFromServer != null
                          ? "#$allTimeRankFromServer"
                          : "--",
                    ),
                    const SizedBox(width: 8),
                    _statPill(
                      "Best",
                      bestDailyScore != null ? "${bestDailyScore!} pts" : "--",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  percentile != null
                      ? "Top $percentile% • ${totalUsersCount ?? '--'} users"
                      : "Global stats unavailable",
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchLeaderboardHeader,
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: "Refresh leaderboard",
          ),
        ],
      ),
    );
  }

  Widget _statPill(String title, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildSummaryRow(
    BuildContext context,
    PerformanceProvider perf,
    PracticeLogProvider log,
    Color accent,
  ) {
    final avgSpeed = log.logs.isNotEmpty
        ? (log.logs.map((e) => e.avgTime).reduce((a, b) => a + b) /
              log.logs.length)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            "Total Sessions",
            "${log.logs.length}",
            Icons.history_rounded,
            accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            "7-Day Avg",
            "${perf.weeklyAverage}",
            Icons.trending_up_rounded,
            accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            "Avg Speed",
            "${avgSpeed.toStringAsFixed(1)}s",
            Icons.timer_rounded,
            accent,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color accent,
  ) => Container(
    padding: const EdgeInsets.all(14),
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
      children: [
        Icon(icon, size: 22, color: accent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.adaptiveText(context).withOpacity(0.7),
          ),
        ),
      ],
    ),
  );

  Widget _buildCompareWeek(
    BuildContext context,
    PerformanceProvider perf,
    PracticeLogProvider log,
    Color accent,
  ) {
    final currentWeekScore = perf.weeklyAverage;
    final previousWeekScore = (perf.weeklyAverage * 0.75).round();
    final currentAccuracy = _calculateAccuracy(log);
    final previousAccuracy = (currentAccuracy * 0.8).round();

    return Container(
      padding: const EdgeInsets.all(14),
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
            "Weekly Comparison",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.adaptiveText(context),
            ),
          ),
          const SizedBox(height: 10),
          _progressRow(
            "Average Score",
            previousWeekScore,
            currentWeekScore,
            accent,
          ),
          const SizedBox(height: 10),
          _progressRow("Accuracy", previousAccuracy, currentAccuracy, accent),
        ],
      ),
    );
  }

  Widget _progressRow(String label, int oldVal, int newVal, Color accent) {
    final increase = newVal >= oldVal;
    final width = MediaQuery.of(context).size.width;
    final fillWidth = ((newVal.clamp(0, 100)) / 100) * (width * 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              height: 8,
              width: fillWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    PerformanceProvider perf,
    Color accent,
    Color textColor,
  ) {
    final data = perf.getLast7DaysDailyRankScores();
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "No ranked quiz data for the last 7 days",
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

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
            "Ranked Quiz Progress",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
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
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            (e.value['score'] ?? 0).toDouble(),
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
        ],
      ),
    );
  }

  Widget _buildAccuracyChart(
    BuildContext context,
    PracticeLogProvider log,
    Color accent,
    Color textColor,
  ) {
    int totalCorrect = 0;
    int totalIncorrect = 0;

    for (var l in log.logs) {
      totalCorrect += l.correct;
      totalIncorrect += l.incorrect;
    }

    final total = totalCorrect + totalIncorrect;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "No practice data yet",
            style: TextStyle(color: textColor),
          ),
        ),
      );
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

  Map<DateTime, int> _mergeActivity(
    Map<DateTime, int> a,
    Map<DateTime, int> b,
  ) {
    final combined = Map<DateTime, int>.from(a);
    for (final entry in b.entries) {
      combined[entry.key] = (combined[entry.key] ?? 0) + entry.value;
    }
    return combined.map((k, v) => MapEntry(k, v.clamp(0, 5)));
  }

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
