import 'package:flow_expense/core/services/android_shortcuts_service.dart';
import 'package:flow_expense/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx(double amount, DateTime date, TransactionType type) => Transaction(
      id: '$amount-$date',
      amount: amount,
      type: type,
      categoryId: 'c',
      accountId: 'a',
      date: date,
      createdAt: date,
    );

void main() {
  test('widget totals count only this month and today expenses', () {
    final now = DateTime(2026, 11, 8, 15);
    final totals = widgetSpendTotals([
      _tx(100, DateTime(2026, 11, 8, 9), TransactionType.expense),
      _tx(50, DateTime(2026, 11, 2), TransactionType.expense),
      _tx(999, DateTime(2026, 11, 8), TransactionType.income),
      _tx(70, DateTime(2026, 10, 8), TransactionType.expense),
    ], now);

    expect(totals.today, 100);
    expect(totals.month, 150);
  });
}
