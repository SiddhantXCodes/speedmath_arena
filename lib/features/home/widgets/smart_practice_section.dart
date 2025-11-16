//lib/features/home/widgets/smart_practice_section.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../quiz/screens/setup/mixed_quiz_setup_screen.dart';
import '../../quiz/screens/daily_ranked_quiz_entry.dart';
import '../../performance/screens/performance_screen.dart';
import '../../tips/screens/tips_home_screen.dart';

/// 🧠 Smart Practice Section — Displays Daily Ranked, Mixed Practice, Performance & Tips.
class SmartPracticeSection extends StatelessWidget {
  const SmartPracticeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = AppTheme.adaptiveCard(context);

    final smartPractice = [
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Daily Ranked Quiz',
        'subtitle': 'Compete globally in 5 minutes',
        'color': AppTheme.gold.withOpacity(0.18),
      },
      {
        'icon': Icons.loop_rounded,
        'title': 'Mixed Practice',
        'subtitle': 'Variety of random math sets',
        'color': colorScheme.secondary.withOpacity(0.18),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Performance',
        'subtitle': 'Detailed progress insights',
        'color': AppTheme.successColor.withOpacity(0.18),
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Tips & Tricks',
        'subtitle': 'Speed math shortcuts',
        'color': AppTheme.adaptiveAccent(context).withOpacity(0.14),
      },
    ];

    final textColor = AppTheme.adaptiveText(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Practice',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: smartPractice.map((item) {
            return _smartCard(
              context,
              item['icon'] as IconData,
              item['title'] as String,
              item['subtitle'] as String,
              cardColor,
              item['color'] as Color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _smartCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color baseColor,
    Color accentColor,
  ) {
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        switch (title) {
          case 'Daily Ranked Quiz':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyRankedQuizEntry()),
            );
            break;
          case 'Mixed Practice':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MixedQuizSetupScreen()),
            );
            break;
          case 'Performance':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceScreen()),
            );
            break;
          case 'Tips & Tricks':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TipsHomeScreen()),
            );
            break;
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, baseColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.dividerColor.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.72),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
