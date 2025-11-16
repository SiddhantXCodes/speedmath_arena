// test/auth/auth_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:speedmaths_pro/features/auth/auth_provider.dart' as sm;
import 'auth_provider_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential, GoogleSignIn])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogle;
  late MockUser mockUser;
  late MockUserCredential mockCred;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogle = MockGoogleSignIn();
    mockUser = MockUser();
    mockCred = MockUserCredential();

    // 🔥 Setup default stubs to prevent MissingStubError
    when(
      mockAuth.authStateChanges(),
    ).thenAnswer((_) => Stream<User?>.value(null));
    when(mockAuth.currentUser).thenReturn(null);
  });

  group("🔥 AuthProvider Tests", () {
    test("Initial state → user = null, loading = false", () {
      final provider = sm.AuthProvider.test(mockAuth, mockGoogle);

      expect(provider.user, null);
      expect(provider.loading, false);
    });

    test("authStateChanges emits → provider updates user", () async {
      when(
        mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.value(mockUser));

      final provider = sm.AuthProvider.test(mockAuth, mockGoogle);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.user, mockUser);
      expect(provider.isAuthenticated, true);
    });

    test("login() → calls FirebaseAuth.signInWithEmailAndPassword", () async {
      when(mockCred.user).thenReturn(mockUser);
      when(
        mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockCred);

      // 🔥 Update authStateChanges to emit the mockUser after login
      when(
        mockAuth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.value(mockUser));

      final provider = sm.AuthProvider.test(mockAuth, mockGoogle);

      // Call login WITHOUT context (optional parameter)
      await provider.login("test@mail.com", "pass123");

      // Give the stream time to emit
      await Future.delayed(const Duration(milliseconds: 100));

      verify(
        mockAuth.signInWithEmailAndPassword(
          email: "test@mail.com",
          password: "pass123",
        ),
      ).called(1);

      expect(provider.user, mockUser);
      expect(provider.loading, false);
      expect(provider.error, isNull);
    });

    test(
      "login() throws FirebaseAuthException → sets provider.error",
      () async {
        when(
          mockAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: "wrong-password",
            message: "Incorrect password",
          ),
        );

        final provider = sm.AuthProvider.test(mockAuth, mockGoogle);

        try {
          await provider.login("wrong@mail.com", "bad");
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 50));

        expect(provider.error, isNotNull);
        expect(provider.user, null);
      },
    );

    test("logout() → calls FirebaseAuth.signOut()", () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});
      when(mockGoogle.signOut()).thenAnswer((_) async => null);

      final provider = sm.AuthProvider.test(mockAuth, mockGoogle);

      // Call logout WITHOUT context (optional parameter)
      await provider.logout();

      verify(mockAuth.signOut()).called(1);
      expect(provider.user, isNull);
    });
  });
}
