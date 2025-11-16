import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BootScreen extends StatefulWidget {
  final String message; // ignored intentionally

  const BootScreen({super.key, required this.message});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _symbolTimer;

  final List<_FloatingSymbol> _symbols = [];
  final List<String> _mathChars = ["+", "-", "×", "÷", "√", "%", "π"];

  // 🔡 Typewriter text
  final String subtitle = "Setting up the ground for you to sweat…";
  String visibleText = "";
  int textIndex = 0;

  @override
  void initState() {
    super.initState();

    // Background gradient animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Floating symbols animation
    _symbolTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_symbols.length < 12) {
        setState(() {
          _symbols.add(
            _FloatingSymbol(
              char: _mathChars[Random().nextInt(_mathChars.length)],
              x: Random().nextDouble(),
              size: Random().nextDouble() * 26 + 18,
              speed: Random().nextDouble() * 1.1 + 0.7,
            ),
          );
        });
      }
    });

    // ⌨️ Start typewriter animation
    _startTypewriter();
  }

  void _startTypewriter() {
    Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (textIndex < subtitle.length) {
        setState(() => visibleText += subtitle[textIndex]);
        textIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _symbolTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final background = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // 🔥 Animated gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + _controller.value, -1),
                      end: Alignment(1 - _controller.value, 1),
                      colors: [
                        primary.withOpacity(0.45),
                        secondary.withOpacity(0.45),
                        background.withOpacity(0.50),
                      ],
                    ),
                  ),
                ),

                // 🔢 Floating math symbols
                ..._symbols.map((symbol) {
                  return Positioned(
                    left: symbol.x * MediaQuery.of(context).size.width,
                    top:
                        symbol.offset(_controller.value) *
                        MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: 0.20,
                      child: Text(
                        symbol.char,
                        style: TextStyle(
                          fontSize: symbol.size,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // CENTER CONTENT
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo fade-in
                      AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(seconds: 1),
                        child: Icon(
                          Icons.calculate_rounded,
                          size: 80,
                          color: primary.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        "SpeedMaths Pro",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 26,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔡 TYPEWRITER SUBTITLE
                      Text(
                        visibleText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FloatingSymbol {
  final String char;
  final double x;
  final double speed;
  final double size;

  _FloatingSymbol({
    required this.char,
    required this.x,
    required this.speed,
    required this.size,
  });

  double offset(double t) => (t * speed) % 1.25;
}
