// lib/features/home/widgets/heatmap_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class HeatmapSection extends StatefulWidget {
  final bool isDarkMode;
  final Map<dynamic, int> activity; // 🔥 merged activity (offline + online)
  final Color Function(int) colorForValue;

  const HeatmapSection({
    super.key,
    required this.isDarkMode,
    required this.activity,
    required this.colorForValue,
  });

  @override
  State<HeatmapSection> createState() => _HeatmapSectionState();
}

class _HeatmapSectionState extends State<HeatmapSection> {
  late Map<DateTime, int> normalizedActivity;
  late DateTime currentMonth;

  @override
  void initState() {
    super.initState();
    normalizedActivity = _normalizeActivity(widget.activity);
    currentMonth = DateTime.now().toLocal();
  }

  /// 🔥 CRITICAL → Refresh heatmap automatically when activity map changes
  @override
  void didUpdateWidget(covariant HeatmapSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activity != widget.activity) {
      setState(() {
        normalizedActivity = _normalizeActivity(widget.activity);
      });
    }
  }

  /// Normalizes keys into consistent DateTime objects
  Map<DateTime, int> _normalizeActivity(Map<dynamic, int> map) {
    final data = <DateTime, int>{};

    map.forEach((key, value) {
      DateTime? date;

      if (key is DateTime) {
        date = DateTime(key.year, key.month, key.day);
      } else if (key is String) {
        try {
          date = DateTime.parse(key);
        } catch (_) {}
      }

      if (date != null) {
        data[date] = (data[date] ?? 0) + (value ?? 0);
      }
    });

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toLocal();
    final textColor = AppTheme.adaptiveText(context);
    final bgColor = AppTheme.adaptiveCard(context);

    final days = _generateMonthDays(currentMonth);
    final monthLabel = DateFormat('MMMM yyyy').format(currentMonth);

    final totalSessions = days.fold<int>(
      0,
      (sum, d) => sum + (normalizedActivity[d] ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Practice Activity",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: Icon(Icons.chevron_left, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: Icon(Icons.chevron_right, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Weekdays
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 6),

          // Calendar heatmap grid
          _buildCalendarGrid(days, textColor, bgColor, now),

          const SizedBox(height: 10),

          // Legend + summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend(textColor),
              Text(
                "${DateFormat('MMM').format(currentMonth)}: $totalSessions sessions",
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + offset);
    });
  }

  Widget _buildCalendarGrid(
    List<DateTime> days,
    Color textColor,
    Color bgColor,
    DateTime now,
  ) {
    final firstWeekday = DateTime(days.first.year, days.first.month, 1).weekday;
    final startPadding = firstWeekday - 1;
    final totalCells = startPadding + days.length;

    final rows = <Widget>[];

    for (int i = 0; i < totalCells; i += 7) {
      final weekCells = <Widget>[];

      for (int j = 0; j < 7; j++) {
        final index = i + j - startPadding;

        if (index < 0 || index >= days.length) {
          weekCells.add(const Expanded(child: SizedBox()));
        } else {
          final day = days[index];
          final value = normalizedActivity[day] ?? 0;
          final color = _heatmapColor(value);
          final isToday = DateUtils.isSameDay(day, now);

          weekCells.add(
            Expanded(
              child: GestureDetector(
                onTap: value > 0
                    ? () => _showDayDialog(day, value, bgColor, textColor)
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: const Color(0xFF2ECC71), width: 1.5)
                        : null,
                  ),
                  height: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${day.day}",
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (value > 0)
                        Text(
                          "$value",
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }

      rows.add(Row(children: weekCells));
    }

    return Column(children: rows);
  }

  Widget _buildLegend(Color textColor) {
    final steps = [0, 3, 6, 9, 12];

    return Row(
      children: [
        ...steps.map(
          (v) => Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _heatmapColor(v),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "0+  3+  6+  9+  12+",
          style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
        ),
      ],
    );
  }

  void _showDayDialog(
    DateTime date,
    int value,
    Color bgColor,
    Color textColor,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          DateFormat('EEE, MMM d').format(date),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "$value practice sessions completed",
          style: TextStyle(color: textColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  /// GitHub-style green gradient
  Color _heatmapColor(int value) {
    if (value <= 0) return Colors.transparent;
    if (value <= 2) return const Color(0xFF9BE9A8);
    if (value <= 5) return const Color(0xFF40C463);
    if (value <= 8) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  List<DateTime> _generateMonthDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    return List.generate(
      last.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }
}
