//lib/features/learn_daily/widgets/learn_table_view.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LearnTableView extends StatefulWidget {
  final String topic;
  const LearnTableView({super.key, required this.topic});

  @override
  State<LearnTableView> createState() => _LearnTableViewState();
}

class _LearnTableViewState extends State<LearnTableView> {
  late final PageController _pageController;
  late List<Map<String, dynamic>> groups;
  int selectedGroupIndex = 0;

  static const double _cellHeight = 48;
  static const double _leftColumnWidth = 60;
  static const int _tablesPerGroup = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    // 1–100 divided into 20 groups (1–5, 6–10, ...)
    groups = List.generate(20, (i) {
      final start = (i * _tablesPerGroup) + 1;
      final end = start + _tablesPerGroup - 1;
      return {'label': '$start–$end', 'start': start, 'end': end};
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildFixedLeftColumn(accent),
              _buildPagedTables(context, accent, textColor),
            ],
          ),
        ),
        _buildBottomChips(accent, textColor),
      ],
    );
  }

  /// 🧮 Fixed x1–x10 column
  Widget _buildFixedLeftColumn(Color accent) {
    return Container(
      width: _leftColumnWidth,
      color: accent.withOpacity(0.9),
      child: Column(
        children: [
          Container(height: _cellHeight, color: accent.withOpacity(0.15)),
          for (int i = 1; i <= 10; i++)
            Container(
              height: _cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.6,
                  ),
                ),
              ),
              child: Text(
                'x$i',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 📊 Right side: Full-height page for each group of 5 tables
  Widget _buildPagedTables(
    BuildContext context,
    Color accent,
    Color textColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - _leftColumnWidth;
    final double columnWidth = availableWidth / _tablesPerGroup;

    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        itemCount: groups.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => selectedGroupIndex = i),
        itemBuilder: (context, index) {
          final group = groups[index];
          final start = group['start'] as int;
          final end = group['end'] as int;

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                for (int n = start; n <= end; n++)
                  _buildTableColumn(context, n, textColor, accent, columnWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 📈 Single table column (header + 10 rows)
  Widget _buildTableColumn(
    BuildContext context,
    int number,
    Color textColor,
    Color accent,
    double width,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header (table number)
          Container(
            height: _cellHeight,
            color: accent.withOpacity(0.15),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Rows: x1–x10
          for (int i = 1; i <= 10; i++)
            Container(
              height: _cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i.isEven
                    ? theme.cardColor.withOpacity(0.9)
                    : theme.cardColor.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                    width: 0.4,
                  ),
                ),
              ),
              child: Text(
                '${number * i}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🔘 Bottom chips for navigating sections (1–5, 6–10, ...)
  Widget _buildBottomChips(Color accent, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: groups.asMap().entries.map((entry) {
            final i = entry.key;
            final label = entry.value['label'] as String;
            final selected = i == selectedGroupIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                  setState(() => selectedGroupIndex = i);
                },
                selectedColor: accent,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
