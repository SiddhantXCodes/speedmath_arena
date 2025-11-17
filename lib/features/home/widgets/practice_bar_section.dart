// lib/features/home/widgets/practice_bar_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../quiz/screens/daily_ranked_quiz_entry.dart';
import '../../quiz/widgets/quiz_entry_popup.dart';
import '../../quiz/screens/leaderboard_screen.dart';
import '../../quiz/screens/practice_quiz_entry.dart';
import '../../quiz/screens/setup/mixed_quiz_setup_screen.dart';
import '../../../models/practice_mode.dart';
import '../../quiz/screens/practice_overview_screen.dart';

class PracticeBarSection extends StatefulWidget {
  const PracticeBarSection({super.key});

  @override
  State<PracticeBarSection> createState() => _PracticeBarSectionState();
}

class _PracticeBarSectionState extends State<PracticeBarSection> {
  bool loading = true;

  bool attemptedToday = false;
  int? todayScore;

  @override
  void initState() {
    super.initState();
    _loadRankedState();
  }

  Future<void> _loadRankedState() async {
    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      attemptedToday = false;
      todayScore = null;
      setState(() => loading = false);
      return;
    }

    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection("daily_leaderboard")
        .doc(todayKey)
        .collection("entries")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      attemptedToday = true;
      todayScore = doc.data()?["score"];
    } else {
      attemptedToday = false;
      todayScore = null;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);

    if (loading) {
      return SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    // Cooldown Timer (Remaining hrs until next quiz)
    String cooldownText = "";
    if (attemptedToday) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final diff = tomorrow.difference(now);
      cooldownText = "Next quiz in ${diff.inHours}h";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCard(context),
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
          // ⭐ Ranked Quiz Card
          _PracticeCard(
            title: attemptedToday
                ? "Today's Ranked Result"
                : "Daily Ranked Quiz",
            subtitle: attemptedToday
                ? "Today's Score: $todayScore"
                : "1 attempt • 150 seconds timer",
            icon: attemptedToday
                ? Icons.leaderboard_rounded
                : Icons.flash_on_rounded,
            color: accent,
            badge: attemptedToday ? cooldownText : null,
            onTap: () async {
              // Not logged in → login
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }

              // Already played today → go to leaderboard (official result)
              if (attemptedToday) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
                return;
              }

              // Not played today → show start popup
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
                  ).then((_) => _loadRankedState());
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // 🧩 Daily Practice Quiz (offline)
          _PracticeCard(
            title: "Daily Practice Quiz",
            subtitle: "Train like ranked — no limits.",
            icon: Icons.school_rounded,
            color: accent,
            onTap: () {
              showQuizEntryPopup(
                context: context,
                title: "Daily Practice Quiz",
                infoLines: [
                  "150 seconds timer",
                  "Score = total correct answers",
                  "Unlimited attempts per day",
                ],
                onStart: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PracticeQuizEntry(),
                    ),
                  );
                },
                showPracticeLink: false,
                showHistoryButton: true,
              );
            },
          ),

          const SizedBox(height: 14),

          // 🔀 Mixed Practice
          _PracticeCard(
            title: "Mixed Practice",
            subtitle: "Customize multiple topics.",
            icon: Icons.shuffle_rounded,
            color: accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MixedQuizSetupScreen()),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 14),

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

                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.18),
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
