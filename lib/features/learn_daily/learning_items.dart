//lib/features/learn_daily/learning_items.dart
import 'dart:math' as Math;

class LearningItems {
  static List<String> multiplicationTable(int n, {int upto = 100}) {
    return List.generate(upto, (i) => '${n} × ${i + 1} = ${n * (i + 1)}');
  }

  static List<String> tablesUpTo({int upto = 12, int maxMultiplier = 100}) {
    final List<String> out = [];
    for (var i = 1; i <= upto; i++) {
      out.addAll(multiplicationTable(i, upto: maxMultiplier));
      out.add('');
    }
    return out;
  }

  static List<String> squares({int from = 1, int to = 100}) {
    return List.generate(to - from + 1, (i) {
      final n = i + from;
      return '$n² = ${n * n}';
    });
  }

  static List<String> cubes({int from = 1, int to = 100}) {
    return List.generate(to - from + 1, (i) {
      final n = i + from;
      return '$n³ = ${n * n * n}';
    });
  }

  static List<String> squareRoots({int from = 1, int to = 100}) {
    return List.generate(to - from + 1, (i) {
      final n = i + from;
      return '√$n ≈ ${(_formatDouble(Math.sqrt(n)))}';
    });
  }

  static List<String> cubeRoots({int from = 1, int to = 100}) {
    return List.generate(to - from + 1, (i) {
      final n = i + from;
      return '∛$n ≈ ${(_formatDouble(Math.pow(n, 1 / 3)))}';
    });
  }

  static List<String> percentageExamples({int from = 1, int to = 20}) {
    // Show percent increase/decrease examples and quick conversions
    final List<String> out = [];
    for (var p = from; p <= to; p++) {
      out.add('$p% of 100 = $p');
      out.add('$p% of 250 = ${_formatDouble(250 * p / 100)}');
      out.add('Increase 100 by $p% → ${_formatDouble(100 * (1 + p / 100))}');
      out.add('Decrease 100 by $p% → ${_formatDouble(100 * (1 - p / 100))}');
      out.add('');
    }
    return out;
  }
}

String _formatDouble(num v) {
  if (v == v.roundToDouble()) return v.toString();
  return v.toStringAsFixed(3).replaceAll(RegExp(r"\.0+\$"), '');
}
