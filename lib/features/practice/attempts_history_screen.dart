//lib/features/practice/attempts_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/performance_provider.dart';
import '../../providers/practice_log_provider.dart';
import '../../theme/app_theme.dart';

/// 🧾 Combined Attempts History
/// Merges:
///  - Offline Practice (Hive)
///  - Online Ranked Attempts (Firestore)
/// Sorted newest → oldest
class AttemptsHistoryScreen extends StatefulWidget {
  const AttemptsHistoryScreen({super.key});

  @override
  State<AttemptsHistoryScreen> createState() => _AttemptsHistoryScreenState();
}

class _AttemptsHistoryScreenState extends State<AttemptsHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _mergedAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadAllAttempts();
  }

  Future<void> _loadAllAttempts() async {
    try {
      final practiceProvider = context.read<PracticeLogProvider>();
      final performanceProvider = context.read<PerformanceProvider>();

      final offline = practiceProvider.getAllSessions(); // Hive
      final online = await performanceProvider
          .fetchOnlineAttempts(); // Firestore

      final all = [...offline, ...online];

      all.sort((a, b) {
        final ad = a['date'] ?? a['timestamp'];
        final bd = b['date'] ?? b['timestamp'];

        if (ad is DateTime && bd is DateTime) {
          return bd.compareTo(ad);
        }
        return 0;
      });

      setState(() {
        _mergedAttempts = all;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Failed loading attempts: $e');
      setState(() => _isLoading = false);
    }
  }

  // MODE BADGES
  Color _badgeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains("ranked")) return Colors.orangeAccent;
    if (t.contains("mixed")) return Colors.purpleAccent;
    return Colors.tealAccent;
  }

  IconData _modeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains("ranked")) return Icons.leaderboard_rounded;
    if (t.contains("mixed")) return Icons.shuffle_rounded;
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Attempts History"),
        centerTitle: true,
        backgroundColor: accent,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            )
          : _mergedAttempts.isEmpty
          ? Center(
              child: Text(
                "No attempts found yet",
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllAttempts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _mergedAttempts.length,
                itemBuilder: (context, index) {
                  final attempt = _mergedAttempts[index];

                  final date = attempt['date'] ?? attempt['timestamp'];
                  final formatted = (date is DateTime)
                      ? DateFormat.yMMMd().add_jm().format(date)
                      : "Unknown date";

                  final correct = attempt['correct'] ?? 0;
                  final total = attempt['total'] ?? 0;

                  final type = attempt['category']?.toString() ?? "Practice";
                  final accuracy = total > 0
                      ? ((correct / total) * 100).toStringAsFixed(1)
                      : "0.0";

                  return Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _badgeColor(type).withOpacity(0.25),
                        child: Icon(_modeIcon(type), color: _badgeColor(type)),
                      ),
                      title: Text(
                        attempt['topic'] ?? "Unknown Topic",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        "$type  •  $formatted",
                        style: TextStyle(color: textColor.withOpacity(0.6)),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$accuracy%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (correct / (total == 0 ? 1 : total)) >= 0.6
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                          Text(
                            "$correct / $total",
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AttemptReviewScreen(attempt: attempt),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// REVIEW SCREEN — shows all questions + answers
class AttemptReviewScreen extends StatelessWidget {
  final Map<String, dynamic> attempt;

  const AttemptReviewScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

    final questions = attempt['questions'] as List? ?? [];
    final answers = attempt['userAnswers'] ?? {};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Review Attempt"),
        backgroundColor: AppTheme.adaptiveAccent(context),
      ),
      body: questions.isEmpty
          ? Center(
              child: Text(
                "No detailed data for this attempt",
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];

                final expression = q is Map
                    ? q['expression']?.toString()
                    : q.toString();
                final correct = q is Map ? q['correctAnswer']?.toString() : "";
                final userAns = answers[index]?.toString() ?? "";

                final isCorrect = userAns.trim() == (correct?.trim() ?? "");

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      expression ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          "Your Answer: $userAns",
                          style: TextStyle(
                            color: isCorrect
                                ? AppTheme.successColor
                                : AppTheme.dangerColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Correct: $correct",
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
