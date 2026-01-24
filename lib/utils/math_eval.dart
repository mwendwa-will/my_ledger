import 'package:math_expressions/math_expressions.dart';

/// Evaluates a mathematical expression string and returns the numeric value.
/// Throws on invalid expression.
double evaluateExpression(String expression) {
  final p = ShuntingYardParser();
  final exp = p.parse(expression.replaceAll(',', '.'));
  final cm = ContextModel();
  // ignore: deprecated_member_use
  final val = exp.evaluate(EvaluationType.REAL, cm) as num;
  return val.toDouble();
}

/// Safe evaluation returning null on parse error.
double? tryEvaluateExpression(String expression) {
  try {
    return evaluateExpression(expression);
  } catch (_) {
    return null;
  }
}
