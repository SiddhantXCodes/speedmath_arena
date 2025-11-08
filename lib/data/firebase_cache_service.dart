import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_profile.dart';
import 'models/daily_quiz_meta.dart';
import 'hive_service.dart';

class FirebaseCacheService {
  static final _firestore = FirebaseFirestore.instance;

  /// Fetch user profile once and cache
  static Future<UserProfile?> getUserProfile(String uid) async {
    final cached = HiveService.getUser(uid);
    if (cached != null) return cached;

    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;

    final data = UserProfile.fromMap(snap.data()!);
    HiveService.saveUser(data);
    return data;
  }

  /// Fetch daily quiz metadata once per day
  static Future<DailyQuizMeta?> getDailyQuizMeta(String date) async {
    final cached = HiveService.getDailyQuizMeta(date);
    if (cached != null) return cached;

    final snap = await _firestore.collection('dailyQuiz').doc(date).get();
    if (!snap.exists) return null;

    final meta = DailyQuizMeta.fromMap(snap.data()!);
    HiveService.saveDailyQuizMeta(meta);
    return meta;
  }

  /// Manual refresh (for user-initiated pull-to-refresh)
  static Future<void> refreshUserProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return;
    final user = UserProfile.fromMap(snap.data()!);
    HiveService.saveUser(user);
  }
}
