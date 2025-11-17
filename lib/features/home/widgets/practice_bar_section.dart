//lib/features/home/widgets/practice_bar_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../quiz/screens/practice_overview_screen.dart';
import '../../../theme/app_theme.dart';
import '../../quiz/screens/practice_quiz_entry.dart';
import '../../quiz/screens/setup/mixed_quiz_setup_screen.dart';
import '../../quiz/screens/daily_ranked_quiz_entry.dart';
import '../../quiz/widgets/quiz_entry_popup.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../auth/auth_provider.dart';
import '../../../providers/performance_provider.dart';
import 'master_basics_section.dart';
import '../../auth/screens/login_screen.dart';
import '../../quiz/screens/result_screen.dart';

/// 🧮 Unified Practice Zone (below Quick Stats)
class PracticeBarSection extends StatelessWidget {
  const PracticeBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

    final perf = context.watch<PerformanceProvider>();
    final user = context.watch<AuthProvider>().user;

    final attemptedToday = perf.todayRank != null;

    // Cooldown Timer (Remaining hrs until next quiz)
    String cooldownText = "";
    if (attemptedToday) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final diff = tomorrow.difference(now);
      final hoursLeft = diff.inHours;
      cooldownText = "Next quiz in ${hoursLeft}h";
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
          // ⭐ Ranked Quiz Card (same design as other cards)
          _PracticeCard(
            title: attemptedToday
                ? "Today's Ranked Result"
                : "Daily Ranked Quiz",
            subtitle: attemptedToday
                ? "See your result & leaderboard position"
                : "1 attempt • 150 seconds timer",
            icon: attemptedToday
                ? Icons.leaderboard_rounded
                : Icons.flash_on_rounded,
            color: accent,
            badge: attemptedToday ? cooldownText : null,
            onTap: () {
              // Not logged in → login
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }

              // Already played today → go to result
              if (attemptedToday) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      score: perf.bestScore ?? 0,
                      timeTakenSeconds: 0,
                      mode: QuizMode.dailyRanked,
                    ),
                  ),
                );
                return;
              }

              // Not played today → start popup
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
                  ).then((_) => perf.reloadAll());
                },
              );
            },
          ),

          const SizedBox(height: 18),

          // 🧩 Offline Practice
          _PracticeCard(
            title: "Daily Practice Quiz",
            subtitle: "Train like ranked — no limits.",
            icon: Icons.school_rounded,
            color: accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PracticeOverviewScreen(
                    mode: PracticeMode.dailyPractice,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔀 Mixed Practice
          _PracticeCard(
            title: "Mixed Practice",
            subtitle: "Customize multiple topics.",
            icon: Icons.shuffle_rounded,
            color: accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PracticeOverviewScreen(
                    mode: PracticeMode.mixedPractice,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// 🎯 Practice Mode Card (Ranked + Offline + Mixed)
class _PracticeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  final String? badge; // 🔥 (optional) cooldown badge

  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            // Icon bubble
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 14),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: textColor,
                          ),
                        ),
                      ),

                      // 🔥 Cooldown badge (optional)
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
