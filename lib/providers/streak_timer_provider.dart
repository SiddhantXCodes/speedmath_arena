import 'dart:async';
import 'package:flutter/material.dart';

class StreakTimerProvider extends ChangeNotifier {
  Duration _activeTime = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;

  Duration get activeTime => _activeTime;
  bool get isRunning => _isRunning;

  static const Duration dailyGoal = Duration(minutes: 15);

  void startTracking() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _activeTime += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetDailyProgress() {
    _activeTime = Duration.zero;
    notifyListeners();
  }

  double get progress =>
      (_activeTime.inSeconds / dailyGoal.inSeconds).clamp(0, 1);

  bool get goalReached => _activeTime >= dailyGoal;
}
