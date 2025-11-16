//lib/features/quiz/screens/setup/mixed_quiz_setup_screen.dart
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../quiz_screen.dart';

class MixedQuizSetupScreen extends StatefulWidget {
  const MixedQuizSetupScreen({super.key});

  @override
  State<MixedQuizSetupScreen> createState() => _MixedQuizSetupScreenState();
}

class _MixedQuizSetupScreenState extends State<MixedQuizSetupScreen> {
  final List<String> allTopics = const [
    "Addition",
    "Subtraction",
    "Multiplication",
    "Division",
    "Squares",
    "Cubes",
    "Square Root",
    "Cube Root",
    "Percentage",
    "Average",
  ];

  final Set<String> selectedTopics = {};
  bool useTimer = false;
  int timerMinutes = 2;
  int numQuestions = 20;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Mixed Practice"),
        backgroundColor: accent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Select Topics",
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Topic Selection Chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allTopics.map((topic) {
                final selected = selectedTopics.contains(topic);
                return ChoiceChip(
                  label: Text(topic),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        selectedTopics.add(topic);
                      } else {
                        selectedTopics.remove(topic);
                      }
                    });
                  },
                  selectedColor: accent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selected ? accent : textColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ⏱ Timer Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Use Timer", style: TextStyle(color: textColor)),
                Switch(
                  value: useTimer,
                  onChanged: (v) => setState(() => useTimer = v),
                ),
              ],
            ),
            if (useTimer)
              Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Timer Duration: $timerMinutes min",
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: timerMinutes.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: "$timerMinutes min",
                    onChanged: (v) => setState(() => timerMinutes = v.toInt()),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // 📊 Question Count
            Text(
              "Number of Questions: $numQuestions",
              style: TextStyle(color: textColor),
            ),
            Slider(
              value: numQuestions.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: "$numQuestions",
              onChanged: (v) => setState(() => numQuestions = v.toInt()),
            ),

            const SizedBox(height: 30),

            // ▶️ Start Button
            ElevatedButton.icon(
              onPressed: selectedTopics.isEmpty
                  ? null
                  : () async {
                      // 🧠 Navigate to unified QuizScreen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            title: "Mixed Practice",
                            min: 1,
                            max: 50,
                            count: numQuestions,
                            mode: QuizMode.practice,
                            timeLimitSeconds: useTimer ? timerMinutes * 60 : 0,
                            onFinish: (_) async {
                              // optional async safe callback
                              return;
                            },
                          ),
                        ),
                      );

                      // Add a return statement so analyzer knows it can't "fall through"
                      return;
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Start Practice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
