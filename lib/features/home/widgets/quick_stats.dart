// lib/features/home/widgets/quick_stats.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../quiz/screens/daily_ranked_quiz_entry.dart';
import '../../quiz/screens/leaderboard_screen.dart';
import '../../performance/screens/performance_screen.dart';
import '../../../services/hive_service.dart';
import '../../../providers/performance_provider.dart';
import '../../quiz/widgets/quiz_entry_popup.dart';
import '../../auth/auth_provider.dart' as myauth;

class QuickStatsSection extends StatefulWidget {
  final bool isDarkMode;
  const QuickStatsSection({super.key, required this.isDarkMode});

  @override
  State<QuickStatsSection> createState() => _QuickStatsSectionState();
}

class _QuickStatsSectionState extends State<QuickStatsSection>
    with WidgetsBindingObserver {
  bool _loading = true;

  // OFFLINE
  int offlineSessions = 0;
  int bestOfflineScore = 0;
  int weeklyAverage = 0;

  // RANKED
  int? todayRank;
  int? allTimeRank;
  int? bestRankedScore;
  bool attemptedToday = false;

  bool _isFetching = false;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  bool _shouldFetch() {
    final diff = DateTime.now().difference(_lastFetch).inMilliseconds;
    if (diff < 350) return false;
    _lastFetch = DateTime.now();
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<myauth.AuthProvider>().addListener(_refetch);
      context.read<PerformanceProvider>().addListener(_refetch);
      _fetchStats();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      context.read<myauth.AuthProvider>().removeListener(_refetch);
      context.read<PerformanceProvider>().removeListener(_refetch);
    } catch (_) {}
    super.dispose();
  }

  void _refetch() {
    if (_shouldFetch()) _fetchStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldFetch()) {
      Future.delayed(const Duration(milliseconds: 150), _fetchStats);
    }
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  // ------------------------------------------------------------
  // MAIN FETCH
  // ------------------------------------------------------------
  Future<void> _fetchStats() async {
    if (!mounted || _isFetching) return;
    _isFetching = true;

    setState(() => _loading = true);

    try {
      // --------------------------------------------------
      // OFFLINE DATA → From DailyScore hive entries
      // --------------------------------------------------
      final allScores = HiveService.getAllDailyScores();

      offlineSessions = allScores.length;

      bestOfflineScore = 0;
      int sum = 0;
      int count = 0;

      final now = DateTime.now();

      for (final s in allScores) {
        // Best Offline Score (practice or ranked)
        bestOfflineScore = (s.score > bestOfflineScore)
            ? s.score
            : bestOfflineScore;

        // Weekly average (last 7 days)
        final d = DateTime(s.date.year, s.date.month, s.date.day);
        if (now.difference(d).inDays <= 6) {
          sum += s.score;
          count++;
        }
      }

      weeklyAverage = (count > 0) ? (sum / count).round() : 0;

      final user = FirebaseAuth.instance.currentUser;

      // --------------------------------------------------
      // USER NOT LOGGED IN
      // --------------------------------------------------
      if (user == null) {
        todayRank = null;
        allTimeRank = null;
        bestRankedScore = null;
        attemptedToday = false;

        if (mounted) setState(() => _loading = false);
        _isFetching = false;
        return;
      }

      // --------------------------------------------------
      // FETCH RANKED DATA (from PerformanceProvider)
      // --------------------------------------------------
      final perf = context.read<PerformanceProvider>();

      todayRank = perf.todayRank;
      allTimeRank = perf.allTimeRank;
      bestRankedScore = perf.bestScore;
      attemptedToday = perf.dailyScores.containsKey(
        DateTime(now.year, now.month, now.day),
      );

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint("⚠️ QuickStats Error: $e");
      if (mounted) setState(() => _loading = false);
    }

    _isFetching = false;
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final accent = AppTheme.adaptiveAccent(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final textColor = AppTheme.adaptiveText(context);

    if (_loading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Quick Stats",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PerformanceScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.insights, color: accent),
                label: Text(
                  "Performance",
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // OFFLINE STATS ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(Icons.school, "Sessions", "$offlineSessions", accent),
              _miniStat(Icons.stars, "Best", "$bestOfflineScore", accent),
              _miniStat(
                Icons.show_chart,
                "Weekly Avg",
                "$weeklyAverage",
                accent,
              ),
            ],
          ),

          const SizedBox(height: 20),

          user != null ? _rankedStats(accent) : _guestCTA(accent, textColor),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RANKED (LOGGED-IN)
  // ------------------------------------------------------------
  Widget _rankedStats(Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            attemptedToday
                ? "🎯 You've completed today's ranked quiz!"
                : "⚡ Take today's Ranked Quiz and climb the leaderboard!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(
                Icons.emoji_events,
                "Today Rank",
                todayRank != null ? "#$todayRank" : "—",
                accent,
              ),
              _miniStat(
                Icons.bar_chart,
                "All-Time",
                allTimeRank != null ? "#$allTimeRank" : "—",
                accent,
              ),
              _miniStat(
                Icons.bolt,
                "Best Score",
                bestRankedScore?.toString() ?? "—",
                accent,
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (attemptedToday) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                } else {
                  showQuizEntryPopup(
                    context: context,
                    title: "Daily Ranked Quiz",
                    infoLines: [
                      "150 seconds timer",
                      "Score = total correct answers",
                      "1 attempt per day",
                    ],
                    onStart: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyRankedQuizEntry(),
                        ),
                      ).then((_) {
                        context.read<PerformanceProvider>().reloadAll();
                        _fetchStats();
                      });
                    },
                  );
                }
              },
              icon: Icon(
                attemptedToday ? Icons.leaderboard : Icons.flash_on_rounded,
              ),
              label: Text(
                attemptedToday
                    ? "View Leaderboard"
                    : "Take Today's Ranked Quiz",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // GUEST
  // ------------------------------------------------------------
  Widget _guestCTA(Color accent, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            "🔥 Take the Daily Ranked Quiz to compete globally!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text("Login to Compete"),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent),
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MINI STAT WIDGET
  // ------------------------------------------------------------
  Widget _miniStat(IconData icon, String title, String value, Color accent) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: accent,
            fontSize: 15,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: accent.withOpacity(0.7)),
        ),
      ],
    );
  }
}
