//lib/features/tips/screens/tips_home_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../tips_data.dart';
import 'tips_detail_screen.dart';

/// 💡 Tips & Tricks — Topic overview page
class TipsHomeScreen extends StatelessWidget {
  const TipsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final topics = tipsData.keys.toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Tips & Tricks"),
        centerTitle: true,
        backgroundColor: accent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TipsDetailScreen(topic: topic),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: accent.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
