//lib/features/practice/widgets/topic_mode_selector.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// 🧮 TopicModeSelector — lets users choose a sub-mode (Tips, Revision, Practice)
/// Used in Smart Practice or Master Basics flow.
class TopicModeSelector extends StatelessWidget {
  final String topic;

  const TopicModeSelector({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final cardColor = AppTheme.adaptiveCard(context);

    final modes = [
      {'icon': Icons.lightbulb_outline, 'label': 'Tips & Tricks'},
      {'icon': Icons.replay, 'label': 'Revision'},
      {'icon': Icons.play_circle_outline, 'label': 'Practice'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(topic),
        centerTitle: true,
        backgroundColor: accent,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an activity for $topic',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: modes.map((item) {
                  return Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        switch (item['label']) {
                          case 'Tips & Tricks':
                            Navigator.pushNamed(context, '/tips');
                            break;
                          case 'Revision':
                            // Later: navigate to revision mode
                            break;
                          case 'Practice':
                            // Later: show number-of-questions popup or difficulty picker
                            break;
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 40,
                            color: accent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
