// test/helpers/test_app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_mocks.dart';

import 'package:speedmaths_pro/app.dart';
import 'package:speedmaths_pro/providers/theme_provider.dart';
import 'package:speedmaths_pro/features/auth/auth_provider.dart' as sm;
import 'package:speedmaths_pro/providers/practice_log_provider.dart';
import 'package:speedmaths_pro/providers/performance_provider.dart';
import 'package:speedmaths_pro/features/performance/performance_repository.dart';
import 'package:speedmaths_pro/features/practice/practice_repository.dart';
import 'package:speedmaths_pro/models/practice_log.dart';

/// Create testable SpeedMathApp with mocked dependencies
Widget createTestApp() {
  final mockPerformanceRepo = _MockPerformanceRepository();
  final mockPracticeRepo = _MockPracticeRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(
        create: (_) => sm.AuthProvider.test(mockAuth, mockGoogleSignIn),
      ),
      ChangeNotifierProvider(
        create: (_) => PracticeLogProvider.test(mockPracticeRepo),
      ),
      ChangeNotifierProvider(
        create: (_) => PerformanceProvider.test(mockPerformanceRepo),
      ),
    ],
    child: const SpeedMathApp(),
  );
}

/// Mock PerformanceRepository - returns dummy data without Firebase
class _MockPerformanceRepository implements PerformanceRepository {
  @override
  Future<Map<String, dynamic>> fetchLeaderboardHeader() async {
    return {
      'todayRank': 1,
      'allTimeRank': 10,
      'bestScore': 50,
      'currentStreak': 5,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRankedQuizTrend() async {
    return [
      {'date': DateTime.now(), 'score': 10, 'isRanked': true},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOnlineAttempts({
    int limit = 200,
  }) async {
    return [];
  }

  @override
  Future<void> saveDailyScore(score) async {
    // No-op in tests
  }

  @override
  Future<void> syncData() async {
    // No-op in tests
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock PracticeRepository - returns empty data without Firebase
class _MockPracticeRepository implements PracticeRepository {
  @override
  List<PracticeLog> getAllLocalSessions() => [];

  @override
  Map<DateTime, int> getActivityMapFromHive() => {};

  @override
  Future<void> savePracticeSession(PracticeLog log) async {}

  @override
  Future<int> syncPendingSessions() async => 0; // 🔥 Returns int, not void

  @override
  Future<void> clearAllLocalData() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
