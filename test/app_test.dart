// test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'helpers/firebase_mocks.dart'; // ✅ correct path
import 'helpers/test_app.dart'; // ✅ correct path

import 'package:speedmaths_pro/features/home/screens/home_screen.dart';

void main() {
  // ------------------------------------------------------------
  // 🔥 Initialize all Firebase mocks before ANY test runs
  // ------------------------------------------------------------
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupFirebaseMocks();
  });

  testWidgets(
    "🚀 Full App Launch → SpeedMathApp loads and HomeScreen appears",
    (tester) async {
      // Load entire app
      await tester.pumpWidget(createTestApp());

      // Give providers time to initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // HomeScreen must appear
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
