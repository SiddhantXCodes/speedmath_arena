//lib/features/performance/widgets/performance_heatmap.dart
import 'package:flutter/material.dart';
import '../../home/widgets/heatmap_section.dart';
import '../../../providers/practice_log_provider.dart';
import '../../../providers/performance_provider.dart';
import '../../../theme/app_theme.dart';

class PerformanceHeatmap extends StatelessWidget {
  final PerformanceProvider perf;
  final PracticeLogProvider log;

  const PerformanceHeatmap({super.key, required this.perf, required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.adaptiveText(context);

    final offlineMap = log.getActivityMap();
    final onlineMap = Map<DateTime, int>.fromEntries(
      perf.dailyScores.keys.map((d) => MapEntry(d, 1)),
    );

    final merged = _mergeActivity(offlineMap, onlineMap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overall Activity (Offline + Ranked)",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Matches the new HeatmapSection constructor
        HeatmapSection(
          isDarkMode: isDark,
          activity: merged,
          colorForValue: _colorForValue,
        ),
      ],
    );
  }

  /// 🧩 Merge Offline + Online Maps
  Map<DateTime, int> _mergeActivity(
    Map<DateTime, int> offline,
    Map<DateTime, int> online,
  ) {
    final merged = Map<DateTime, int>.from(offline);
    for (final e in online.entries) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    return merged.map((k, v) => MapEntry(k, v.clamp(0, 5)));
  }

  /// 🎨 GitHub-like color scale
  Color _colorForValue(int v) {
    switch (v.clamp(0, 4)) {
      case 0:
        return const Color(0xFFEBEDF0);
      case 1:
        return const Color(0xFF9BE9A8);
      case 2:
        return const Color(0xFF40C463);
      case 3:
        return const Color(0xFF30A14E);
      default:
        return const Color(0xFF216E39);
    }
  }
}
