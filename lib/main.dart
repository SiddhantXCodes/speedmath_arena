import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SpeedMathArenaApp());
}

class SpeedMathArenaApp extends StatelessWidget {
  const SpeedMathArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeedMath Arena',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(), // 👈 starting screen
    );
  }
}
