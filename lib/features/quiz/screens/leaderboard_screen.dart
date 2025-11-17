// lib/features/quiz/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../quiz_repository.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final QuizRepository _quizRepo = QuizRepository();

  /// Selected tab: daily | weekly
  String selectedTab = "daily";

  int? myDailyRank;
  int? myWeeklyRank;

  Map<String, dynamic>? myDailyData;
  Map<String, dynamic>? myWeeklyData;

  @override
  void initState() {
    super.initState();
    _fetchDailyRank();
    _fetchWeeklyRank();
  }

  // -----------------------------------------------------------
  // DATE KEYS
  // -----------------------------------------------------------
  String get todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
      myDailyRank = null;
      myDailyData = null;

      for (final doc in snap.docs) {
        if (doc.id == user!.uid) {
          myDailyRank = rank;
          myDailyData = doc.data();
          break;
        }
        rank++;
      }
      setState(() {});
    } catch (e) {
      debugPrint("⚠️ DailyRank fetch error: $e");
    }
  }

  // -----------------------------------------------------------
  // FETCH WEEKLY RANK
  // -----------------------------------------------------------
  Future<void> _fetchWeeklyRank() async {
    if (user == null) return;

    final list = await _fetchWeeklyLeaderboardList();

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

    setState(() {});
  }

  // -----------------------------------------------------------
  // WEEKLY LEADERBOARD = best score from last 7 days
  // -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchWeeklyLeaderboardList() async {
    final Map<String, Map<String, dynamic>> bestByUser = {};

    final now = DateTime.now();
    final last7days = List.generate(7, (i) => now.subtract(Duration(days: i)));

    for (final d in last7days) {
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final snap = await FirebaseFirestore.instance
          .collection("daily_leaderboard")
          .doc(key)
          .collection("entries")
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final uid = data["uid"];
        final score = data["score"] ?? 0;
        final ts = (data["timestamp"] as Timestamp?)?.toDate() ?? d;

        if (!bestByUser.containsKey(uid) ||
            score > (bestByUser[uid]!["score"] ?? -999)) {
          bestByUser[uid] = {
            "uid": uid,
            "name": data["name"] ?? "Player",
            "photoUrl": data["photoUrl"] ?? "",
            "score": score,
            "date": ts,
          };
        }
      }
    }

    final list = bestByUser.values.toList();
    list.sort((a, b) => b["score"].compareTo(a["score"]));
    return list;
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

  //----------------------------------------------------------------
  // TABS
  //----------------------------------------------------------------
  Widget _tabs(Color textColor, Color accent) {
    const tabs = ["daily", "weekly"];
    const labels = ["Daily", "Weekly"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(2, (i) {
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = tabs[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTab == tabs[i] ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selectedTab == tabs[i]
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

  //----------------------------------------------------------------
  // TAB CONTENT
  //----------------------------------------------------------------
  Widget _tabContent(Color textColor, Color accent) {
    if (selectedTab == "daily") {
      return _dailyLeaderboard(textColor, accent);
    } else {
      return FutureBuilder(
        future: _fetchWeeklyLeaderboardList(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildLeaderboardList(snap.data!, textColor, accent);
        },
      );
    }
  }

  //----------------------------------------------------------------
  // DAILY STREAM
  //----------------------------------------------------------------
  Widget _dailyLeaderboard(Color textColor, Color accent) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _quizRepo.getDailyLeaderboard(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snap.data!.docs.map((e) {
          final d = e.data();
          return {
            "uid": e.id,
            "name": d["name"] ?? "Player",
            "photoUrl": d["photoUrl"] ?? "",
            "score": d["score"] ?? 0,
            "date": (d["timestamp"] as Timestamp?)?.toDate(),
          };
        }).toList();

        return _buildLeaderboardList(list, textColor, accent);
      },
    );
  }

  //----------------------------------------------------------------
  // LEADERBOARD ITEM UI
  //----------------------------------------------------------------
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

        final DateTime? date = entry["date"];
        final String day = date != null ? DateFormat('EEE').format(date) : "";

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
                backgroundColor: isYou ? accent : accent.withOpacity(0.2),
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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${entry["score"]}",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (day.isNotEmpty)
                    Text(
                      day,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  //----------------------------------------------------------------
  // YOUR RANK SECTION
  //----------------------------------------------------------------
  Widget? _yourRankSection() {
    if (user == null) return null;

    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    int? rank;
    Map<String, dynamic>? data;

    if (selectedTab == "daily") {
      rank = myDailyRank;
      data = myDailyData;
    } else {
      rank = myWeeklyRank;
      data = myWeeklyData;
    }

    if (rank == null || data == null) return null;

    final score = data["score"] ?? 0;

    DateTime? date = data["date"];
    final String day = date != null ? DateFormat('EEE').format(date) : "";

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
              "You • Rank #$rank\nScore: $score${day.isNotEmpty ? " ($day)" : ""}",
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.emoji_events_rounded, color: accent, size: 26),
        ],
      ),
    );
  }
}
