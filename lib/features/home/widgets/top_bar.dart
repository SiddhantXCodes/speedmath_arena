// lib/features/home/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../auth/auth_provider.dart';
import '../../auth/screens/profile_screen.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/performance_provider.dart';

import 'daily_streak_widget.dart';

/// 🔝 App-wide TopBar shown on HomeScreen.
class TopBar extends StatelessWidget {
  final VoidCallback? onToggleToday;
  const TopBar({super.key, this.onToggleToday});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final isDarkMode = themeProvider.isDark;

    final user = auth.user;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 0,
      titleSpacing: 16,
      title: Text(
        'SpeedMath Pro',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      actions: [
        // 🌗 Theme toggle
        SizedBox(
          width: 40,
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.7, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDarkMode),
                color: accent,
                size: 24,
              ),
            ),
            tooltip: isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ),

        const SizedBox(width: 8),

        // 🔥 Daily Streak Widget (separated)
        const DailyStreakWidget(),

        const SizedBox(width: 12),

        // 👤 User Avatar
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.3), width: 1.3),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                  0.4,
                ),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user == null
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: accent,
                      )
                    : user.photoURL == null
                    ? Text(
                        _getUserInitial(user.displayName, user.email),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getUserInitial(String? name, String? email) {
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }
}
