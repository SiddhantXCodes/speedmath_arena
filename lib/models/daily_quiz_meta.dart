//lib/models/daily_quiz_meta.dart
import 'package:hive/hive.dart';
part 'daily_quiz_meta.g.dart';

@HiveType(typeId: 5)
class DailyQuizMeta extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final int totalQuestions;

  @HiveField(2)
  final int score; // ✅ added field

  @HiveField(3)
  final String difficulty;

  DailyQuizMeta({
    required this.date,
    required this.totalQuestions,
    required this.score,
    required this.difficulty,
  });

  factory DailyQuizMeta.fromMap(Map<String, dynamic> map) => DailyQuizMeta(
    date: map['date'] ?? '',
    totalQuestions: map['totalQuestions'] ?? 0,
    score: map['score'] ?? 0,
    difficulty: map['difficulty'] ?? 'medium',
  );

  Map<String, dynamic> toMap() => {
    'date': date,
    'totalQuestions': totalQuestions,
    'score': score,
    'difficulty': difficulty,
  };
}
