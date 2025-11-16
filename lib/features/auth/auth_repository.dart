// lib/features/auth/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 🔐 Handles Firebase authentication & Google sign-in.
class AuthRepository {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  /// -------------------------------------------------------------
  /// 🟢 NORMAL CONSTRUCTOR — Real Firebase for production
  /// -------------------------------------------------------------
  AuthRepository() {
    _auth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn();
  }

  /// -------------------------------------------------------------
  /// 🧪 TEST CONSTRUCTOR — Inject mock FirebaseAuth & GoogleSignIn
  /// -------------------------------------------------------------
  AuthRepository.test(FirebaseAuth mockAuth, [GoogleSignIn? mockGoogle]) {
    _auth = mockAuth;
    _googleSignIn = mockGoogle ?? GoogleSignIn();
  }

  // Stream of user changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Quick access to user
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------
  // EMAIL LOGIN
  // ---------------------------------------------------------------
  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.reload();
    return _auth.currentUser;
  }

  // ---------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------
  Future<User?> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.updateDisplayName(name);
    await cred.user?.reload();
    return _auth.currentUser;
  }

  // ---------------------------------------------------------------
  // RESET PASSWORD
  // ---------------------------------------------------------------
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  // ---------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
