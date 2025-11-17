// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../../../providers/performance_provider.dart';
import '../../../providers/practice_log_provider.dart';
import '../../../theme/app_theme.dart';

import '../widgets/practice_bar_section.dart';
import '../widgets/top_bar.dart';
import '../widgets/quick_stats.dart';
import '../widgets/heatmap_section.dart';
import '../widgets/master_basics_section.dart';
import '../../../features/auth/auth_provider.dart';
import '../../performance/screens/performance_screen.dart';
import '../../practice/screens/attempts_history_screen.dart';
import '../../revise_daily/screens/learn_daily_screen.dart';
import '../../tips/screens/tips_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _isRefreshing = false;
  VoidCallback? _authListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    if (_authListener == null) {
      final auth = context.read<AuthProvider>();

      _authListener = () => _refreshActivityData();
      auth.addListener(_authListener!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshActivityData();
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    try {
      if (_authListener != null) {
        context.read<AuthProvider>().removeListener(_authListener!);
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshActivityData();
  }

  // -------------------------------------------------------------
  // Refresh Online + Offline Data
  // -------------------------------------------------------------
  Future<void> _refreshActivityData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      final performance = context.read<PerformanceProvider>();
      final practice = context.read<PracticeLogProvider>();

      await Future.wait([performance.reloadAll(), practice.loadLogs()]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Refresh failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // Heatmap colors
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practice = context.watch<PracticeLogProvider>();
    final performance = context.watch<PerformanceProvider>();

    // Merge online+offline activity
    final activity = _mergeActivityMaps(
      practice.activityMap,
      performance.dailyScores,
    );

    final loadingProviders = !practice.initialized || !performance.initialized;

    final width = MediaQuery.of(context).size.width;
    final isBigTablet = width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: TopBar(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshActivityData,
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: loadingProviders
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : (isBigTablet
                    ? _buildTabletLayout(context, activity)
                    : _buildPhoneLayout(context, activity)),
        ),
      ),
    );
  }

  // =============================================================
  // PHONE LAYOUT — SLIVERS
  // =============================================================
  Widget _buildPhoneLayout(BuildContext context, Map<DateTime, int> activity) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildWelcomeSection(context)),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: QuickStatsSection(
              isDarkMode: theme.brightness == Brightness.dark,
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverToBoxAdapter(child: PracticeBarSection()),
        ),

        _sliverFeatureCard(
          context,
          title: "Revise Daily",
          subtitle: "Do it daily to boast speed by +40% 🚀",
          icon: Icons.menu_book_rounded,
          iconColor: Colors.blueAccent,
          gradient1: theme.colorScheme.primary.withOpacity(0.15),
          gradient2: theme.colorScheme.primary.withOpacity(0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearnDailyScreen()),
            );
          },
        ),

        _sliverFeatureCard(
          context,
          title: "Tips & Tricks",
          subtitle: "Quick speedMaths hacks ⚡",
          icon: Icons.lightbulb_rounded,
          iconColor: Colors.orangeAccent,
          gradient1: Colors.orangeAccent.withOpacity(0.15),
          gradient2: Colors.orangeAccent.withOpacity(0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TipsHomeScreen()),
            );
          },
        ),
        // ⭐ NEW — Separate Master Basics Card
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: const SliverToBoxAdapter(child: MasterBasicsSection()),
        ),
        _sliverWideCard(
          context,
          title: "Practice History",
          subtitle: "Review your past quizzes",
          icon: Icons.history_rounded,
          accent: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttemptsHistoryScreen()),
            );
          },
        ),

        _sliverWideCard(
          context,
          title: "Performance Insights",
          subtitle: "Track accuracy & trends",
          icon: Icons.trending_up_rounded,
          accent: Colors.purpleAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceScreen()),
            );
          },
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          sliver: SliverToBoxAdapter(
            child: HeatmapSection(
              isDarkMode: theme.brightness == Brightness.dark,
              activity: activity,
              colorForValue: _colorForValue,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TABLET LAYOUT — TWO COLUMN SLIVERS
  // =============================================================
  Widget _buildTabletLayout(BuildContext context, Map<DateTime, int> activity) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN
                SizedBox(
                  width: width * 0.58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(context),
                      const SizedBox(height: 20),

                      _buildSectionTitle("Your Activity"),
                      const SizedBox(height: 8),

                      HeatmapSection(
                        isDarkMode: theme.brightness == Brightness.dark,
                        activity: activity,
                        colorForValue: _colorForValue,
                      ),

                      const SizedBox(height: 20),

                      _buildFeatureCard(
                        context,
                        title: "Learn Daily",
                        subtitle: "A new math concept every day",
                        icon: Icons.menu_book_rounded,
                        iconColor: Colors.blueAccent,
                        gradientColors: [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.primary.withOpacity(0.05),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LearnDailyScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildWideCard(
                        context,
                        title: "Performance Insights",
                        subtitle: "Track your progress",
                        icon: Icons.trending_up_rounded,
                        accent: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerformanceScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // RIGHT COLUMN
                SizedBox(
                  width: width * 0.38,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuickStatsSection(
                        isDarkMode: theme.brightness == Brightness.dark,
                      ),
                      const SizedBox(height: 20),

                      PracticeBarSection(),
                      const SizedBox(height: 20),

                      _buildFeatureCard(
                        context,
                        title: "Tips & Tricks",
                        subtitle: "Math hacks to speed up",
                        icon: Icons.lightbulb_rounded,
                        iconColor: Colors.orangeAccent,
                        gradientColors: [
                          Colors.orangeAccent.withOpacity(0.15),
                          Colors.orangeAccent.withOpacity(0.05),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TipsHomeScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildWideCard(
                        context,
                        title: "Practice History",
                        subtitle: "Review your attempts",
                        icon: Icons.history_rounded,
                        accent: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttemptsHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // Custom Sliver Builders
  // =============================================================

  SliverPadding _sliverFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color gradient1,
    required Color gradient2,
    required VoidCallback onTap,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      sliver: SliverToBoxAdapter(
        child: _buildFeatureCard(
          context,
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: iconColor,
          gradientColors: [gradient1, gradient2],
          onTap: onTap,
        ),
      ),
    );
  }

  SliverPadding _sliverWideCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      sliver: SliverToBoxAdapter(
        child: _buildWideCard(
          context,
          title: title,
          subtitle: subtitle,
          icon: icon,
          accent: accent,
          onTap: onTap,
        ),
      ),
    );
  }

  // =============================================================
  // Welcome Section
  // =============================================================
  Widget _buildWelcomeSection(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? "Good morning"
        : hour < 17
        ? "Good afternoon"
        : "Good evening";

    final name = (auth.user?.displayName ?? "").split(" ").first.trim();

    final line = name.isEmpty ? "$greeting 👋" : "$greeting, $name 👋";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let’s boost your math speed today!",
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  // =============================================================
  // Feature Card (private)
  // =============================================================
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradientColors.first.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // Wide Card (private)
  // =============================================================
  Widget _buildWideCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.2)),
          color: theme.cardColor,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // Utilities
  // =============================================================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
    );
  }

  /// Merge offline practice + online daily ranked
  Map<DateTime, int> _mergeActivityMaps(
    Map<DateTime, int> offline,
    Map<DateTime, int> online,
  ) {
    final merged = <DateTime, int>{};

    offline.forEach((d, v) {
      final day = DateTime(d.year, d.month, d.day);
      merged[day] = (merged[day] ?? 0) + v;
    });

    online.forEach((d, _) {
      final day = DateTime(d.year, d.month, d.day);
      merged[day] = (merged[day] ?? 0) + 1;
    });

    return merged.map((d, v) => MapEntry(d, v.clamp(0, 12)));
  }
}
