// lib/providers/performance_provider.dart

import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../models/daily_score.dart';
import '../features/performance/performance_repository.dart';
import 'dart:developer' as dev;

class PerformanceProvider extends ChangeNotifier {
  final PerformanceRepository _repository = PerformanceRepository();

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------
  Map<DateTime, int> _dailyScores = {};
  Map<String, dynamic>? _leaderboardData;

  bool initialized = false;
  bool _isLoadingLeaderboard = false;

  int _currentStreak = 0; // Firebase-provided only
  int? _todayRank;
  int? _allTimeRank;
  int? _bestScore;

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------
  Map<DateTime, int> get dailyScores => _dailyScores;
  Map<String, dynamic>? get leaderboardData => _leaderboardData;

  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get loading => !initialized;

  int get currentStreak => _currentStreak;
  int? get todayRank => _todayRank;
  int? get allTimeRank => _allTimeRank;
  int? get bestScore => _bestScore;

  int get weeklyAverage {
    if (_dailyScores.isEmpty) return 0;

    final now = DateTime.now();

    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    final used = last7
        .map((d) => _dailyScores[d] ?? 0)
        .where((v) => v > 0)
        .toList();

    if (used.isEmpty) return 0;
    return (used.reduce((a, b) => a + b) / used.length).round();
  }

  // --------------------------------------------------------------------------
  // Constructor
  // --------------------------------------------------------------------------
  PerformanceProvider() {
    _init();
  }

  Future<void> _init() async {
    await reloadAll();
    initialized = true;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Load local cached daily trend ONLY
  // --------------------------------------------------------------------------
  Future<void> loadFromLocal({bool force = false}) async {
    try {
      final items = await _repository.fetchRankedQuizTrend();

      _dailyScores = {
        for (final e in items)
          DateTime(e['date'].year, e['date'].month, e['date'].day): e['score'],
      };

      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ loadFromLocal error: $e");
    }
  }

  // --------------------------------------------------------------------------
  // REMOVE addTodayScore() → Firebase handles this now
  // --------------------------------------------------------------------------
  // (Deleted)

  // --------------------------------------------------------------------------
  // REMOVE all streak writing logic
  // streak now comes ONLY from Firebase
  // --------------------------------------------------------------------------
  // (Deleted _updateStreak, _loadStreak, hasPlayedToday)

  // --------------------------------------------------------------------------
  // Leaderboard (Firebase)
  // --------------------------------------------------------------------------
  Future<void> fetchLeaderboardHeader() async {
    if (_isLoadingLeaderboard) return;

    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      _leaderboardData = await _repository.fetchLeaderboardHeader();

      _todayRank = _leaderboardData?['todayRank'];
      _allTimeRank = _leaderboardData?['allTimeRank'];
      _bestScore = _leaderboardData?['bestScore'];
      _currentStreak = _leaderboardData?['currentStreak'] ?? 0;
    } catch (e) {
      debugPrint("⚠️ Leaderboard fetch error: $e");
    }

    _isLoadingLeaderboard = false;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Online attempts
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchOnlineAttempts({
    int limit = 200,
  }) async {
    try {
      return await _repository.fetchOnlineAttempts(limit: limit);
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Reload all
  // --------------------------------------------------------------------------
  Future<void> reloadAll() async {
    try {
      await loadFromLocal(force: true);
      await fetchLeaderboardHeader();
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ reloadAll error: $e");
    }
  }

  // --------------------------------------------------------------------------
  // Reset
  // --------------------------------------------------------------------------
  Future<void> resetAll() async {
    _dailyScores.clear();
    _leaderboardData = null;

    _currentStreak = 0;
    _todayRank = null;
    _allTimeRank = null;
    _bestScore = null;

    // Clear only the graph data, NOT streak
    try {
      await HiveService.clearDailyScores();
    } catch (_) {}

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Utils
  // --------------------------------------------------------------------------
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
