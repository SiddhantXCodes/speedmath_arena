//lib/features/home/home_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/hive_service.dart';

/// Handles reading home screen–related data from Firebase + Hive.
class HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get local practice activity map from Hive
  Map<DateTime, int> getLocalActivity() => HiveService.getActivityMap();

  /// Get today's leaderboard data (for quick stats)
  Future<Map<String, dynamic>?> fetchTodayLeaderboard(String dateKey) async {
    try {
      final ref = _firestore
          .collection('daily_leaderboard')
          .doc(dateKey)
          .collection('entries');
      final snap = await ref.orderBy('score', descending: true).get();
      return {'entries': snap.docs.map((d) => d.data()).toList()};
    } catch (_) {
      return null;
    }
  }
}
