import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../../presentation/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../performance/presentation/providers/performance_provider.dart';
import '../../../../presentation/providers/theme_provider.dart';

/// 🔝 App-wide TopBar shown on HomeScreen.
/// Displays title, theme toggle, streak count, and profile avatar.
class TopBar extends StatefulWidget {
  final VoidCallback? onToggleToday;

  const TopBar({super.key, this.onToggleToday});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  int _userStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final performance = Provider.of<PerformanceProvider>(
        context,
        listen: false,
      );
      final streak = await performance.fetchCurrentStreak();
      if (mounted) setState(() => _userStreak = streak);
    } catch (e) {
      debugPrint("⚠️ Failed to load streak: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);
    final isDarkMode = themeProvider.isDark;

    const streakGradient = LinearGradient(
      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final user = auth.user;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: 0,
      centerTitle: false, // ✅ stays left-aligned
      leadingWidth: 0, // ✅ no leading space shifting
      titleSpacing: 16, // ✅ consistent padding from left edge
      title: Text(
        'SpeedMath Pro',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      actions: [
        // 🌗 Theme toggle
        IconButton(
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
              size: 26,
            ),
          ),
          tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () {
            // Instantly toggle theme
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
          },
        ),

        const SizedBox(width: 8),

        // 🔥 Daily streak indicator
        GestureDetector(
          onTap: () {
            widget.onToggleToday?.call();
            _loadStreak();
          },
          child: Row(
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => streakGradient.createShader(bounds),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 26,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$_userStreak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _userStreak > 0
                      ? const Color(0xFFFF5722)
                      : textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

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
