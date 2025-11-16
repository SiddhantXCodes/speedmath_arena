//lib/models/streak_data.dart
import 'package:hive/hive.dart';
part 'streak_data.g.dart';

@HiveType(typeId: 2)
class StreakData extends HiveObject {
  @HiveField(0)
  final int currentStreak;

  @HiveField(1)
  final DateTime lastActive;

  StreakData({required this.currentStreak, required this.lastActive});
}
