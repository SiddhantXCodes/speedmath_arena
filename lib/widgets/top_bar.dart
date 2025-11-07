import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart'; // For ThemeProvider
import '../theme/app_theme.dart';

class TopBar extends StatelessWidget {
  final int userStreak;
  final VoidCallback onToggleToday;

  const TopBar({
    super.key,
    required this.userStreak,
    required this.onToggleToday,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Theme-driven tokens
    final accent = AppTheme.adaptiveAccent(context);
    final onSurface = colorScheme.onSurface;
    final mutedOnSurface = onSurface.withOpacity(0.68);
    final streakActive = AppTheme.warningColor; // warm highlight for streaks
    final streakInactive = colorScheme.surfaceVariant.withOpacity(0.18);

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: theme.appBarTheme.elevation ?? 0,
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: onSurface,
          fontSize: 20,
        ),
        child: const Text('SpeedMath'),
      ),
      actions: [
        // Animated Theme Toggle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: 0.70, end: 2).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: IconButton(
            key: ValueKey<bool>(isDarkMode),
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
              color: isDarkMode ? streakActive : accent,
              size: 26,
            ),
            tooltip: isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ),

        const SizedBox(width: 8),

        // Streak counter
        GestureDetector(
          onTap: onToggleToday,
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 26,
                color: userStreak > 0 ? streakActive : mutedOnSurface,
              ),
              const SizedBox(width: 4),
              Text(
                '$userStreak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: userStreak > 0 ? streakActive : mutedOnSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Avatar
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/images/elf_icon.png'),
          ),
        ),
      ],
    );
  }
}
