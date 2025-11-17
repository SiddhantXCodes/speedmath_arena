//lib/features/learn_daily/learn_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

class LearnRepository {
  static const _keyPrefix = 'learn_last_seen_';

  Future<void> markReviewed(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${topic.toLowerCase().replaceAll(' ', '_')}';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  Future<DateTime?> lastReviewed(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${topic.toLowerCase().replaceAll(' ', '_')}';
    final s = prefs.getString(key);
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (e) {
      return null;
    }
  }

  Future<bool> reviewedToday(String topic) async {
    final dt = await lastReviewed(topic);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}
