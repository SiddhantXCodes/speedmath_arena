//lib/models/daily_score.dart
import 'package:hive/hive.dart';

part 'daily_score.g.dart';

/// 📊 DailyScore — stores a user's daily quiz performance (offline + online)
/// Used for both Hive (offline caching) and Firebase sync.
@HiveType(typeId: 6)
class DailyScore extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int score;

  @HiveField(2)
  final int totalQuestions;

  @HiveField(3)
  final int timeTakenSeconds;

  @HiveField(4)
  final bool isRanked; // true = daily ranked quiz, false = practice quiz

  DailyScore({
    required this.date,
    required this.score,
    this.totalQuestions = 0,
    this.timeTakenSeconds = 0,
    this.isRanked = true,
  });

  // ----------------------------------------------------------
  // 🔁 Convert model → Map (for Firebase/Hive storage)
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'score': score,
    'totalQuestions': totalQuestions,
    'timeTakenSeconds': timeTakenSeconds,
    'isRanked': isRanked,
  };

  // ----------------------------------------------------------
  // 🧩 Convert Map → model (safe backward-compatible parsing)
  // ----------------------------------------------------------
  factory DailyScore.fromMap(Map<String, dynamic> map) {
    dynamic rawScore = map['score'];
    dynamic rawTotal = map['totalQuestions'];
    dynamic rawTime = map['timeTakenSeconds'];
    dynamic rawRanked = map['isRanked'];

    return DailyScore(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),

      // ✅ Safely convert mixed or null values to int
      score: (rawScore is num)
          ? rawScore.toInt()
          : int.tryParse(rawScore?.toString() ?? '0') ?? 0,

      totalQuestions: (rawTotal is num)
          ? rawTotal.toInt()
          : int.tryParse(rawTotal?.toString() ?? '0') ?? 0,

      timeTakenSeconds: (rawTime is num)
          ? rawTime.toInt()
          : int.tryParse(rawTime?.toString() ?? '0') ?? 0,

      // ✅ Safely convert any value to bool (fallback = true)
      isRanked: (rawRanked is bool)
          ? rawRanked
          : (rawRanked?.toString().toLowerCase() == 'true'),
    );
  }

  // ----------------------------------------------------------
  // 🧾 For quick debug prints
  // ----------------------------------------------------------
  @override
  String toString() {
    return 'DailyScore(date: $date, score: $score, total: $totalQuestions, '
        'time: $timeTakenSeconds, ranked: $isRanked)';
  }
}
