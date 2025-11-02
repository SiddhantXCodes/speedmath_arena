import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speedmath_arena/screens/battle_screen.dart' as battle;
import 'package:speedmath_arena/screens/login_screen.dart' as login;
import 'package:speedmath_arena/screens/practice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void handleBattleTap(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const login.LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const battle.BattleScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SpeedMath Arena")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
                // Offline Practice Mode - no login needed
              },
              child: const Text("Practice Mode 🧮"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => handleBattleTap(context),
              child: const Text("Leaderboard Battle 🏆"),
            ),
          ],
        ),
      ),
    );
  }
}
