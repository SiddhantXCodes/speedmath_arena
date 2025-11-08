import 'package:hive/hive.dart';
part 'practice_log.g.dart';

@HiveType(typeId: 0)
class PracticeLog {
  @HiveField(0)
  final DateTime date;

  /// e.g. "Addition", "Subtraction", "Daily Ranked Quiz"
  @HiveField(1)
  final String topic;

  /// e.g. "Basics", "Mixed", "Ranked"
  @HiveField(2)
  final String category;

  @HiveField(3)
  final int correct;

  @HiveField(4)
  final int incorrect;

  /// Total score achieved in that session
  @HiveField(5)
  final int score;

  /// Total number of questions attempted
  @HiveField(6)
  final int total;

  /// Average time spent per question (in seconds)
  @HiveField(7)
  final double avgTime;

  /// Total time spent on the session (in seconds)
  @HiveField(8)
  final int timeSpentSeconds;

  PracticeLog({
    required this.date,
    required this.topic,
    required this.category,
    required this.correct,
    required this.incorrect,
    required this.score,
    required this.total,
    required this.avgTime,
    required this.timeSpentSeconds,
  });
}
