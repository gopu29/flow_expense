/// Keypad operators, in display order.
const List<String> amountOperators = ['+', '−', '×', '÷'];

/// Whether [expression] contains an operator rather than a plain number.
bool hasAmountOperator(String expression) =>
    amountOperators.any(expression.contains);

/// Whether [expression] ends with an operator.
bool endsWithAmountOperator(String expression) =>
    amountOperators.any(expression.endsWith);

/// The number currently being typed, after the last operator.
String lastAmountSegment(String expression) {
  var start = 0;
  for (var index = 0; index < expression.length; index++) {
    if (amountOperators.contains(expression[index])) start = index + 1;
  }
  return expression.substring(start);
}

/// Evaluates a keypad expression such as `120+30×2`, with × and ÷ first.
/// A trailing operator is ignored. Returns null for invalid input or
/// division by zero. The result is rounded to two decimal places.
double? evaluateAmountExpression(String expression) {
  var input = expression;
  while (input.isNotEmpty && endsWithAmountOperator(input)) {
    input = input.substring(0, input.length - 1);
  }

  final numbers = <double>[];
  final operators = <String>[];
  var current = StringBuffer();
  for (final character in input.split('')) {
    if (amountOperators.contains(character)) {
      final value = double.tryParse(current.toString());
      if (value == null) return null;
      numbers.add(value);
      operators.add(character);
      current = StringBuffer();
    } else {
      current.write(character);
    }
  }
  final last = double.tryParse(current.toString());
  if (last == null) return null;
  numbers.add(last);

  final sumTerms = <double>[numbers.first];
  for (var index = 0; index < operators.length; index++) {
    final next = numbers[index + 1];
    switch (operators[index]) {
      case '+':
        sumTerms.add(next);
      case '−':
        sumTerms.add(-next);
      case '×':
        sumTerms.last *= next;
      case '÷':
        if (next == 0) return null;
        sumTerms.last /= next;
    }
  }

  final total = sumTerms.reduce((a, b) => a + b);
  return (total * 100).roundToDouble() / 100;
}

/// Formats [amount] for the keypad, without trailing zeros.
String formatAmountInput(double amount) {
  final fixed = amount.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
