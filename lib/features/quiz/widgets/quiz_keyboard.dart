//lib/features/quiz/widgets/quiz_keyboard.dart
import 'package:flutter/material.dart';

class QuizKeyboard extends StatelessWidget {
  final bool autoSubmit;
  final bool isDark;
  final Color primary;
  final Function(String) onKeyTap;
  final VoidCallback onSubmit;
  final bool isReversed;

  const QuizKeyboard({
    super.key,
    required this.autoSubmit,
    required this.isDark,
    required this.primary,
    required this.onKeyTap,
    required this.onSubmit,
    required this.isReversed,
  });

  @override
  Widget build(BuildContext context) {
    final normal = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'BACK'],
    ];
    final reversed = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', 'BACK'],
    ];
    final grid = isReversed ? reversed : normal;

    return Column(
      children: [
        if (!autoSubmit)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: onSubmit,
              icon: const Icon(Icons.send, size: 16, color: Colors.white),
              label: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...grid.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: row.map((key) {
                final isBack = key == 'BACK';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBack
                            ? (isDark ? Colors.grey[300] : Colors.grey[200])
                            : primary.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => onKeyTap(isBack ? 'BACK' : key),
                      child: isBack
                          ? Icon(
                              Icons.backspace_outlined,
                              color: isDark ? Colors.black : Colors.black87,
                            )
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
