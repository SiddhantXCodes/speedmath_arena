// lib/features/learn_daily/learn_daily_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../learn_tile.dart';
import 'learn_detail_screen.dart';
import '../../../theme/app_theme.dart';

class LearnDailyScreen extends StatefulWidget {
  const LearnDailyScreen({super.key});

  @override
  State<LearnDailyScreen> createState() => _LearnDailyScreenState();
}

class _LearnDailyScreenState extends State<LearnDailyScreen> {
  Future<void> _refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final width = MediaQuery.of(context).size.width;

    final isPhone = width < 600;
    final isTablet = width >= 600 && width < 900;
    final isBigTablet = width >= 900;

    final double horizontalPad = isBigTablet ? width * 0.18 : 16;
    final double topSpacing = isPhone ? 12 : 20;

    final topics = [
      {'title': 'Tables', 'subtitle': 'Multiplication tables 1–100'},
      {'title': 'Squares', 'subtitle': 'Squares 1–100'},
      {'title': 'Cubes', 'subtitle': 'Cubes 1–100'},
      {'title': 'Square Roots', 'subtitle': '√1–100'},
      {'title': 'Cube Roots', 'subtitle': '∛1–100'},
      {
        'title': 'Percentage',
        'subtitle': 'Quick percent examples & improvements',
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Revise Daily'),
        centerTitle: true,
        backgroundColor: AppTheme.adaptiveAccent(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topSpacing),
              Text(
                'Daily revision & quick learning',
                style: TextStyle(
                  color: textColor.withOpacity(0.85),
                  fontSize: isPhone ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: topics.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final t = topics[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: isPhone ? 12 : 18),
                      child: LearnTile(
                        title: t['title']!,
                        subtitle: t['subtitle']!,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LearnDetailScreen(topic: t['title']!),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
