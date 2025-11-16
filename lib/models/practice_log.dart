//lib/models/practice_log.dart
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

  factory PracticeLog.fromMap(Map<String, dynamic> map) => PracticeLog(
    date: DateTime.parse(map['date']),
    topic: map['topic'] ?? 'Unknown',
    category: map['category'] ?? 'General',
    correct: map['correct'] ?? 0,
    incorrect: map['incorrect'] ?? 0,
    score: map['score'] ?? 0,
    total: map['total'] ?? 0,
    avgTime: (map['avgTime'] ?? 0.0).toDouble(),
    timeSpentSeconds: map['timeSpentSeconds'] ?? 0,
    questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
    userAnswers: Map<int, String>.from(map['userAnswers'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'topic': topic,
    'category': category,
    'correct': correct,
    'incorrect': incorrect,
    'score': score,
    'total': total,
    'avgTime': avgTime,
    'timeSpentSeconds': timeSpentSeconds,
    'questions': questions,
    'userAnswers': userAnswers,
  };
}
