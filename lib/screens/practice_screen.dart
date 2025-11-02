import 'package:flutter/material.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Practice Mode")),
      body: const Center(
        child: Text(
          "Welcome to Practice Mode!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
