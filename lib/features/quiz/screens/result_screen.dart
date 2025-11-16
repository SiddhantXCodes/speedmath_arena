import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../performance/screens/performance_screen.dart';
import '../../home/screens/home_screen.dart';
import 'leaderboard_screen.dart';
import '../../../providers/performance_provider.dart';
import '../../../services/hive_service.dart';
import '../../../models/daily_score.dart';

import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int timeTakenSeconds;
  final QuizMode mode;

  const ResultScreen({
    super.key,
    required this.score,
    required this.timeTakenSeconds,
    this.mode = QuizMode.practice,
  });

  bool get isRanked =>
      mode == QuizMode.dailyRanked || mode == QuizMode.timedRanked;

  // ----------------------------------------------------------
  // LOAD HISTORY BASED ON QUIZ TYPE
  // ----------------------------------------------------------
  List<DailyScore> _loadHistory() {
    switch (mode) {
      case QuizMode.practice:
        return HiveService.getPracticeScores();

      case QuizMode.dailyRanked:
      case QuizMode.timedRanked:
        return HiveService.getRankedScores();

      case QuizMode.challenge:
        return HiveService.getMixedScores();

      default:
        return HiveService.getPracticeScores();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final surface = AppTheme.adaptiveCard(context);

    // Refresh performance only for ranked
    if (isRanked) {
      Future.microtask(() {
        Provider.of<PerformanceProvider>(context, listen: false).reloadAll();
      });
    }

    final mins = (timeTakenSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (timeTakenSeconds % 60).toString().padLeft(2, '0');

    // Load filtered attempts
    final List<DailyScore> history = _loadHistory()
      ..sort((a, b) => b.date.compareTo(a.date));

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        // --------------------------- APP BAR ---------------------------
        appBar: AppBar(
          backgroundColor: accent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.adaptiveText(context),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
          ),
          title: Text(
            isRanked ? "Ranked Result" : "Quiz Result",
            style: TextStyle(
              color: AppTheme.adaptiveText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),

        // --------------------------- BODY ---------------------------
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ----------------------------------------------------
              // ⭐ SCORE CARD
              // ----------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: isRanked ? Colors.amber : accent,
                      size: 40,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Your Score",
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "$score",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Time Taken: $mins:$secs",
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------
              // 🔘 MAIN BUTTONS
              // ----------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text("Home"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  if (isRanked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.leaderboard_rounded),
                        label: const Text("Leaderboard"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: accent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 18),

              // ----------------------------------------------------
              // 📊 PERFORMANCE SCREEN
              // ----------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerformanceScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights_rounded),
                  label: const Text("Performance Page"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ----------------------------------------------------
              // 🕒 HISTORY TITLE
              // ----------------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Past Attempts (${history.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------
              // 📜 HISTORY LIST
              // ----------------------------------------------------
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          "No previous attempts",
                          style: TextStyle(color: textColor.withOpacity(0.6)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final s = history[index];

                          final d = s.date;
                          final date =
                              "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

                          final mm = (s.timeTakenSeconds ~/ 60)
                              .toString()
                              .padLeft(2, '0');
                          final ss = (s.timeTakenSeconds % 60)
                              .toString()
                              .padLeft(2, '0');

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                /// DATE
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                /// TIME
                                Text(
                                  "$mm:$ss",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),

                                /// SCORE
                                Text(
                                  "${s.score}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
