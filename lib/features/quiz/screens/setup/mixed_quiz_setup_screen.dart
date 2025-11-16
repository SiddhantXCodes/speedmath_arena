// lib/features/quiz/screens/setup/mixed_quiz_setup_screen.dart

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

  // Min / Max input
  final TextEditingController minCtrl = TextEditingController(text: "1");
  final TextEditingController maxCtrl = TextEditingController(text: "50");

  // Timer
  bool useTimer = true;
  int timerMinutes = 2; // default 2 min

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Mixed Practice"),
        backgroundColor: accent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TOPICS
          Text(
            "Select Topics",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

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

          // RANGE INPUT
          Text(
            "Number Range",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(context, "Min", accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(context, "Max", accent),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // TIMER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Use Timer?", style: TextStyle(color: textColor)),
              Switch(
                value: useTimer,
                onChanged: (v) => setState(() => useTimer = v),
              ),
            ],
          ),

          if (useTimer) ...[
            Text(
              "Timer Duration: $timerMinutes minutes",
              style: TextStyle(color: textColor),
            ),
            Slider(
              value: timerMinutes.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: accent,
              onChanged: (v) => setState(() => timerMinutes = v.toInt()),
            ),
          ],

          const SizedBox(height: 40),

          // START BUTTON
          ElevatedButton.icon(
            onPressed: selectedTopics.isEmpty
                ? null
                : () {
                    final min = int.tryParse(minCtrl.text) ?? 1;
                    final max = int.tryParse(maxCtrl.text) ?? 50;
                    final seconds = useTimer
                        ? timerMinutes * 60
                        : 150; // fallback

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          title: "Mixed Practice",
                          min: min,
                          max: max,
                          count: 0,
                          mode: QuizMode.practice,
                          timeLimitSeconds: seconds,

                          // ✅ IMPORTANT: Pass topic list to quiz
                          topics: selectedTopics.toList(),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Start Practice"),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context,
  String label,
  Color accent,
) {
  final textColor = AppTheme.adaptiveText(context);
  final surface = Theme.of(context).colorScheme.surfaceVariant;

  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
    filled: true,
    fillColor: surface.withOpacity(0.08),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: textColor.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accent, width: 1.5),
    ),
  );
}
