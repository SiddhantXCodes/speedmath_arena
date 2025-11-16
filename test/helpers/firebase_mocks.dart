// test/helpers/firebase_mocks.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

/// -----------------------------------------------------------
/// 🔥 MOCK CLASSES
/// -----------------------------------------------------------
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Stream<User?> userChanges() => Stream.value(null);

  @override
  User? get currentUser => null;
}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

/// -----------------------------------------------------------
/// 🔥 GLOBAL MOCK INSTANCES
/// -----------------------------------------------------------
late MockFirebaseAuth mockAuth;
late MockGoogleSignIn mockGoogleSignIn;

/// -----------------------------------------------------------
/// 🚀 Initialize mocks (NO Firebase.initializeApp needed)
/// -----------------------------------------------------------
Future<void> setupFirebaseMocks() async {
  mockAuth = MockFirebaseAuth();
  mockGoogleSignIn = MockGoogleSignIn();
}
