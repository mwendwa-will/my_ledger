import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/utils/math_eval.dart';

void main() {
  test('evaluate simple expression', () {
    final res = tryEvaluateExpression('2+3*4');
    expect(res, 14);
  });

  test('evaluate parentheses and decimals', () {
    final res = tryEvaluateExpression('(2.5+0.5)*2');
    expect(res, 6);
  });

  test('invalid expression returns null', () {
    final res = tryEvaluateExpression('2++');
    expect(res, null);
  });
}
