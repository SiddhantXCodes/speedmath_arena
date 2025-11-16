// lib/features/auth/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_repository.dart';
import '../../providers/performance_provider.dart';

/// 🧠 AuthProvider bridges UI and AuthRepository.
class AuthProvider extends ChangeNotifier {
  late final AuthRepository _repo;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null; // 🔥 Added for test compatibility

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // --------------------------------------------------------------------------
  // 🔥 REAL CONSTRUCTOR (USED BY NORMAL APP)
  // --------------------------------------------------------------------------
  AuthProvider() {
    _repo = AuthRepository();
    _listenToUser();
  }

  // -------------------------------------------------------------
  // 🧪 TEST CONSTRUCTOR — used only inside Flutter tests
  // -------------------------------------------------------------
  AuthProvider.test(FirebaseAuth mockAuth, GoogleSignIn mockGoogle) {
    _repo = AuthRepository.test(mockAuth, mockGoogle);
    _listenToUser();
  }

  // --------------------------------------------------------------------------
  // 🔁 INTERNAL: listen to auth state changes
  // --------------------------------------------------------------------------
  void _listenToUser() {
    _repo.userChanges.listen((firebaseUser) {
      _user = firebaseUser;
      notifyListeners();
    });
  }

  // --------------------------------------------------------------------------
  // 🔐 LOGIN (with optional BuildContext for production, not required in tests)
  // --------------------------------------------------------------------------
  Future<void> login(
    String email,
    String password, [
    BuildContext? context,
  ]) async {
    _setLoading(true);
    _error = null; // Clear previous errors

    try {
      await _repo.signInWithEmail(email, password);

      // Only reload performance if context is provided (production)
      if (context != null && context.mounted) {
        await context.read<PerformanceProvider>().reloadAll();
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
      rethrow; // 🔥 Rethrow so tests can catch it
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
    String password, [
    BuildContext? context,
  ]) async {
    _setLoading(true);
    _error = null;

    try {
      await _repo.registerWithEmail(name, email, password);

      if (context != null && context.mounted) {
        await context.read<PerformanceProvider>().reloadAll();
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // 🔐 GOOGLE AUTH
  // --------------------------------------------------------------------------
  Future<void> loginWithGoogle([BuildContext? context]) async {
    _setLoading(true);
    _error = null;

    try {
      await _repo.signInWithGoogle();

      if (context != null && context.mounted) {
        await context.read<PerformanceProvider>().reloadAll();
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // 🔐 RESET PASSWORD
  // --------------------------------------------------------------------------
  Future<void> resetPassword(String email) => _repo.sendPasswordReset(email);

  // --------------------------------------------------------------------------
  // 🚪 LOGOUT (with optional BuildContext)
  // --------------------------------------------------------------------------
  Future<void> logout([BuildContext? context]) async {
    if (context != null && context.mounted) {
      await context.read<PerformanceProvider>().resetAll();
    }

    await _repo.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // 🔧 INTERNAL
  // --------------------------------------------------------------------------
  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }
}
