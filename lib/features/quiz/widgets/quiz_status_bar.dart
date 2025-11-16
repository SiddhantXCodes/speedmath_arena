import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class QuizStatusBar extends StatelessWidget {
  final int correct; // SCORE
  final String timerText; // now plain seconds like "120s"
  final Color textColor;
  final Color cardColor;
  final bool isDark;

  const QuizStatusBar({
    super.key,
    required this.correct,
    required this.timerText,
    required this.textColor,
    required this.cardColor,
    required this.isDark,

    // old unused fields
    required int incorrect,
    required int current,
    required int total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.adaptiveAccent(context);
    final warning = AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.dividerColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ⭐ Score
          Row(
            children: [
              Icon(Icons.star_rounded, color: accent, size: 26),
              const SizedBox(width: 8),
              Text(
                "$correct",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),

          // ⏱ Timer (seconds only)
          Row(
            children: [
              Icon(Icons.timer_rounded, color: warning, size: 24),
              const SizedBox(width: 6),
              Text(
                "$timerText", // 🔥 seconds only
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
