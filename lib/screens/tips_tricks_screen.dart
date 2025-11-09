import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TipsAndTricksScreen extends StatefulWidget {
  const TipsAndTricksScreen({super.key});

  @override
  State<TipsAndTricksScreen> createState() => _TipsAndTricksScreenState();
}

class _TipsAndTricksScreenState extends State<TipsAndTricksScreen> {
  final Map<String, List<String>> _tipsData = {
    "Addition": [
      "Add from left to right for faster mental math.",
      "Round up one number and compensate after adding.",
      "Break large numbers into tens and ones.",
      "Use complements: e.g., 98 + 37 → (100 - 2) + 37 = 135.",
    ],
    "Subtraction": [
      "Borrow mentally by rounding up to the nearest 10.",
      "Subtract left to right for better accuracy.",
      "Convert subtraction into addition of negative numbers.",
      "For near multiples of 100: 1000 - 874 = (1000 - 900) + (900 - 874).",
    ],
    "Multiplication": [
      "Use distributive property: (20 + 3) × 7 = 140 + 21.",
      "For numbers near 100: (97 × 96) = (100 - 3)(100 - 4) = 9216.",
      "Multiply by 5 easily: halve the number, then multiply by 10.",
      "Use finger trick for 9× tables (hand method).",
    ],
    "Division": [
      "Estimate first to find approximate quotient quickly.",
      "Double-check by reversing (multiply quotient × divisor).",
      "For dividing by 5, double the number and divide by 10.",
      "Remember divisibility rules (e.g., 3 → sum of digits).",
    ],
    "Squares & Cubes": [
      "Square of numbers ending with 5 → (n×(n+1)) and add 25.",
      "Use (a+b)² = a² + 2ab + b² for near numbers.",
      "Memorize squares and cubes up to 30 for faster answers.",
      "Cube of (a+b): a³ + 3a²b + 3ab² + b³.",
    ],
    "Percentages": [
      "Find 10% by moving one decimal place left.",
      "Find 5% by halving 10%.",
      "1% of a number = divide by 100.",
      "Use 50%, 25%, 10%, 5%, and 1% blocks for quick mental estimates.",
    ],
  };

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tips & Tricks"),
        backgroundColor: accent,
        centerTitle: true,
      ),
      backgroundColor: bgColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _tipsData.keys.length,
        itemBuilder: (context, index) {
          final topic = _tipsData.keys.elementAt(index);
          final tips = _tipsData[topic]!;

          return Card(
            color: cardColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: accent.withOpacity(0.1),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                iconColor: accent,
                collapsedIconColor: textColor.withOpacity(0.6),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  topic,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: tips.map((tip) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 20,
                          color: accent.withOpacity(0.9),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 14.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
