// lib/features/auth/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final accent = AppTheme.adaptiveAccent(context);
    final textColor = AppTheme.adaptiveText(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                // -----------------------------
                // 👤 PROFILE AVATAR
                // -----------------------------
                CircleAvatar(
                  radius: 45,
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                    0.4,
                  ),
                  backgroundImage: (user?.photoURL != null)
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user == null
                      ? const Icon(Icons.person_outline_rounded, size: 42)
                      : user.photoURL == null
                      ? Text(
                          _getUserInitial(user.displayName, user.email),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.light
                                ? Colors.black
                                : Colors.white,
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 10),

                // -----------------------------
                // 🧾 NAME + EMAIL
                // -----------------------------
                Text(
                  _capitalizeName(user?.displayName ?? "Guest User"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  user?.email ?? "Not signed in",
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // -----------------------------
                // 🔐 LOGIN BUTTON
                // -----------------------------
                if (user == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, color: Colors.white),
                    label: const Text(
                      "Login or Register",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // -----------------------------
          // ⚙️ SETTINGS
          // -----------------------------
          _sectionTitle("Settings", textColor),

          _tile(
            icon: themeProvider.isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: "Dark Mode",
            subtitle: themeProvider.isDark ? "Enabled" : "Disabled",
            onTap: () => themeProvider.toggleTheme(),
          ),

          _tile(
            icon: Icons.notifications_active_rounded,
            title: "Notifications",
            subtitle: "Coming soon",
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // -----------------------------
          // 💬 FEEDBACK
          // -----------------------------
          _sectionTitle("Feedback & Support", textColor),

          _tile(
            icon: Icons.star_rate_rounded,
            title: "Rate the App",
            subtitle: "Share your experience",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("⭐ Feature coming soon!")),
              );
            },
          ),

          _tile(
            icon: Icons.feedback_rounded,
            title: "Send Feedback",
            subtitle: "Help us improve SpeedMath Pro",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("📨 Feedback form coming soon!")),
              );
            },
          ),

          const SizedBox(height: 20),

          // -----------------------------
          // 🚪 LOGOUT BUTTON
          // -----------------------------
          if (user != null)
            ElevatedButton.icon(
              onPressed: () async {
                await auth.logout(context); // 🔥 FIXED — now passes context

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Signed out successfully."),
                    duration: Duration(seconds: 2),
                  ),
                );

                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Sign Out"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 📌 Helpers
  // --------------------------------------------------------------------------
  String _getUserInitial(String? name, String? email) {
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return "?";
  }

  String _capitalizeName(String name) {
    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = AppTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 26),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
