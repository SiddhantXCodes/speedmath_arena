//test/helpers/mocks/mock_google_signin.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleUser extends Mock implements GoogleSignInAccount {}

class MockGoogleAuth extends Mock implements GoogleSignInAuthentication {}
