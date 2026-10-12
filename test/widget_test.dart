import 'package:flutter_test/flutter_test.dart';
import 'package:flow_expense/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowExpenseApp());
    expect(find.text('This month'), findsOneWidget);
  });
}
