//lib/models/quiz_session_model.dart
import 'package:hive/hive.dart';

part 'quiz_session_model.g.dart';

@HiveType(typeId: 4)
class QuizSessionModel extends HiveObject {
  @HiveField(0)
  final String topic;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final int correct;

  @HiveField(3)
  final int incorrect;

  @HiveField(4)
  final int score;

  @HiveField(5)
  final int total;

  @HiveField(6)
  final double avgTime;

  @HiveField(7)
  final int timeSpentSeconds;

  @HiveField(8)
  final List<Map<String, dynamic>> questions;

  @HiveField(9)
  final Map<int, String> userAnswers;

  @HiveField(10)
  final String difficulty; // ✅ Added field

  QuizSessionModel({
    required this.topic,
    required this.category,
    required this.correct,
    required this.incorrect,
    required this.score,
    required this.total,
    required this.avgTime,
    required this.timeSpentSeconds,
    required this.questions,
    required this.userAnswers,
    this.difficulty = 'normal', // ✅ Default difficulty
  });

  factory QuizSessionModel.fromMap(Map<String, dynamic> map) {
    return QuizSessionModel(
      topic: map['topic'] ?? 'Unknown',
      category: map['category'] ?? 'General',
      correct: map['correct'] ?? 0,
      incorrect: map['incorrect'] ?? 0,
      score: map['score'] ?? 0,
      total: map['total'] ?? 10,
      avgTime: (map['avgTime'] ?? 0).toDouble(),
      timeSpentSeconds: map['timeSpentSeconds'] ?? 0,
      questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
      userAnswers: Map<int, String>.from(map['userAnswers'] ?? {}),
      difficulty: map['difficulty'] ?? 'normal', // ✅ Added
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'difficulty': difficulty, // ✅ Added
    };
  }
}
