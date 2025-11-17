// lib/features/home/widgets/practice_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../tips/tips_data.dart';
import '../../tips/screens/tips_detail_screen.dart';

// NEW IMPORTS
import '../../../models/practice_mode.dart';
import '../../quiz/screens/practice_overview_screen.dart';

/// 🎯 Reusable bottom sheet for topic-mode practice setup
/// Supports ONLY: min, max, and time limit (unlimited questions)
Future<void> showPracticeBottomSheet(
  BuildContext context, {
  required String topic,
}) async {
  final textColor = AppTheme.adaptiveText(context);
  final accent = AppTheme.adaptiveAccent(context);
  final theme = Theme.of(context);

  // User inputs
  final minCtrl = TextEditingController(text: '1');
  final maxCtrl = TextEditingController(text: '50');

  double timeLimit = 60; // default 60 sec

  // Fetch tips for that topic
  final allTips = tipsData[topic] ?? [];
  final randomTips = List<String>.from(allTips)..shuffle();
  final shownTips = randomTips.take(2).toList();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.adaptiveCard(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                topic,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              /// Tips list ...
              if (shownTips.isNotEmpty) ...[
                Text(
                  '💡 Quick Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),

                ...shownTips.map(
                  (tip) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_rounded, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// VIEW ALL TIPS
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TipsDetailScreen(topic: topic),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text("View All Tips"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent, width: 1.2),
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: textColor.withOpacity(0.15)),
                const SizedBox(height: 16),
              ],

              /// PRACTICE SETTINGS
              Text(
                'Practice Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        context,
                        'Min number',
                        accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(
                        context,
                        'Max number',
                        accent,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Time Limit: ${timeLimit.toInt()} seconds',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              Slider(
                value: timeLimit,
                min: 10,
                max: 2000,
                divisions: 30,
                activeColor: accent,
                onChanged: (value) => setState(() => timeLimit = value),
              ),

              const SizedBox(height: 16),

              // 🔥🔥🔥 NEW BUTTON ADDED HERE
              /// ---------------------------------------------------------------------
              /// VIEW PRACTICE HISTORY (TOPIC MODE)
              /// ---------------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final mode = PracticeModeX.fromTitle(topic);
                    if (mode != null) {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeOverviewScreen(mode: mode),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("View Practice History"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent, width: 1.2),
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// START PRACTICE BUTTON
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

                    final min = int.tryParse(minCtrl.text) ?? 0;
                    final max = int.tryParse(maxCtrl.text) ?? 100;

                    const unlimitedQuestionCount = 999999;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          title: topic,
                          min: min,
                          max: max,
                          count: unlimitedQuestionCount,
                          mode: QuizMode.practice,
                          timeLimitSeconds: timeLimit.toInt(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Start Practice',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

InputDecoration _inputDecoration(
  BuildContext context,
  String label,
  Color accent,
) {
  final textColor = AppTheme.adaptiveText(context);
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
    filled: true,
    fillColor: colorScheme.surfaceVariant.withOpacity(0.06),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accent, width: 1.5),
    ),
  );
}
