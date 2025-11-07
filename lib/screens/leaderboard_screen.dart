import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> dailyLeaderboard = [];
  List<Map<String, dynamic>> allTimeLeaderboard = [];
  String selectedTab = "daily";
  int? myScore;
  String? todayKey;

  @override
  void initState() {
    super.initState();
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    final prefs = await SharedPreferences.getInstance();
    todayKey = DateTime.now().toIso8601String().substring(0, 10);
    myScore = prefs.getInt('daily_score_$todayKey') ?? 0;
    final random = Random();

    dailyLeaderboard = List.generate(10, (i) {
      return {'name': 'User_${1000 + i}', 'score': random.nextInt(100) + 20};
    });

    dailyLeaderboard.add({'name': 'You', 'score': myScore ?? 34});

    allTimeLeaderboard = List.generate(10, (i) {
      return {'name': 'User_${1000 + i}', 'score': 500 + random.nextInt(500)};
    });

    allTimeLeaderboard.add({'name': 'You', 'score': 650});

    dailyLeaderboard.sort((a, b) => b['score'].compareTo(a['score']));
    allTimeLeaderboard.sort((a, b) => b['score'].compareTo(a['score']));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = AppTheme.adaptiveText(context);
    final surface = theme.scaffoldBackgroundColor;

    final currentList = selectedTab == "daily"
        ? dailyLeaderboard
        : allTimeLeaderboard;

    final myRank = currentList.indexWhere((e) => e['name'] == 'You') + 1;
    final myEntry = currentList.firstWhere(
      (e) => e['name'] == 'You',
      orElse: () => {},
    );

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
        backgroundColor: surface,
        elevation: 0,
      ),
      body: currentList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                _buildTabs(context, textColor),
                const SizedBox(height: 16),
                _buildTopThree(context, currentList),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 12),
                    itemCount: currentList.length - 3,
                    itemBuilder: (context, index) {
                      final entry = currentList[index + 3];
                      final isYou = entry['name'] == 'You';
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isYou
                              ? colorScheme.primaryContainer.withOpacity(0.4)
                              : colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isYou
                                  ? colorScheme.primary
                                  : colorScheme.primaryContainer,
                              child: Text(
                                "${index + 4}",
                                style: TextStyle(
                                  color: isYou
                                      ? Colors.white
                                      : colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Text(
                              "${entry['score']} pts",
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildYouCard(context, myRank, myEntry),
              ],
            ),
    );
  }

  // --- Top 3 Section ---
  Widget _buildTopThree(BuildContext context, List<Map<String, dynamic>> list) {
    final textColor = AppTheme.adaptiveText(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (list.length < 3) return const SizedBox.shrink();
    final top3 = list.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(context, top3[1], 2, size: 65),
          _buildAvatar(context, top3[0], 1, size: 80, crown: true),
          _buildAvatar(context, top3[2], 3, size: 65),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    Map<String, dynamic> user,
    int rank, {
    required double size,
    bool crown = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = AppTheme.adaptiveText(context);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Crown for #1
            if (crown)
              Positioned(
                top: -20,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),

            // Avatar Circle
            CircleAvatar(
              radius: size / 2,
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.4),
              child: Text(
                user['name'] == 'You' ? 'You' : user['name'].substring(5),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            // Rank badge (bottom)
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "${user['score']} pts",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // --- Tabs (Daily / All-Time) ---
  Widget _buildTabs(BuildContext context, Color textColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabButton(context, "daily", "Daily", textColor),
          _tabButton(context, "all", "All Time", textColor),
        ],
      ),
    );
  }

  Widget _tabButton(
    BuildContext context,
    String id,
    String label,
    Color textColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = selectedTab == id;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
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

  // --- Sticky "You" card ---
  Widget _buildYouCard(
    BuildContext context,
    int myRank,
    Map<String, dynamic> myEntry,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = AppTheme.adaptiveText(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  "$myRank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Score: ${myEntry['score'] ?? 0}",
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }
}
