// lib/features/quiz/screens/practice_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../services/hive_service.dart';
import '../../../models/daily_score.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../quiz/screens/setup/mixed_quiz_setup_screen.dart';
import '../../performance/screens/performance_screen.dart';
import '../../home/screens/home_screen.dart';

enum PracticeMode { dailyPractice, mixedPractice }

class PracticeOverviewScreen extends StatelessWidget {
  final PracticeMode mode;

  const PracticeOverviewScreen({super.key, required this.mode});

  bool get isDaily => mode == PracticeMode.dailyPractice;

  // Fixed daily practice configuration
  static const int dailyMin = 1;
  static const int dailyMax = 50;
  static const int dailyCount = 10;
  static const int dailyTimeLimit = 0;

  List<DailyScore> _loadHistory() {
    return isDaily
        ? HiveService.getPracticeScores()
        : HiveService.getMixedScores();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final surface = AppTheme.adaptiveCard(context);

    final attempts = _loadHistory()..sort((a, b) => b.date.compareTo(a.date));

    final lastAttempt = attempts.isNotEmpty ? attempts.first : null;

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
        appBar: AppBar(
          backgroundColor: accent,
          centerTitle: true,
          title: Text(isDaily ? "Daily Practice" : "Mixed Practice"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ------------------------------------------------------------
              // LAST ATTEMPT CARD
              // ------------------------------------------------------------
              if (lastAttempt != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_rounded, color: accent, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        "Last Attempt",
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${lastAttempt.score}",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Time: ${_formatDuration(lastAttempt.timeTakenSeconds)} • "
                        "${DateFormat('MMM d, yyyy').format(lastAttempt.date)}",
                        style: TextStyle(color: textColor.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 14),

                      // ACTION BUTTONS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (isDaily) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QuizScreen(
                                          title: "Daily Practice",
                                          min: dailyMin,
                                          max: dailyMax,
                                          count: dailyCount,
                                          mode: QuizMode.practice,
                                          timeLimitSeconds: dailyTimeLimit,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MixedQuizSetupScreen(),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text("Practice Again"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
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
                                label: const Text("Performance"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(color: accent, width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                // ------------------------------------------------------------
                // No attempts yet
                // ------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDaily ? "Daily Practice" : "Mixed Practice",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDaily
                            ? "10 questions • No time limit.\nBuild your speed daily!"
                            : "Select topics & ranges to create your custom practice quiz.",
                        style: TextStyle(color: textColor.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isDaily) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    title: "Daily Practice",
                                    min: dailyMin,
                                    max: dailyMax,
                                    count: dailyCount,
                                    mode: QuizMode.practice,
                                    timeLimitSeconds: dailyTimeLimit,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MixedQuizSetupScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isDaily
                                ? "Start Daily Practice"
                                : "Start Mixed Setup",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ------------------------------------------------------------
              // Past Attempts Title
              // ------------------------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Past Attempts (${attempts.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ------------------------------------------------------------
              // HEADER ROW
              // ------------------------------------------------------------
              if (attempts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _header("Date", textColor),
                      _header("Time", textColor),
                      _header(isDaily ? "Score" : "Result", textColor),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ------------------------------------------------------------
              // ATTEMPTS LIST
              // ------------------------------------------------------------
              Expanded(
                child: attempts.isEmpty
                    ? Center(
                        child: Text(
                          "No previous attempts",
                          style: TextStyle(color: textColor.withOpacity(0.6)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: attempts.length,
                        itemBuilder: (context, index) {
                          final s = attempts[index];
                          final isLast = index == 0;

                          final dateStr = DateFormat(
                            "MMM d, yy",
                          ).format(s.date);
                          final timeStr = DateFormat("h:mm a").format(s.date);

                          final mixedResult =
                              "${s.score} in ${s.timeTakenSeconds}s";

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? accent.withOpacity(0.08)
                                  : surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLast
                                    ? accent.withOpacity(0.15)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    isDaily ? "${s.score}" : mixedResult,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDaily ? 18 : 15,
                                    ),
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

  Widget _header(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color.withOpacity(0.8),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
