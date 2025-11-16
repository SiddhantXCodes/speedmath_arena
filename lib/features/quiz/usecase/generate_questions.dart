//lib/features/quiz/usecase/generate_questions.dart
import 'dart:math' as math;

class Question {
  final String expression;
  final String correctAnswer;

  Question({required this.expression, required this.correctAnswer});
}

class QuestionGenerator {
  static final _rnd = math.Random();

  /// Central entry point: generates question list for any topic
  static List<Question> generate(String topic, int min, int max, int count) {
    if (min > max) {
      final t = min;
      min = max;
      max = t;
    }

    topic = topic.toLowerCase();
    switch (topic) {
      case 'addition':
        return _basic(op: '+', min: min, max: max, count: count);
      case 'subtraction':
        return _basic(op: '-', min: min, max: max, count: count);
      case 'multiplication':
        return _basic(op: '×', min: min, max: max, count: count);
      case 'division':
        return _basic(op: '÷', min: min, max: max, count: count);
      case 'percentage':
        return _percentage(min, max, count);
      case 'average':
        return _average(min, max, count);
      case 'square':
        return _square(min, max, count);
      case 'cube':
        return _cube(min, max, count);
      case 'square root':
        return _squareRoot(min, max, count);
      case 'cube root':
        return _cubeRoot(min, max, count);
      case 'trigonometry':
        return _trigonometry(count);
      case 'tables':
        return _tables(min, max, count);
      case 'data interpretation':
        return _dataInterpretation(min, max, count);
      case 'mixed questions':
        return _mixed(min, max, count);
      default:
        return _basic(op: '+', min: min, max: max, count: count);
    }
  }

  // ---------- Helpers ----------
  static int _randInt(int min, int max) => min + _rnd.nextInt(max - min + 1);

  static T _choice<T>(List<T> list) => list[_rnd.nextInt(list.length)];

  static Map<String, int>? _findIntegerDivisionPair(
    int min,
    int max, {
    int tries = 30,
  }) {
    for (int t = 0; t < tries; t++) {
      final b = _randInt(math.max(2, min), max);
      final qMin = (min / b).ceil();
      final qMax = (max / b).floor();

      if (qMin <= qMax && qMax >= 0) {
        final q = _randInt(math.max(0, qMin), qMax);
        final a = b * q;

        if (a >= min && a <= max && b >= min && b <= max) {
          return {'a': a, 'b': b, 'q': q};
        }
      }
    }
    return null;
  }

  // ---------- Basic arithmetic ----------
  static List<Question> _basic({
    required String op,
    required int min,
    required int max,
    required int count,
  }) {
    return List.generate(count, (_) {
      int a = _randInt(min, max);
      int b = _randInt(min, max);

      switch (op) {
        case '+':
          return Question(expression: '$a + $b = ?', correctAnswer: '${a + b}');

        case '-':
          if (b > a) {
            final tmp = a;
            a = b;
            b = tmp;
          }
          return Question(expression: '$a - $b = ?', correctAnswer: '${a - b}');

        case '×':
          return Question(expression: '$a × $b = ?', correctAnswer: '${a * b}');

        case '÷':
          final pair = _findIntegerDivisionPair(min, max);
          if (pair != null && pair['b'] != 0) {
            return Question(
              expression: '${pair['a']} ÷ ${pair['b']} = ?',
              correctAnswer: '${pair['q']}',
            );
          }

          b = _randInt(math.max(1, min), max);
          final res = (a / b).toStringAsFixed(2);
          return Question(expression: '$a ÷ $b = ?', correctAnswer: res);

        default:
          return Question(
            expression: '$a $op $b = ?',
            correctAnswer: '${a + b}',
          );
      }
    });
  }

  // ---------- Percentage ----------
  static List<Question> _percentage(int min, int max, int count) {
    return List.generate(count, (_) {
      final base = _randInt(min, max);
      final percent = _randInt(5, 95);
      final result = (base * percent / 100).toStringAsFixed(2);

      return Question(
        expression: '$percent% of $base = ?',
        correctAnswer: result,
      );
    });
  }

  // ---------- Average ----------
  static List<Question> _average(int min, int max, int count) {
    return List.generate(count, (_) {
      final nums = List.generate(3, (_) => _randInt(min, max));
      final avg = (nums.reduce((a, b) => a + b) / nums.length).toStringAsFixed(
        2,
      );

      return Question(
        expression: 'Average of ${nums.join(", ")} = ?',
        correctAnswer: avg,
      );
    });
  }

  // ---------- Square ----------
  static List<Question> _square(int min, int max, int count) {
    final nMin = (min <= 0) ? 0 : sqrtCeil(min);
    final nMax = sqrtFloor(max);

    if (nMin > nMax) {
      return List.generate(count, (_) {
        final n = _randInt(min, max);
        return Question(expression: '$n² = ?', correctAnswer: '${n * n}');
      });
    }

    return List.generate(count, (_) {
      final n = _randInt(nMin, nMax);
      return Question(expression: '$n² = ?', correctAnswer: '${n * n}');
    });
  }

