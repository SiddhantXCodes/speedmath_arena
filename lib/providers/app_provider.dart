// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../services/sync_manager.dart';

class AppProvider extends ChangeNotifier {
  final SyncManager syncManager;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  AppProvider({required this.syncManager});

  Future<void> syncAll() async {
    await syncManager.syncAll();
    notifyListeners();
  }

  void updateNetworkStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }
}
