//lib/features/home/widgets/practice_bar_section.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../quiz/screens/practice_quiz_entry.dart';
import '../../quiz/screens/setup/mixed_quiz_setup_screen.dart';
import 'master_basics_section.dart'; // ✅ Uses your existing widget

/// 🧮 Unified Practice Zone (below Quick Stats)
/// All content enclosed in one full-width card (same width as Quick Stats).
class PracticeBarSection extends StatelessWidget {
  const PracticeBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

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
          // Section Header (like Quick Stats)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Practice Zone",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Optional: link to dedicated practice page
                },
                icon: Icon(Icons.bolt_rounded, color: accent, size: 20),
                label: Text(
                  "Smart Practice",
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🧩 Offline Practice Card
          _PracticeCard(
            title: "Offline Practice",
            subtitle: "Train like ranked — no leaderboard or limits.",
            icon: Icons.school_rounded,
            color: accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeQuizEntry()),
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔀 Mixed Practice Card
          _PracticeCard(
            title: "Mixed Practice",
            subtitle: "Customize and combine multiple topics.",
            icon: Icons.shuffle_rounded,
            color: Colors.tealAccent.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MixedQuizSetupScreen()),
              );
            },
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(height: 24, color: textColor.withOpacity(0.1), thickness: 1),

          const SizedBox(height: 4),

          // 🧠 Master Basics Section
          const MasterBasicsSection(),
        ],
      ),
    );
  }
}

/// 🎯 Individual full-width practice mode card
class _PracticeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
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
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: textColor,
                    ),
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
              color: color.withOpacity(0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
