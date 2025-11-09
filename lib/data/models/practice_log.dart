import 'package:hive/hive.dart';
part 'practice_log.g.dart';

@HiveType(typeId: 0)
class PracticeLog extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String topic;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final int correct;

  @HiveField(4)
  final int incorrect;

  @HiveField(5)
  final int score;

  @HiveField(6)
  final int total;

  @HiveField(7)
  final double avgTime;

  @HiveField(8)
  final int timeSpentSeconds;

  // ✅ make sure types are consistent
  @HiveField(9)
  final List<Map<String, dynamic>> questions;

  @HiveField(10)
  final Map<int, String> userAnswers;

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
    this.questions = const [],
    this.userAnswers = const {},
  });
}
