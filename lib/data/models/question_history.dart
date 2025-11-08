import 'package:hive/hive.dart';
part 'question_history.g.dart';

@HiveType(typeId: 1)
class QuestionHistory {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String userAnswer;

  @HiveField(2)
  final String correctAnswer;

  @HiveField(3)
  final bool isCorrect;

  @HiveField(4)
  final DateTime date;

  QuestionHistory({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.date,
  });
}
