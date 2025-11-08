import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/streak_data.dart';
import '../data/hive_service.dart';

class StreakTimerProvider extends ChangeNotifier {
  Duration _activeTime = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;
  int _currentStreak = 0;
  DateTime? _lastActiveDate;

  Duration get activeTime => _activeTime;
  bool get isRunning => _isRunning;
  int get currentStreak => _currentStreak;

  static const Duration dailyGoal = Duration(minutes: 15);

  StreakTimerProvider() {
    _loadStreakData();
  }

  // ----------------------------------------
  // Load streak data from Hive
  // ----------------------------------------
  Future<void> _loadStreakData() async {
    final stored = HiveService.getStreak();
    if (stored != null) {
      _currentStreak = stored.currentStreak;
      _lastActiveDate = stored.lastActive;
    }

    // Reset daily progress if new day
    final now = DateTime.now();
    if (_lastActiveDate == null || !_isSameDay(now, _lastActiveDate!)) {
      _activeTime = Duration.zero;
    }

    notifyListeners();
  }

  // ----------------------------------------
  // Start tracking active session time
  // ----------------------------------------
  void startTracking() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeTime += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  // ----------------------------------------
  // Stop tracking & save streak
  // ----------------------------------------
  void stopTracking() {
    _timer?.cancel();
    _isRunning = false;
    _updateStreak();
    notifyListeners();
  }

  // ----------------------------------------
  // Manual reset for debugging/testing
  // ----------------------------------------
  Future<void> resetDailyProgress() async {
    _activeTime = Duration.zero;
    await HiveService.saveStreak(
      StreakData(currentStreak: _currentStreak, lastActive: DateTime.now()),
    );
    notifyListeners();
  }

  // ----------------------------------------
  // Save or update streak based on day logic
  // ----------------------------------------
  Future<void> _updateStreak() async {
    final now = DateTime.now();

    if (_lastActiveDate != null && _isSameDay(now, _lastActiveDate!)) {
      await HiveService.saveStreak(
        StreakData(currentStreak: _currentStreak, lastActive: now),
      );
      return;
    }

    if (_lastActiveDate != null && _isYesterday(now, _lastActiveDate!)) {
      _currentStreak += 1;
    } else {
      _currentStreak = 1;
    }

    _lastActiveDate = now;
    await HiveService.saveStreak(
      StreakData(currentStreak: _currentStreak, lastActive: now),
    );
  }

  // ----------------------------------------
  // Utility helpers
  // ----------------------------------------
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isYesterday(DateTime today, DateTime last) {
    final y = today.subtract(const Duration(days: 1));
    return _isSameDay(y, last);
  }

  double get progress =>
      (_activeTime.inSeconds / dailyGoal.inSeconds).clamp(0, 1);

  bool get goalReached => _activeTime >= dailyGoal;
}
