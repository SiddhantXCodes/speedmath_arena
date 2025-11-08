// lib/widgets/theme_transition_overlay.dart
import 'package:flutter/material.dart';

class ThemeTransitionOverlay extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onAnimationComplete;

  const ThemeTransitionOverlay({
    super.key,
    required this.isDarkMode,
    required this.onAnimationComplete,
  });

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().whenComplete(widget.onAnimationComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool toDark = !widget.isDarkMode;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);

        // Smooth background fade between day and night colors
        final bgColor = Color.lerp(
          widget.isDarkMode
              ? const Color(0xFFFFF9C4) // light creamy yellow (day)
              : const Color(0xFF0D1B2A), // deep navy (night)
          toDark ? const Color(0xFF0D1B2A) : const Color(0xFFFFF9C4),
          t,
        )!;

        return AnimatedOpacity(
          opacity: 1 - (t * 0.4),
          duration: const Duration(milliseconds: 900),
          child: Container(
            color: bgColor,
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 🌙 moon fades in
                  Opacity(
                    opacity: toDark ? t : 1 - t,
                    child: Icon(
                      Icons.nights_stay_rounded,
                      size: 95,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),

                  // ☀️ sun fades out
                  Opacity(
                    opacity: toDark ? 1 - t : t,
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      size: 95,
                      color: Colors.orangeAccent.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
