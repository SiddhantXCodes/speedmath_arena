// lib/features/home/widgets/quick_stats.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // ---------------- NOTIFIERS ----------------
  final ValueNotifier<int> offlineSessions = ValueNotifier<int>(0);
  final ValueNotifier<int> bestOfflineScore = ValueNotifier<int>(0);
  final ValueNotifier<int> weeklyAverage = ValueNotifier<int>(0);

  final ValueNotifier<int?> todayScore = ValueNotifier<int?>(null);
  final ValueNotifier<int?> todayRank = ValueNotifier<int?>(null);
  final ValueNotifier<int?> weeklyRank = ValueNotifier<int?>(null);
  final ValueNotifier<bool> attemptedToday = ValueNotifier<bool>(false);

  // ---------------- REALTIME SUBS ----------------
  StreamSubscription? _todayEntrySub;
  StreamSubscription? _todayLeaderboardSub;
  StreamSubscription? _weeklySub;

  bool _isFetching = false;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  bool _shouldFetch() =>
      DateTime.now().difference(_lastFetch).inMilliseconds > 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<myauth.AuthProvider>().addListener(_onExtChange);
      } catch (_) {}
      try {
        context.read<PerformanceProvider>().addListener(_onExtChange);
      } catch (_) {}
      _init();
    });
  }

  Future<void> _init() async {
    await _fetchStats();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      context.read<myauth.AuthProvider>().removeListener(_onExtChange);
    } catch (_) {}
    try {
      context.read<PerformanceProvider>().removeListener(_onExtChange);
    } catch (_) {}

    _cancelSubs();

    offlineSessions.dispose();
    bestOfflineScore.dispose();
    weeklyAverage.dispose();
    todayScore.dispose();
    todayRank.dispose();
    weeklyRank.dispose();
    attemptedToday.dispose();

    super.dispose();
  }

  void _onExtChange() {
    if (_shouldFetch()) {
      _fetchStats();
      _setupRealtimeListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldFetch()) {
      Future.delayed(const Duration(milliseconds: 150), _fetchStats);
    }
  }

  // ----------------------------------------------------------------------
  // ------------------------- Fetch Everything ---------------------------
  // ----------------------------------------------------------------------
  Future<void> _fetchStats() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;
    _lastFetch = DateTime.now();

    try {
      _fetchOfflineStats();
      await _fetchTodayAndWeeklyStats();
    } catch (_) {}

    _isFetching = false;
  }

  void _fetchOfflineStats() {
    final all = [
      ...HiveService.getPracticeScores(),
      ...HiveService.getMixedScores(),
    ];

    offlineSessions.value = all.length;

    int best = 0;
    int sum = 0;
    int count = 0;
    final now = DateTime.now();

    for (final s in all) {
      if (s.score > best) best = s.score;

      final d = DateTime(s.date.year, s.date.month, s.date.day);
      if (now.difference(d).inDays <= 6) {
        sum += s.score;
        count++;
      }
    }

    bestOfflineScore.value = best;
    weeklyAverage.value = count > 0 ? (sum ~/ count) : 0;
  }

  // ----------------------------------------------------------------------
  // ------------------- ONE-SHOT TODAY + WEEKLY FETCH -------------------
  // ----------------------------------------------------------------------
  Future<void> _fetchTodayAndWeeklyStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      attemptedToday.value = false;
      todayScore.value = null;
      todayRank.value = null;
      weeklyRank.value = null;
      return;
    }

    final uid = user.uid;
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      // TODAY SCORE
      final todayDoc = await FirebaseFirestore.instance
          .collection("daily_leaderboard")
          .doc(todayKey)
          .collection("entries")
          .doc(uid)
          .get();

      if (todayDoc.exists) {
        attemptedToday.value = true;
        final raw = todayDoc.data()?["score"];
        todayScore.value = raw is int ? raw : (raw is num ? raw.toInt() : null);
      } else {
        attemptedToday.value = false;
        todayScore.value = null;
      }

      // TODAY RANK
      final todaySnap = await FirebaseFirestore.instance
          .collection("daily_leaderboard")
          .doc(todayKey)
          .collection("entries")
          .orderBy("score", descending: true)
          .orderBy("timeTaken")
          .get();

      int r = 1;
      int? result;
      for (final d in todaySnap.docs) {
        if (d.id == uid) {
          result = r;
          break;
        }
        r++;
      }
      todayRank.value = result;

      // WEEKLY RANK
      weeklyRank.value = await _computeWeeklyRank(uid);
    } catch (e) {
      print("Error fetching ranked: $e");
    }
  }

  // ----------------------------------------------------------------------
  // --------------------------- REALTIME LISTENERS -----------------------
  // ----------------------------------------------------------------------
  void _setupRealtimeListeners() {
    _cancelSubs();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // DAILY ENTRY LISTENER
    _todayEntrySub = FirebaseFirestore.instance
        .collection("daily_leaderboard")
        .doc(todayKey)
        .collection("entries")
        .doc(uid)
        .snapshots()
        .listen((doc) async {
          if (!mounted) return;

          if (doc.exists) {
            attemptedToday.value = true;
            final raw = doc.data()?["score"];
            todayScore.value = raw is int
                ? raw
                : (raw is num ? raw.toInt() : null);
          } else {
            attemptedToday.value = false;
            todayScore.value = null;
          }

          weeklyRank.value = await _computeWeeklyRank(uid);
        });

    // TODAY RANK LISTENER
    _todayLeaderboardSub = FirebaseFirestore.instance
        .collection("daily_leaderboard")
        .doc(todayKey)
        .collection("entries")
        .orderBy("score", descending: true)
        .orderBy("timeTaken")
        .snapshots()
        .listen((snap) {
          if (!mounted) return;

          final idx = snap.docs.indexWhere((d) => d.id == uid);
          todayRank.value = idx >= 0 ? idx + 1 : null;
        });

    // WEEKLY UPDATES LISTENER
    _weeklySub = FirebaseFirestore.instance
        .collection("daily_leaderboard")
        .snapshots()
        .listen((_) async {
          if (!mounted) return;
          weeklyRank.value = await _computeWeeklyRank(uid);
        });
  }

  void _cancelSubs() {
    _todayEntrySub?.cancel();
    _todayEntrySub = null;

    _todayLeaderboardSub?.cancel();
    _todayLeaderboardSub = null;

    _weeklySub?.cancel();
    _weeklySub = null;
  }

  // ----------------------------------------------------------------------
  // -------------------------- WEEKLY RANK LOGIC -------------------------
  // ----------------------------------------------------------------------
  Future<int?> _computeWeeklyRank(String uid) async {
    try {
      final now = DateTime.now();

      // LAST 7 DAYS KEY LIST
      final last7 = List.generate(7, (i) => now.subtract(Duration(days: i)));

      Map<String, int> bestByUser = {};

      for (final d in last7) {
        final key =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

        final snap = await FirebaseFirestore.instance
            .collection("daily_leaderboard")
            .doc(key)
            .collection("entries")
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final suid = data["uid"];
          final score = data["score"] ?? 0;

          if (!bestByUser.containsKey(suid) || score > bestByUser[suid]!) {
            bestByUser[suid] = score;
          }
        }
      }

      if (!bestByUser.containsKey(uid)) return null;

      final sorted = bestByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int rank = 1;
      for (final e in sorted) {
        if (e.key == uid) return rank;
        rank++;
      }
      return null;
    } catch (e) {
      print("Weekly rank error: $e");
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // ------------------------------ UI ------------------------------------
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final accent = AppTheme.adaptiveAccent(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final textColor = AppTheme.adaptiveText(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
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

          // Offline stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _valueBox(offlineSessions, Icons.school, "Sessions", accent),
              _valueBox(bestOfflineScore, Icons.stars, "Best", accent),
              _valueBox(weeklyAverage, Icons.show_chart, "Weekly Avg", accent),
            ],
          ),

          const SizedBox(height: 20),

          // Ranked section
          user != null ? _rankedSection(accent, textColor) : _guestCTA(accent),
        ],
      ),
    );
  }

  Widget _rankedSection(Color accent, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: attemptedToday,
            builder: (_, played, __) => Text(
              played
                  ? "🎯 You've completed today's ranked quiz!"
                  : "⚡ Take today's Ranked Quiz and climb the leaderboard!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _valueBox(
                todayRank,
                Icons.emoji_events,
                "Today Rank",
                accent,
                prefix: "#",
              ),
              _valueBox(todayScore, Icons.bolt, "Today Score", accent),
              _valueBox(
                weeklyRank,
                Icons.trending_up,
                "Weekly Rank",
                accent,
                prefix: "#",
              ),
            ],
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<bool>(
            valueListenable: attemptedToday,
            builder: (_, played, __) {
              return ElevatedButton.icon(
                onPressed: () {
                  if (played) {
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
                        ).then((_) async => await _fetchStats());
                      },
                    );
                  }
                },
                icon: Icon(played ? Icons.leaderboard : Icons.flash_on_rounded),
                label: Text(played ? "View Leaderboard" : "Take Today's Quiz"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _valueBox(
    ValueNotifier notifier,
    IconData icon,
    String title,
    Color accent, {
    String prefix = "",
  }) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, val, __) {
        final display = val == null
            ? "—"
            : (prefix.isEmpty ? "$val" : "$prefix$val");

        return Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 4),
            Text(
              display,
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
      },
    );
  }

  Widget _guestCTA(Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            "🔥 Take the Daily Ranked Quiz to get your global ranking!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text("Login to Compete"),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
