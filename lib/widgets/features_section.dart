import 'package:flutter/material.dart';
import '../screens/number_of_questions_selector_popup.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/daily_ranked_quiz_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../theme/app_theme.dart';

class FeaturesSection extends StatelessWidget {
  final bool isDarkMode;

  const FeaturesSection({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // Theme-driven tokens (use these everywhere)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = AppTheme.adaptiveText(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = AppTheme.adaptiveCard(context);
    final accent = AppTheme.adaptiveAccent(context);
    final divider = theme.dividerColor;

    // Smart practice cards: keep semantic meanings but use theme tokens
    final smartPractice = [
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'Daily Ranked Quiz',
        'subtitle': 'Compete globally in 5 min',
        // gold-like highlight for leaderboard
        'color': AppTheme.gold.withOpacity(0.18),
      },
      {
        'icon': Icons.loop_rounded,
        'title': 'Mixed Practice',
        'subtitle': 'Variety of random math sets',
        // use secondary color for variety card
        'color': colorScheme.secondary.withOpacity(0.18),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Performance',
        'subtitle': 'Detailed progress insights',
        // success token
        'color': AppTheme.successColor.withOpacity(0.18),
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Tips & Tricks',
        'subtitle': 'Speed math shortcuts',
        // use accent but slightly muted
        'color': accent.withOpacity(0.14),
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'Streak Challenge',
        'subtitle': 'Maintain daily practice',
        // warning / energetic color
        'color': AppTheme.warningColor.withOpacity(0.18),
      },
    ];

    final basics = [
      {'icon': Icons.add, 'title': 'Addition'},
      {'icon': Icons.remove, 'title': 'Subtraction'},
      {'icon': Icons.clear, 'title': 'Multiplication'},
      {'icon': Icons.percent, 'title': 'Division'},
      {'icon': Icons.calculate, 'title': 'Percentage'},
      {'icon': Icons.show_chart, 'title': 'Average'},
      {'icon': Icons.square_foot, 'title': 'Square'},
      {'icon': Icons.widgets_outlined, 'title': 'Cube'},
      {'icon': Icons.square_outlined, 'title': 'Square Root'},
      {'icon': Icons.data_exploration, 'title': 'Cube Root'},
      {'icon': Icons.terrain, 'title': 'Trigonometry'},
      {'icon': Icons.table_chart, 'title': 'Tables'},
      {'icon': Icons.insights, 'title': 'Data Interpretation'},
      {'icon': Icons.category_rounded, 'title': 'Mixed Questions'},
    ];

    return SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 20),
          Text(
            'Master Basics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildGrid(context, basics, scaffoldBg),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // ✅ Bottom sheet for number range & question count
  // -----------------------------------------------
  void _showPracticeDialog(BuildContext context, String topic) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);
    final fill = colorScheme.surfaceVariant.withOpacity(0.06);
    final outline = colorScheme.onSurface.withOpacity(0.12);

    final TextEditingController minCtrl = TextEditingController(text: '5');
    final TextEditingController maxCtrl = TextEditingController(text: '30');
    double questionCount = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.adaptiveCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Practice $topic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Range input fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Min number',
                          labelStyle: TextStyle(
                            color: textColor.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: fill,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Max number',
                          labelStyle: TextStyle(
                            color: textColor.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: fill,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question count slider
                Text(
                  'Number of Questions: ${questionCount.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Slider(
                  value: questionCount,
                  min: 5,
                  max: 30,
                  divisions: 5,
                  activeColor: accent,
                  onChanged: (value) {
                    setState(() => questionCount = value);
                  },
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final int min = int.tryParse(minCtrl.text) ?? 0;
                      final int max = int.tryParse(maxCtrl.text) ?? 100;
                      final int count = questionCount.toInt();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            title: topic,
                            min: min,
                            max: max,
                            count: count,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Start Practice',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------
  // ✅ Grid for Master Basics with dialog trigger
  // -----------------------------------------------
  Widget _buildGrid(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Color? bgColor,
  ) {
    final theme = Theme.of(context);
    final cardFill = theme.cardColor;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items.map((item) {
        return _featureTile(
          context,
          item['icon'] as IconData,
          item['title'] as String,
          cardFill,
        );
      }).toList(),
    );
  }

  Widget _featureTile(
    BuildContext context,
    IconData icon,
    String title,
    Color? bgColor,
  ) {
    final theme = Theme.of(context);
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);

    return InkWell(
      onTap: () {
        _showPracticeDialog(context, title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.dividerColor.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: accent),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // smart cards stay same visually but theme-driven
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
        // ✅ Launch Daily Ranked Quiz directly
        if (title == 'Daily Ranked Quiz') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyRankedQuizScreen()),
          );
          return;
        }
        // ✅ Launch Leaderboard for Performance card
        if (title == 'Performance') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          );
          return;
        }
        // Otherwise, keep existing logic
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FeatureDetailScreen(title: title)),
        );
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
            Icon(icon, size: 28, color: AppTheme.adaptiveAccent(context)),
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
