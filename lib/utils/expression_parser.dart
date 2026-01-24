import 'package:math_expressions/math_expressions.dart';

/// Utility class for parsing and validating mathematical expressions
/// Centralizes expression parsing logic to avoid duplication
class ExpressionParser {
  /// Attempts to parse and evaluate a mathematical expression
  /// Returns the result as a double, or null if parsing fails
  static double? tryParse(String expression) {
    if (expression.isEmpty) return null;

    try {
      final cleanExpression = expression.replaceAll(',', '.');
      final parser = ShuntingYardParser();
      final exp = parser.parse(cleanExpression);
      final context = ContextModel();
      // ignore: deprecated_member_use
      return (exp.evaluate(EvaluationType.REAL, context) as num).toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Validates an expression and returns an error message if invalid
  /// Returns null if the expression is valid
  static String? validate(String expression) {
    if (expression.isEmpty) return 'Please enter an amount';

    final result = tryParse(expression);
    if (result == null) return 'Invalid expression';
    if (result <= 0) return 'Amount must be positive';

    return null; // Valid
  }

  /// Checks if an expression contains mathematical operators
  static bool hasOperators(String expression) {
    return expression.contains(RegExp(r'[+\-*/()]'));
  }

  /// Formats a number with commas for better readability
  static String formatNumber(double number, {int decimals = 2}) {
    final parts = number.toStringAsFixed(decimals).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Add commas to integer part
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return decimalPart.isNotEmpty ? '$buffer.$decimalPart' : buffer.toString();
  }
}
