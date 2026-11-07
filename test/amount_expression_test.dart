import 'package:flow_expense/core/utils/amount_expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateAmountExpression', () {
    test('reads a plain number', () {
      expect(evaluateAmountExpression('250.50'), 250.5);
    });

    test('applies × and ÷ before + and −', () {
      expect(evaluateAmountExpression('120+30×2'), 180);
      expect(evaluateAmountExpression('100−50÷2'), 75);
    });

    test('ignores a trailing operator', () {
      expect(evaluateAmountExpression('120+'), 120);
    });

    test('rounds to two decimal places', () {
      expect(evaluateAmountExpression('10÷3'), 3.33);
    });

    test('returns null for division by zero', () {
      expect(evaluateAmountExpression('10÷0'), isNull);
    });
  });

  test('lastAmountSegment returns the number being typed', () {
    expect(lastAmountSegment('120+30.5'), '30.5');
    expect(lastAmountSegment('120+'), '');
  });

  test('formatAmountInput removes trailing zeros only', () {
    expect(formatAmountInput(150), '150');
    expect(formatAmountInput(100), '100');
    expect(formatAmountInput(12.5), '12.5');
  });
}
