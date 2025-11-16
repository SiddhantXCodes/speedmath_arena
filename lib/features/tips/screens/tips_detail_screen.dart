//lib/features/tips/screens/tips_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../tips_data.dart';

/// 💡 Dedicated page showing tips for one topic
class TipsDetailScreen extends StatelessWidget {
  final String topic;
  const TipsDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tips = tipsData[topic] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          topic,
          style: TextStyle(
            color: AppTheme.adaptiveText(
              context,
            ), // ✅ uses global adaptive text
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.adaptiveCard(
          context,
        ), // ✅ matches global theme
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppTheme.adaptiveText(
            context,
          ), // ✅ back button color consistent
        ),
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: tips.isEmpty
          ? Center(
              child: Text(
                "No tips available for this topic.",
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
