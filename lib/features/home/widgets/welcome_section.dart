// lib/features/home/widgets/welcome_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/auth_provider.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: true);

    // 🔹 Extract first name safely
    String firstName = "there";
    if (auth.user != null && auth.user!.displayName != null) {
      final name = auth.user!.displayName!.trim();
      if (name.isNotEmpty) {
        firstName = name.split(" ").first;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hi $firstName 👋",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Ready to sharpen your math reflexes today?",
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () {
            // TODO: Check if user has completed daily ranked quiz
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text("Continue Daily Ranked Quiz"),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
