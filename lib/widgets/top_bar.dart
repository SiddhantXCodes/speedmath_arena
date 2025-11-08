// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../theme/app_theme.dart';
import '../screens/profile_screen.dart';
import 'theme_transition_overlay.dart';

class TopBar extends StatefulWidget {
  final VoidCallback? onToggleToday;

  const TopBar({super.key, this.onToggleToday});
  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  int userStreak = 0;
  final _auth = FirebaseAuth.instance;
  late final User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadStreak();
  }

  /// Fetch daily ranked streak count
  Future<void> _loadStreak() async {
    if (user == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('daily_leaderboard')
          .get();

      int count = 0;
      for (final doc in query.docs) {
        final entry = await doc.reference
            .collection('entries')
            .doc(user!.uid)
            .get();
        if (entry.exists) count++;
      }

      if (mounted) setState(() => userStreak = count);
    } catch (e) {
      debugPrint("⚠️ Failed to load streak: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final theme = Theme.of(context);
    final isDarkMode = themeProvider.isDark;
    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    // 🔥 Fire gradient
    final streakGradient = const LinearGradient(
      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.transparent,
      elevation: 0,
      title: Text(
        'SpeedMaths Pro',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      actions: [
        // 🌗 Theme Toggle (with fullscreen animation)
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
          onPressed: () async {
            // Get root provider context
            final rootContext = Navigator.of(
              context,
              rootNavigator: true,
            ).context;

            // 🌓 1️⃣ Switch theme instantly (before showing overlay)
            Provider.of<ThemeProvider>(
              rootContext,
              listen: false,
            ).toggleTheme();

            // 🎬 2️⃣ Then show transition overlay (to mask the instant switch)
            showGeneralDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              transitionDuration: Duration.zero,
              pageBuilder: (context, _, __) {
                return ThemeTransitionOverlay(
                  isDarkMode: isDarkMode,
                  onAnimationComplete: () {
                    Navigator.of(context).pop(); // close overlay
                  },
                );
              },
            );
          },
        ),

        const SizedBox(width: 8),

        // 🔥 Daily streak display
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
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$userStreak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: userStreak > 0 ? const Color(0xFFFF5722) : textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // 👤 Profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withOpacity(0.3),
                      width: 1.4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.surfaceVariant
                        .withOpacity(0.4),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user == null
                        ? Icon(Icons.person, size: 20, color: accent)
                        : user.photoURL == null
                        ? Text(
                            _getUserInitial(user),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getUserInitial(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return 'U';
  }
}
