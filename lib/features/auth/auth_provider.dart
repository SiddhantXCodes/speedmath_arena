// lib/features/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';
import '../../providers/performance_provider.dart';
import 'package:provider/provider.dart';

/// 🧠 AuthProvider bridges UI and AuthRepository.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    // 🔥 Listen to Firebase user changes in REAL-TIME
    _repo.userChanges.listen((firebaseUser) {
      _user = firebaseUser;
      notifyListeners(); // keeps UI synced with login state
    });
  }

  // --------------------------------------------------------------------------
  // 🔐 LOGIN
  // --------------------------------------------------------------------------
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    _setLoading(true);
    try {
      await _repo.signInWithEmail(email, password);

      // 🔥 Sync performance after login
      await context.read<PerformanceProvider>().reloadAll();
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // 🆕 REGISTER
  // --------------------------------------------------------------------------
  Future<void> register(
    String name,
    String email,
    String password,
    BuildContext context,
  ) async {
    _setLoading(true);
    try {
      await _repo.registerWithEmail(name, email, password);

      // 🔥 Load performance for newly created user
      await context.read<PerformanceProvider>().reloadAll();
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // 🔐 GOOGLE AUTH
  // --------------------------------------------------------------------------
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      await _repo.signInWithGoogle();

      // 🔥 Sync after login
      await context.read<PerformanceProvider>().reloadAll();
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // 🔐 RESET PASSWORD
  // --------------------------------------------------------------------------
  Future<void> resetPassword(String email) => _repo.sendPasswordReset(email);

  // --------------------------------------------------------------------------
  // 🚪 LOGOUT
  // --------------------------------------------------------------------------
  Future<void> logout(BuildContext context) async {
    // 🔥 Reset local streak & all performance data FIRST
    context.read<PerformanceProvider>().resetAll();

    // 🔥 Then sign out user
    await _repo.signOut();

    _user = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // INTERNAL
  // --------------------------------------------------------------------------
  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
