import 'package:hive/hive.dart';

part 'daily_score.g.dart';

@HiveType(typeId: 6)
class DailyScore extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int score;

  DailyScore({required this.date, required this.score});
}
