//lib/features/learn_daily/widgets/learn_topic_list_view.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LearnTopicListView extends StatelessWidget {
  final List<String> items;
  const LearnTopicListView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final accent = AppTheme.adaptiveAccent(context);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isEmpty) return const Divider();
        final parts = item.split('=');
        final left = parts.first.trim();
        final right = parts.length > 1 ? parts.last.trim() : '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCard(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                left,
                style: TextStyle(
                  color: accent,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                right,
                style: TextStyle(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
