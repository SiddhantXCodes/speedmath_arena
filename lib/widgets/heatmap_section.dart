import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class HeatmapSection extends StatefulWidget {
  final bool isDarkMode;
  final Map<DateTime, int> activity;
  final double cellSize;
  final double cellSpacing;
  final Color Function(int) colorForValue;

  const HeatmapSection({
    super.key,
    required this.isDarkMode,
    required this.activity,
    required this.cellSize,
    required this.cellSpacing,
    required this.colorForValue,
  });

  @override
  State<HeatmapSection> createState() => _HeatmapSectionState();
}

class _HeatmapSectionState extends State<HeatmapSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.adaptiveText(context);
    final bgColor = AppTheme.adaptiveCard(context);
    final accent = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();

    // Normalize the incoming activity map to date-only keys (yyyy-mm-dd)
    final normalizedActivity = <DateTime, int>{};
    widget.activity.forEach((k, v) {
      final dt = DateTime(k.year, k.month, k.day);
      normalizedActivity[dt] = (normalizedActivity[dt] ?? 0) + v;
    });

    // ✅ Rolling 12-month window (from 12 months ago till this month)
    final firstVisibleMonth = DateTime(now.year, now.month - 11, 1);
    final startDate = firstVisibleMonth;
    final endDate = DateTime(now.year, now.month + 1, 0);

    // ✅ Generate days within the range
    final allDays = _generateDays(startDate, endDate);
    final weeks = _splitIntoWeeks(allDays);
    final monthPositions = _getMonthPositions(weeks);

    // 🧭 Auto-scroll to current month (fallback to closest month if exact not found)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      int? currentMonthWeekIndex = monthPositions[now.month];
      if (currentMonthWeekIndex == null && monthPositions.isNotEmpty) {
        // find the nearest month entry (by month distance)
        final months = monthPositions.keys.toList()..sort();
        int nearest = months.first;
        int bestDiff = (now.month - nearest).abs();
        for (final m in months) {
          final diff = (now.month - m).abs();
          if (diff < bestDiff) {
            bestDiff = diff;
            nearest = m;
          }
        }
        currentMonthWeekIndex = monthPositions[nearest];
      }

      if (currentMonthWeekIndex != null) {
        final scrollOffset =
            currentMonthWeekIndex *
            (widget.cellSize + widget.cellSpacing * 1.5);
        _scrollController.animateTo(
          scrollOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ), // safe clamp
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              Text(
                "${now.year}",
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Heatmap grid + month labels
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔥 Heatmap grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int w = 0; w < weeks.length; w++) ...[
                      // Add gap before a new month
                      if (monthPositions.containsValue(w) && w != 0)
                        SizedBox(width: widget.cellSpacing * 4),

                      Column(
                        children: [
                          for (int d = 0; d < 7; d++) ...[
                            _buildCell(
                              context,
                              weeks[w][d],
                              normalizedActivity,
                            ),
                            SizedBox(height: widget.cellSpacing),
                          ],
                        ],
                      ),
                      SizedBox(width: widget.cellSpacing),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // 🔥 Month labels (centered & spaced properly)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int w = 0; w < weeks.length; w++) ...[
                      if (monthPositions.containsValue(w) && w != 0)
                        SizedBox(width: widget.cellSpacing * 4),

                      SizedBox(
                        width: (widget.cellSize + widget.cellSpacing),
                        child: monthPositions.containsValue(w)
                            ? Center(
                                child: Text(
                                  _monthForWeek(monthPositions, w),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight:
                                        now.month ==
                                            _monthIndexForWeek(
                                              monthPositions,
                                              w,
                                            )
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color:
                                        now.month ==
                                            _monthIndexForWeek(
                                              monthPositions,
                                              w,
                                            )
                                        ? accent
                                        : textColor.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Legend
          Row(
            children: [
              Text('Less', style: TextStyle(fontSize: 12, color: textColor)),
              const SizedBox(width: 8),
              ...List.generate(4, (i) {
                final val = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.colorForValue(val),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text('More', style: TextStyle(fontSize: 12, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Build each heatmap cell
  Widget _buildCell(
    BuildContext context,
    DateTime? date,
    Map<DateTime, int> normalizedActivity,
  ) {
    if (date == null) {
      return Container(width: widget.cellSize, height: widget.cellSize);
    }

    final normalized = DateTime(date.year, date.month, date.day);
    final value = normalizedActivity[normalized] ?? 0;
    final color = widget.colorForValue(value);

    return GestureDetector(
      onTap: value > 0
          ? () {
              final formatted = DateFormat('MMM d, yyyy').format(date);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.adaptiveCard(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(
                    'Activity on $formatted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.adaptiveText(context),
                    ),
                  ),
                  content: Text(
                    '$value practice sessions completed',
                    style: TextStyle(
                      color: AppTheme.adaptiveText(context).withOpacity(0.8),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.cellSize,
        height: widget.cellSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // 🔹 Generate days
  List<DateTime> _generateDays(DateTime start, DateTime end) {
    final days = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  // 🔹 Split days into weeks
  List<List<DateTime?>> _splitIntoWeeks(List<DateTime> allDays) {
    final List<List<DateTime?>> weeks = [];

    if (allDays.isEmpty) return weeks;

    // Determine the weekday index for the first day (0 = Sunday, 6 = Saturday)
    // DateTime.weekday: Monday=1 ... Sunday=7, so convert to Sunday=0..Saturday=6
    final first = allDays.first;
    final firstOffset = (first.weekday % 7);

    List<DateTime?> current = List.filled(7, null);
    int index = 0;

    // Fill first week starting at firstOffset
    for (int i = firstOffset; i < 7 && index < allDays.length; i++) {
      current[i] = allDays[index++];
    }
    weeks.add(List.from(current));

    // Fill remaining full weeks
    while (index < allDays.length) {
      current = List.filled(7, null);
      for (int i = 0; i < 7 && index < allDays.length; i++) {
        current[i] = allDays[index++];
      }
      weeks.add(List.from(current));
    }
    return weeks;
  }

  // 🔹 Map: month → first week index
  Map<int, int> _getMonthPositions(List<List<DateTime?>> weeks) {
    final map = <int, int>{};
    for (int w = 0; w < weeks.length; w++) {
      for (final d in weeks[w]) {
        if (d == null) continue;
        // Only set if not already present (we want first week index for the month)
        map.putIfAbsent(d.month, () => w);
      }
    }
    return map;
  }

  // 🔹 Get month name
  String _monthForWeek(Map<int, int> positions, int weekIndex) {
    final entry = positions.entries.firstWhere(
      (e) => e.value == weekIndex,
      orElse: () => const MapEntry(0, -1),
    );
    if (entry.key == 0) return '';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[entry.key];
  }

  int _monthIndexForWeek(Map<int, int> positions, int weekIndex) {
    final entry = positions.entries.firstWhere(
      (e) => e.value == weekIndex,
      orElse: () => const MapEntry(0, -1),
    );
    return entry.key;
  }
}
