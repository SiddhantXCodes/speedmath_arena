// lib/features/quiz/widgets/quiz_entry_popup.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../screens/practice_quiz_entry.dart';
import '../screens/practice_overview_screen.dart';
import '../../../models/practice_mode.dart';

Future<void> showQuizEntryPopup({
  required BuildContext context,
  required String title,
  required List<String> infoLines,
  required VoidCallback onStart,
  int questionCount = 10,
  int timeSeconds = 60,
  bool showPracticeLink = true, // ranked only
  bool showHistoryButton = false, // daily practice
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.adaptiveCard(context),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final accent = AppTheme.adaptiveAccent(context);
      final textColor = AppTheme.adaptiveText(context);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 16),

              // Info list
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: infoLines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Box: questions + time
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.help_outline, size: 26, color: accent),
                        const SizedBox(height: 6),
                        Text(
                          "$questionCount Questions",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.timer_outlined, size: 26, color: accent),
                        const SizedBox(height: 6),
                        Text(
                          timeSeconds == 0
                              ? "No Time Limit"
                              : "${(timeSeconds / 60).round()} Min",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Start Quiz Primary Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onStart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Start Quiz",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------------------
              //  SECONDARY BUTTON 1: VIEW PAST ATTEMPTS (if enabled)
              // ------------------------------------------------------------------
              if (showHistoryButton)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PracticeOverviewScreen(
                            mode: PracticeMode.dailyPractice,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(
                        color: accent.withOpacity(0.18),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "View Past Attempts",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              if (showHistoryButton) const SizedBox(height: 12),

              // ------------------------------------------------------------------
              //  SECONDARY BUTTON 2: PRACTICE FIRST (same style as above)
              // ------------------------------------------------------------------
              if (showPracticeLink)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PracticeQuizEntry(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(
                        color: accent.withOpacity(0.18),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Not confident? Practice first",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              if (showPracticeLink) const SizedBox(height: 14),

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
