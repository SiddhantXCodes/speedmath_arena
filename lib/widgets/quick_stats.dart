import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import '../screens/daily_ranked_quiz_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../data/hive_service.dart';

class QuickStatsSection extends StatefulWidget {
  final bool isDarkMode;
  const QuickStatsSection({super.key, required this.isDarkMode});

  @override
  State<QuickStatsSection> createState() => _QuickStatsSectionState();
}

class _QuickStatsSectionState extends State<QuickStatsSection>
    with WidgetsBindingObserver {
  int? todayRank;
  int? allTimeRank;
  double weeklyAverage = 0;
  bool _loading = true;

  // --- offline stats ---
  int offlineSessions = 0;
  int offlineCorrect = 0;
  int offlineIncorrect = 0;
  double offlineAvgTime = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchStats();
    }
  }

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _fetchStats() async {
    try {
      // --- Load offline stats first (always fast) ---
      final localStats = HiveService.getStats() ?? {};
      offlineSessions = (localStats['sessions'] ?? 0) as int;
      offlineCorrect = (localStats['totalCorrect'] ?? 0) as int;
      offlineIncorrect = (localStats['totalIncorrect'] ?? 0) as int;
      offlineAvgTime = (localStats['avgTime'] ?? 0.0) as double;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final todayKey = _dateKey(DateTime.now());

      // ---- Fetch today rank ----
      final dailyRef = firestore
          .collection('daily_leaderboard')
          .doc(todayKey)
          .collection('entries');
      final snapshot = await dailyRef
          .orderBy('score', descending: true)
          .orderBy('timeTaken')
          .get();

      int rank = 1;
      todayRank = null;
      for (final doc in snapshot.docs) {
        if (doc.id == user.uid) {
          todayRank = rank;
          break;
        }
        rank++;
      }

      // ---- Fetch all-time rank ----
      final allRef = firestore.collection('alltime_leaderboard').doc(user.uid);
      final allSnap = await allRef.get();

      if (allSnap.exists) {
        allTimeRank = await _getGlobalRank(user.uid);
        final data = allSnap.data()!;
        final quizzes = (data['quizzesTaken'] ?? 1).toDouble();
        final totalScore = (data['totalScore'] ?? 0).toDouble();
        weeklyAverage = quizzes > 0 ? totalScore / quizzes : 0;
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint("⚠️ Error loading stats: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int?> _getGlobalRank(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alltime_leaderboard')
          .orderBy('totalScore', descending: true)
          .get();
      int rank = 1;
      for (final doc in snapshot.docs) {
        if (doc.id == uid) return rank;
        rank++;
      }
    } catch (e) {
      debugPrint("⚠️ Rank fetch error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final accent = AppTheme.adaptiveAccent(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final textColor = AppTheme.adaptiveText(context);
    final divider = Theme.of(context).dividerColor;

    if (_loading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

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
          // Header Row
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
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: accent),
                tooltip: "Refresh stats",
                onPressed: () {
                  setState(() => _loading = true);
                  _fetchStats();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user == null)
            _buildLoginPrompt(context, accent, textColor)
          else
            _buildStats(context, accent, textColor),
          const SizedBox(height: 16),
          _buildOfflineStats(context, textColor, accent),
        ],
      ),
    );
  }

  // --- Online Stats Display (kept same) ---
  Widget _buildStats(BuildContext context, Color accent, Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statItem(
              "All-Time Rank",
              allTimeRank != null ? "#$allTimeRank" : "--",
              textColor,
            ),
            _statItem(
              "Avg Score",
              "${weeklyAverage.toStringAsFixed(1)} pts",
              textColor,
            ),
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
                    child: _ctaItem("Today's Rank", "Take Quiz →", accent),
                  )
                : _statItem("Today's Rank", "#$todayRank", textColor),
          ],
        ),
        const SizedBox(height: 8),
        if (todayRank != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
              icon: const Icon(Icons.leaderboard_rounded, size: 18),
              label: const Text("View Leaderboard"),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
      ],
    );
  }

  // --- New Offline Practice Stats Section ---
  Widget _buildOfflineStats(
    BuildContext context,
    Color textColor,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Offline Practice Summary",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statItem("Sessions", "$offlineSessions", textColor),
            _statItem("Correct", "$offlineCorrect", textColor),
            _statItem("Wrong", "$offlineIncorrect", textColor),
            _statItem(
              "Avg Time",
              "${offlineAvgTime.toStringAsFixed(1)}s",
              textColor,
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper UI Components (unchanged) ---
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

  Widget _buildLoginPrompt(
    BuildContext context,
    Color accent,
    Color textColor,
  ) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, color: accent, size: 40),
          const SizedBox(height: 10),
          Text(
            "Login to view your global rank & performance stats",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text(
              "Sign in to Continue",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent, width: 1.5),
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
