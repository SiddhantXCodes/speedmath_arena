//lib/features/quiz/screens/leaderboard_screen.dart
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

  String selectedTab = "daily"; // daily | all
  int? myRank;
  Map<String, dynamic>? myData;

  /// 🔑 Stable date key for Firestore docs
  String get todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _fetchMyRank();
  }

  /// 🔥 Fetch the current user's rank (DAILY)
  Future<void> _fetchMyRank() async {
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('daily_leaderboard')
          .doc(todayKey)
          .collection('entries')
          .orderBy('score', descending: true)
          .orderBy('timeTaken', descending: false)
          .get();

      int rank = 1;

      for (final doc in query.docs) {
        if (doc.id == user!.uid) {
          setState(() {
            myRank = rank;
            myData = doc.data();
          });
          return;
        }
        rank++;
      }

      setState(() {
        myRank = null;
        myData = null;
      });
    } catch (e) {
      debugPrint("⚠️ _fetchMyRank error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Leaderboard", style: TextStyle(color: textColor)),
        backgroundColor: accent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _fetchMyRank();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildTabs(textColor, accent),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: selectedTab == "daily"
                  ? _quizRepo.getDailyLeaderboard()
                  : FirebaseFirestore.instance
                        .collection('alltime_leaderboard')
                        .orderBy('totalScore', descending: true)
                        .limit(50)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      selectedTab == "daily"
                          ? "No results yet today!"
                          : "No leaderboard data.",
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                final entries = snapshot.data!.docs.map((e) {
                  final data = e.data();
                  return {
                    'id': e.id,
                    'name': data['name'] ?? 'Player',
                    'photoUrl': data['photoUrl'] ?? '',
                    'score': selectedTab == "daily"
                        ? (data['score'] ?? 0)
                        : (data['totalScore'] ?? 0),
                    'timeTaken': data['timeTaken'] ?? 0,
                    'correct': data['correct'] ?? 0,
                  };
                }).toList();

                return _buildLeaderboardList(
                  context,
                  entries,
                  textColor,
                  accent,
                );
              },
            ),
          ),

          // 👤 Your Rank Card (ONLY for daily)
          if (selectedTab == "daily" &&
              user != null &&
              myData != null &&
              myRank != null)
            _yourRankCard(context, accent, textColor),
        ],
      ),
    );
  }

  // ========================================================
  //  UI WIDGETS
  // ========================================================

  /// 🏅 Tabs for switching (Daily / All Time)
  Widget _buildTabs(Color textColor, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabButton("daily", "Daily", textColor, accent),
          _tabButton("all", "All Time", textColor, accent),
        ],
      ),
    );
  }

  Widget _tabButton(String id, String label, Color textColor, Color accent) {
    final isActive = selectedTab == id;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = id);
          if (id == "daily") _fetchMyRank();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : textColor.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🏆 Build Leaderboard List
  Widget _buildLeaderboardList(
    BuildContext context,
    List<Map<String, dynamic>> list,
    Color textColor,
    Color accent,
  ) {
    final top3 = list.take(3).toList();
    final rest = list.length > 3 ? list.sublist(3) : [];

    return Column(
      children: [
        if (top3.isNotEmpty) _buildTopThree(context, top3),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 70),
            itemCount: rest.length,
            itemBuilder: (context, index) {
              final entry = rest[index];
              final rank = index + 4;
              final isYou = user != null && entry['id'] == user!.uid;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isYou
                      ? accent.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isYou
                          ? accent
                          : accent.withOpacity(0.25),
                      radius: 18,
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
                      backgroundImage: entry['photoUrl'].toString().isNotEmpty
                          ? NetworkImage(entry['photoUrl'])
                          : null,
                      backgroundColor: accent.withOpacity(0.2),
                      child: entry['photoUrl'].toString().isEmpty
                          ? Text(
                              (entry['name'] ?? "U")[0].toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      "${entry['score']} pts",
                      style: TextStyle(
                        color: textColor.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🥇 Top 3 Display
  Widget _buildTopThree(BuildContext context, List<Map<String, dynamic>> list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (list.length > 1) _topAvatar(context, list[1], 2, size: 65),
          _topAvatar(context, list[0], 1, size: 80, crown: true),
          if (list.length > 2) _topAvatar(context, list[2], 3, size: 65),
        ],
      ),
    );
  }

  Widget _topAvatar(
    BuildContext context,
    Map data,
    int rank, {
    required double size,
    bool crown = false,
  }) {
    final textColor = AppTheme.adaptiveText(context);
    final color = rank == 1
        ? AppTheme.gold
        : rank == 2
        ? AppTheme.silver
        : rank == 3
        ? AppTheme.bronze
        : AppTheme.adaptiveAccent(context);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (crown)
              Positioned(
                top: -20,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: color,
                  size: 28,
                ),
              ),
            CircleAvatar(
              radius: size / 2,
              backgroundImage: data['photoUrl'].toString().isNotEmpty
                  ? NetworkImage(data['photoUrl'])
                  : null,
              backgroundColor: color.withOpacity(0.15),
              child: data['photoUrl'].toString().isEmpty
                  ? Text(
                      (data['name'] ?? 'P')[0].toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          "${data['score']} pts",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  /// 👤 "YOU" Card
  Widget _yourRankCard(BuildContext context, Color accent, Color textColor) {
    final data = myData!;
    final score = data['score'] ?? 0;
    final correct = data['correct'] ?? 0;
    final time = data['timeTaken'] ?? 0;

    final m = (time ~/ 60).toString().padLeft(2, '0');
    final s = (time % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
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
              "You • Rank #$myRank\n$score pts • $correct correct • $m:$s",
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
