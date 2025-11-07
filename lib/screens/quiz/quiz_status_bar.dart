// lib/screens/quiz/quiz_status_bar.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class QuizStatusBar extends StatelessWidget {
  final int correct;
  final int incorrect;
  final String timerText;
  final int current;
  final int total;
  final Color textColor;
  final Color cardColor;
  final bool isDark;

  const QuizStatusBar({
    super.key,
    required this.correct,
    required this.incorrect,
    required this.timerText,
    required this.current,
    required this.total,
    required this.textColor,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Global theme-driven colors
    final success = AppTheme.successColor;
    final danger = AppTheme.dangerColor;
    final warning = AppTheme.warningColor;
    final accent = AppTheme.adaptiveAccent(context);

    // Score calculation
    final score = correct * 10;

    // Progress bar styling
    final progressBg = colorScheme.surfaceVariant.withOpacity(
      isDark ? 0.10 : 0.12,
    );
    final progressColor = accent;
    final progressValue = (total > 0) ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.dividerColor.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _iconStatus(Icons.star_rounded, score, accent),
              _iconStatus(Icons.check_circle, correct, success),
              _iconStatus(Icons.cancel, incorrect, danger),
              _iconStatus(Icons.timer, null, warning, time: timerText),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // ✅ Smooth left-to-right progress bar
              _RoundedProgressBar(
                value: progressValue,
                height: 8,
                backgroundColor: progressBg,
                progressColor: progressColor,
                borderRadius: 12,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$current/$total',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconStatus(
    IconData icon,
    int? val,
    Color color, {
    String? time,
    String? label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          time ?? '${val ?? 0}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundedProgressBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final double borderRadius;

  const _RoundedProgressBar({
    Key? key,
    required this.value,
    required this.height,
    required this.backgroundColor,
    required this.progressColor,
    required this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeValue = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        color: backgroundColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * safeValue,
            height: height,
            decoration: BoxDecoration(
              color: progressColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: progressColor.withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