  // ---------- Cube ----------
  static List<Question> _cube(int min, int max, int count) {
    final nMin = cubeRootCeil(min);
    final nMax = cubeRootFloor(max);

    if (nMin > nMax) {
      return List.generate(count, (_) {
        final n = _randInt(min, max);
        return Question(expression: '$n³ = ?', correctAnswer: '${n * n * n}');
      });
    }

    return List.generate(count, (_) {
      final n = _randInt(nMin, nMax);
      return Question(expression: '$n³ = ?', correctAnswer: '${n * n * n}');
    });
  }

  // ---------- Square Root ----------
  static List<Question> _squareRoot(int min, int max, int count) {
    final vals = <int>[];
    for (int n = sqrtCeil(min); n <= sqrtFloor(max); n++) {
      vals.add(n * n);
    }

    if (vals.isEmpty) {
      return List.generate(count, (_) {
        final x = _randInt(min, max);
        final root = math.sqrt(x).toStringAsFixed(2);
        return Question(expression: '√$x ≈ ?', correctAnswer: root);
      });
    }

    return List.generate(count, (_) {
      final x = _choice(vals);
      final root = math.sqrt(x).toInt();
      return Question(expression: '√$x = ?', correctAnswer: '$root');
    });
  }

  // ---------- Cube Root ----------
  static List<Question> _cubeRoot(int min, int max, int count) {
    final vals = <int>[];
    for (int n = cubeRootCeil(min); n <= cubeRootFloor(max); n++) {
      vals.add(n * n * n);
    }

    if (vals.isEmpty) {
      return List.generate(count, (_) {
        final x = _randInt(min, max);
        final root = math.pow(x, 1 / 3).toStringAsFixed(2);
        return Question(expression: '∛$x ≈ ?', correctAnswer: root);
      });
    }

    return List.generate(count, (_) {
      final x = _choice(vals);
      final root = cbrt(x).toInt();
      return Question(expression: '∛$x = ?', correctAnswer: '$root');
    });
  }

  // ---------- Tables ----------
  static List<Question> _tables(int min, int max, int count) {
    final base = _randInt(min, max);

    return List.generate(count, (_) {
      final b = _randInt(min, max);
      return Question(
        expression: '$base × $b = ?',
        correctAnswer: '${base * b}',
      );
    });
  }

  // ---------- Trigonometry ----------
  static List<Question> _trigonometry(int count) {
    final funcs = ['sin', 'cos', 'tan'];
    final angles = [0, 30, 45, 60, 90];

    final values = {
      'sin': ['0', '0.5', '0.707', '0.866', '1'],
      'cos': ['1', '0.866', '0.707', '0.5', '0'],
      'tan': ['0', '0.577', '1', '1.732', '∞'],
    };

    return List.generate(count, (_) {
      final f = _choice(funcs);
      final idx = _rnd.nextInt(angles.length);
      return Question(
        expression: '$f(${angles[idx]}°) = ?',
        correctAnswer: values[f]![idx],
      );
    });
  }

  // ---------- Data Interpretation ----------
  static List<Question> _dataInterpretation(int min, int max, int count) {
    return List.generate(count, (_) {
      final prev = _randInt(min, max);
      var curr = _randInt(min, max);

      if (curr == prev) {
        curr = (curr == max) ? curr - 1 : curr + 1;
      }

      final change = (((curr - prev) / prev) * 100).toStringAsFixed(1);

      return Question(
        expression: 'From $prev to $curr, change (%) = ?',
        correctAnswer: '$change%',
      );
    });
  }

  // ---------- Mixed ----------
  static List<Question> _mixed(int min, int max, int count) {
    const topics = [
      'addition',
      'subtraction',
      'multiplication',
      'division',
      'square',
      'cube',
      'percentage',
      'average',
      'tables',
      'trigonometry',
      'data interpretation',
    ];

    return List.generate(count, (_) {
      final t = _choice(topics);
      return generate(t, min, max, 1).first;
    });
  }

  // ---------- Math Helpers ----------
  static int sqrtFloor(int x) => x < 0 ? 0 : math.sqrt(x).floor();
  static int sqrtCeil(int x) => x <= 0 ? 0 : math.sqrt(x).ceil();

  static int cubeRootFloor(int x) =>
      x < 0 ? -math.pow(x.abs(), 1 / 3).floor() : math.pow(x, 1 / 3).floor();

  static int cubeRootCeil(int x) => x <= 0 ? 0 : math.pow(x, 1 / 3).ceil();

  static int cbrt(int x) => math.pow(x, 1 / 3).round();
}
