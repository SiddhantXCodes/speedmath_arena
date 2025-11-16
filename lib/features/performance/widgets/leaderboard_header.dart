//lib/features/performance/widgets/leaderboard_header.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/performance_provider.dart';

class LeaderboardHeader extends StatelessWidget {
  final PerformanceProvider provider;

  const LeaderboardHeader({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.adaptiveAccent(context);
    final isLoading = !provider.initialized;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.92), accent.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Leaderboard Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                /// 🟦 Rank summary row
                Row(
                  children: [
                    _pill(
                      label: "Today",
                      value: provider.todayRank?.toString() ?? "--",
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      label: "All-time",
                      value: provider.allTimeRank?.toString() ?? "--",
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      label: "Best",
                      value: "${provider.bestScore ?? 0} pts",
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// 🟩 Pill Chip
  Widget _pill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
