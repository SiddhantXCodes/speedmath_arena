// lib/providers/performance_provider.dart

import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../features/performance/performance_repository.dart';

class PerformanceProvider extends ChangeNotifier {
  late final PerformanceRepository _repository;

  // --------------------------------------------------------------------------
  // 🔥 NORMAL CONSTRUCTOR (Production)
  // --------------------------------------------------------------------------
  PerformanceProvider() {
    _repository = PerformanceRepository();
    _init();
  }

  // --------------------------------------------------------------------------
  // 🧪 TEST CONSTRUCTOR (Injected Mock PerformanceRepository)
  // --------------------------------------------------------------------------
  PerformanceProvider.test(PerformanceRepository mockRepo) {
    _repository = mockRepo;
    initialized = true;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------
  Map<DateTime, int> _dailyScores = {}; // date → score
  Map<String, dynamic>? _leaderboardData;

  bool initialized = false;
  bool _isLoadingLeaderboard = false;

  int _currentStreak = 0;
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

  int get currentStreak => _currentStreak; // Ranked only
  int? get todayRank => _todayRank;
  int? get allTimeRank => _allTimeRank;
  int? get bestScore => _bestScore;

  // Weekly average of scores
  int get weeklyAverage {
    if (_dailyScores.isEmpty) return 0;

    final now = DateTime.now();

    final last7days = List.generate(7, (index) {
      final d = now.subtract(Duration(days: index));
      return DateTime(d.year, d.month, d.day);
    });

    final used = last7days
        .map((d) => _dailyScores[d] ?? 0)
        .where((score) => score > 0)
        .toList();

    if (used.isEmpty) return 0;

    final avg = used.reduce((a, b) => a + b) / used.length;
    return avg.round();
  }

  // --------------------------------------------------------------------------
  // Initialization
  // --------------------------------------------------------------------------
  Future<void> _init() async {
    await reloadAll();
    initialized = true;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Load local daily scores only (offline practice + ranked cache)
  // --------------------------------------------------------------------------
  Future<void> loadFromLocal({bool force = false}) async {
    try {
      // Fetch new "score-only" trend data
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
  // Leaderboard summary from Firebase (today rank, best score, streak, etc.)
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
  // Fetch list of online attempts (ranked attempts)
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
  // Reload both offline + online data
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
  // Reset (clear local)
  // --------------------------------------------------------------------------
  Future<void> resetAll() async {
    _dailyScores.clear();
    _leaderboardData = null;

    _currentStreak = 0;
    _todayRank = null;
    _allTimeRank = null;
    _bestScore = null;

    try {
      await HiveService.clearDailyScores();
    } catch (e) {
      debugPrint("⚠️ resetAll error: $e");
    }

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // ✔ TEST SUPPORT
  // --------------------------------------------------------------------------
  void testMarkInitialized() {
    initialized = true;
    notifyListeners();
  }
}
