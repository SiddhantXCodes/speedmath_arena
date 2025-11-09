import 'package:hive/hive.dart';
part 'daily_quiz_meta.g.dart';

@HiveType(typeId: 5)
class DailyQuizMeta {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final int totalQuestions;

  @HiveField(2)
  final String difficulty;

  DailyQuizMeta({
    required this.date,
    required this.totalQuestions,
    required this.difficulty,
  });

  factory DailyQuizMeta.fromMap(Map<String, dynamic> map) {
    return DailyQuizMeta(
      date: map['date'],
      totalQuestions: map['totalQuestions'],
      difficulty: map['difficulty'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date,
    'totalQuestions': totalQuestions,
    'difficulty': difficulty,
  };
}
