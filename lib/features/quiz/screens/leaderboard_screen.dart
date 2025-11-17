// lib/features/quiz/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../quiz_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final QuizRepository _quizRepo = QuizRepository();

  /// Selected tab: daily | weekly | all
  String selectedTab = "daily";

  int? myDailyRank;
  int? myWeeklyRank;
  int? myAllTimeRank;

  Map<String, dynamic>? myDailyData;
  Map<String, dynamic>? myWeeklyData;
  Map<String, dynamic>? myAllTimeData;

  @override
  void initState() {
    super.initState();
    _fetchDailyRank();
    _fetchWeeklyRank();
    _fetchAllTimeRank();
  }

  // -----------------------------------------------------------
  // FIRESTORE KEYS
  // -----------------------------------------------------------

  String get todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Monday → Sunday week window
  DateTime get weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)); // Monday
  }

  DateTime get weekEnd {
    final start = weekStart;
    return start.add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  // -----------------------------------------------------------
  // FETCH DAILY RANK
  // -----------------------------------------------------------
  Future<void> _fetchDailyRank() async {
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection("daily_leaderboard")
          .doc(todayKey)
          .collection("entries")
          .orderBy("score", descending: true)
          .orderBy("timeTaken")
          .get();

      int rank = 1;
      for (final doc in snap.docs) {
        if (doc.id == user!.uid) {
          myDailyRank = rank;
          myDailyData = doc.data();
          return;
        }
        rank++;
      }

      myDailyRank = null;
      myDailyData = null;
    } catch (e) {
      debugPrint("⚠️ DailyRank fetch error: $e");
    }
  }

  // -----------------------------------------------------------
  // FETCH WEEKLY RANK (best score in Mon→Sun window)
  // -----------------------------------------------------------
  Future<void> _fetchWeeklyRank() async {
    if (user == null) return;

    try {
      final start = Timestamp.fromDate(weekStart);
      final end = Timestamp.fromDate(weekEnd);

      final snap = await FirebaseFirestore.instance
          .collection("weekly_ranked_attempts")
          .where("timestamp", isGreaterThanOrEqualTo: start)
          .where("timestamp", isLessThanOrEqualTo: end)
          .get();

      // ⚡ Group by user → best score
      final Map<String, Map<String, dynamic>> bestByUser = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = data["uid"];
        final score = data["score"] ?? 0;
        final time = data["timeTaken"] ?? 0;

        if (!bestByUser.containsKey(uid) || score > bestByUser[uid]!["score"]) {
          bestByUser[uid] = {
            "uid": uid,
            "name": data["name"] ?? "Player",
            "photoUrl": data["photoUrl"] ?? "",
            "score": score,
            "timeTaken": time,
          };
        }
      }

      // Convert map → list
      final list = bestByUser.values.toList();

      // Sort
      list.sort((a, b) => b["score"].compareTo(a["score"]));

      // Find my rank
      int rank = 1;
      myWeeklyRank = null;
      myWeeklyData = null;

      for (final entry in list) {
        if (entry["uid"] == user!.uid) {
          myWeeklyRank = rank;
          myWeeklyData = entry;
          break;
        }
        rank++;
      }
    } catch (e) {
      debugPrint("⚠️ WeeklyRank fetch error: $e");
    }
  }

  // -----------------------------------------------------------
  // FETCH ALL-TIME RANK
  // -----------------------------------------------------------
  Future<void> _fetchAllTimeRank() async {
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("alltime_leaderboard")
          .orderBy("totalScore", descending: true)
          .get();

      int rank = 1;
      myAllTimeRank = null;
      myAllTimeData = null;

      for (final doc in snap.docs) {
        if (doc.id == user!.uid) {
          myAllTimeRank = rank;
          myAllTimeData = doc.data();
          break;
        }
        rank++;
      }
    } catch (e) {
      debugPrint("⚠️ AllTimeRank fetch error: $e");
    }
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Leaderboard"),
        backgroundColor: accent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _fetchDailyRank();
              await _fetchWeeklyRank();
              await _fetchAllTimeRank();
              setState(() {});
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          _tabs(textColor, accent),
          const SizedBox(height: 12),

          Expanded(child: _tabContent(textColor, accent)),
          if (_yourRankSection() != null) _yourRankSection()!,
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // TABS: daily | weekly | all
  // -----------------------------------------------------------
  Widget _tabs(Color textColor, Color accent) {
    const tabs = ["daily", "weekly", "all"];
    const labels = ["Daily", "Weekly", "All Time"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedTab = tabs[index]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTab == tabs[index]
                      ? accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selectedTab == tabs[index]
                          ? Colors.white
                          : textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // -----------------------------------------------------------
  // TAB CONTENT
  // -----------------------------------------------------------
  Widget _tabContent(Color textColor, Color accent) {
    if (selectedTab == "daily") {
      return _dailyLeaderboard(textColor, accent);
    } else if (selectedTab == "weekly") {
      return FutureBuilder(
        future: _fetchWeeklyLeaderboardList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildLeaderboardList(snapshot.data!, textColor, accent);
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("alltime_leaderboard")
            .orderBy("totalScore", descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!.docs.map((e) {
            final d = e.data();
            return {
              "id": e.id,
              "name": d["name"] ?? "Player",
              "photoUrl": d["photoUrl"] ?? "",
              "score": d["totalScore"] ?? 0,
              "timeTaken": 0,
            };
          }).toList();
          return _buildLeaderboardList(list, textColor, accent);
        },
      );
    }
  }

  // DAILY STREAM
  Widget _dailyLeaderboard(Color textColor, Color accent) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _quizRepo.getDailyLeaderboard(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final list = snap.data!.docs.map((e) {
          final d = e.data();
          return {
            "id": e.id,
            "name": d["name"] ?? "Player",
            "photoUrl": d["photoUrl"] ?? "",
            "score": d["score"] ?? 0,
            "timeTaken": d["timeTaken"] ?? 0,
          };
        }).toList();

        return _buildLeaderboardList(list, textColor, accent);
      },
    );
  }

  // WEEKLY (FETCH BEST OF WEEK)
  Future<List<Map<String, dynamic>>> _fetchWeeklyLeaderboardList() async {
    final start = Timestamp.fromDate(weekStart);
    final end = Timestamp.fromDate(weekEnd);

    final snap = await FirebaseFirestore.instance
        .collection("weekly_ranked_attempts")
        .where("timestamp", isGreaterThanOrEqualTo: start)
        .where("timestamp", isLessThanOrEqualTo: end)
        .get();

    final Map<String, Map<String, dynamic>> best = {};

    for (final doc in snap.docs) {
      final d = doc.data();
      final uid = d["uid"];
      final score = d["score"] ?? 0;

      if (!best.containsKey(uid) || score > best[uid]!["score"]) {
        best[uid] = d;
      }
    }

    final list = best.values.toList();
    list.sort((a, b) => b["score"].compareTo(a["score"]));

    return list;
  }

  // -----------------------------------------------------------
  // RENDER GENERIC LEADERBOARD LIST
  // -----------------------------------------------------------
  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> list,
    Color textColor,
    Color accent,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No results yet!",
          style: TextStyle(color: textColor.withOpacity(0.8)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        final rank = index + 1;
        final isYou = user != null && entry["uid"] == user!.uid;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isYou
                ? accent.withOpacity(0.15)
                : Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isYou ? accent : accent.withOpacity(0.25),
                child: Text(
                  "$rank",
                  style: TextStyle(
                    color: isYou ? Colors.white : textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundImage: entry["photoUrl"].toString().isNotEmpty
                    ? NetworkImage(entry["photoUrl"])
                    : null,
                backgroundColor: accent.withOpacity(0.25),
                child: entry["photoUrl"].toString().isEmpty
                    ? Text(
                        (entry["name"] ?? "U")[0].toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry["name"] ?? "Player",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "${entry["score"]} pts",
                style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------
  // YOUR RANK CARD (MATCHES CURRENT TAB)
  // -----------------------------------------------------------
  Widget? _yourRankSection() {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    if (user == null) return null;

    int? rank;
    Map<String, dynamic>? data;

    if (selectedTab == "daily") {
      rank = myDailyRank;
      data = myDailyData;
    } else if (selectedTab == "weekly") {
      rank = myWeeklyRank;
      data = myWeeklyData;
    } else if (selectedTab == "all") {
      rank = myAllTimeRank;
      data = myAllTimeData;
    }

    if (rank == null || data == null) return null;

    final score = data["score"] ?? 0;
    final time = data["timeTaken"] ?? 0;

    final m = (time ~/ 60).toString().padLeft(2, '0');
    final s = (time % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            backgroundColor: accent,
            child: user?.photoURL == null
                ? Text(
                    (user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "You • Rank #$rank\n$score pts • $m:$s",
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.emoji_events_rounded, color: accent, size: 28),
        ],
      ),
    );
  }
}
