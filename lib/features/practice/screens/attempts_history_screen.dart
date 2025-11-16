//lib/features/practice/screens/attempts_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/performance_provider.dart';
import '../../../providers/practice_log_provider.dart';
import '../../../theme/app_theme.dart';

/// 🧾 Combined Attempts History Screen
/// Shows both offline practice + online ranked attempts (merged chronologically).
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

      final offline = practiceProvider.getAllSessions(); // from Hive
      final online = await performanceProvider
          .fetchOnlineAttempts(); // from Firestore

      final all = [...offline, ...online];
      all.sort((a, b) {
        final adate = a['date'] ?? a['timestamp'];
        final bdate = b['date'] ?? b['timestamp'];
        return (bdate ?? DateTime.now()).compareTo(adate ?? DateTime.now());
      });

      setState(() {
        _mergedAttempts = all;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load attempts: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _badgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'daily ranked':
        return Colors.orangeAccent;
      case 'mixed practice':
        return Colors.purpleAccent;
      default:
        return Colors.tealAccent;
    }
  }

  IconData _modeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'daily ranked':
        return Icons.leaderboard_rounded;
      case 'mixed practice':
        return Icons.shuffle_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = AppTheme.adaptiveCard(context);

    return Scaffold(
      backgroundColor: bgColor,
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
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
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
                  final formattedDate = date != null
                      ? DateFormat.yMMMd().add_jm().format(date)
                      : "Unknown";

                  final correct = attempt['correct'] ?? 0;
                  final total = attempt['total'] ?? 0;
                  final type = attempt['category'] ?? 'Practice';
                  final accuracy = total > 0
                      ? ((correct / total) * 100).toStringAsFixed(1)
                      : "0.0";

                  return Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _badgeColor(type).withOpacity(0.25),
                        child: Icon(_modeIcon(type), color: _badgeColor(type)),
                      ),
                      title: Text(
                        attempt['topic'] ?? "Unknown Topic",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "$type  •  $formattedDate",
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$accuracy%",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: correct / total > 0.6
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                          Text(
                            "$correct / $total",
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
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

/// 🧩 Review Individual Attempt — shows all questions + answers
class AttemptReviewScreen extends StatelessWidget {
  final Map<String, dynamic> attempt;
  const AttemptReviewScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final questions = attempt['questions'] as List? ?? [];
    final userAnswers = attempt['userAnswers'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Attempt"),
        backgroundColor: AppTheme.adaptiveAccent(context),
      ),
      backgroundColor: bgColor,
      body: questions.isEmpty
          ? Center(
              child: Text(
                "No detailed data available for this attempt",
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final expr = q is Map
                    ? (q['expression']?.toString() ?? '')
                    : q.toString();
                final correct = q is Map
                    ? (q['correctAnswer']?.toString() ?? '')
                    : '';
                final given = userAnswers[index]?.toString() ?? '';

                final bool isCorrect =
                    correct.isNotEmpty && given.trim() == correct.trim();

                return Card(
                  color: cardColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      expr,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "Your Answer: $given",
                          style: TextStyle(
                            color: isCorrect
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Correct: $correct",
                          style: TextStyle(
                            color: AppTheme.successColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
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
