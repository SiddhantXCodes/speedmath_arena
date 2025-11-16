//lib/models/daily_score.dart
import 'package:hive/hive.dart';

part 'daily_score.g.dart';

/// 📊 DailyScore — universal model for score storage.
/// Works for:
/// - Practice Quiz
/// - Ranked Quiz
/// - Mixed Practice
///
/// Used in Hive ONLY (not tied to Firebase now).
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
  final bool isRanked;

  /// 🆕 Strong recommendation: store quiz type
  /// practice | ranked | mixed
  @HiveField(5)
  final String quizType;

  DailyScore({
    required this.date,
    required this.score,
    this.totalQuestions = 0,
    this.timeTakenSeconds = 0,
    this.isRanked = false,
    this.quizType = "practice",
  });

  // ----------------------------------------------------------
  // 🔁 Convert model → Map
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'score': score,
    'totalQuestions': totalQuestions,
    'timeTakenSeconds': timeTakenSeconds,
    'isRanked': isRanked,
    'quizType': quizType,
  };

  // ----------------------------------------------------------
  // 🧩 Convert Map → model (safe & backward compatible)
  // ----------------------------------------------------------
  factory DailyScore.fromMap(Map<String, dynamic> map) {
    final rawScore = map['score'];
    final rawTotal = map['totalQuestions'];
    final rawTime = map['timeTakenSeconds'];
    final rawRanked = map['isRanked'];
    final rawType = map['quizType'];

    return DailyScore(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),

      score: (rawScore is num)
          ? rawScore.toInt()
          : int.tryParse(rawScore?.toString() ?? '0') ?? 0,

      totalQuestions: (rawTotal is num)
          ? rawTotal.toInt()
          : int.tryParse(rawTotal?.toString() ?? '0') ?? 0,

      timeTakenSeconds: (rawTime is num)
          ? rawTime.toInt()
          : int.tryParse(rawTime?.toString() ?? '0') ?? 0,

      isRanked: (rawRanked is bool)
          ? rawRanked
          : (rawRanked?.toString().toLowerCase() == 'true'),

      // ⭐ Backward compatibility: if no quizType → decide automatically
      quizType:
          rawType?.toString() ?? ((rawRanked == true) ? "ranked" : "practice"),
    );
  }

  // ----------------------------------------------------------
  // 🧾 Debug print
  // ----------------------------------------------------------
  @override
  String toString() {
    return 'DailyScore('
        'date: $date, '
        'score: $score, '
        'total: $totalQuestions, '
        'time: $timeTakenSeconds, '
        'ranked: $isRanked, '
        'type: $quizType'
        ')';
  }
}
