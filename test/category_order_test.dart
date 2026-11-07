import 'package:flow_expense/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sortOrder survives a database round trip', () {
    const category = Category(id: 'a', name: 'Food', sortOrder: 3);
    expect(Category.fromMap(category.toMap()).sortOrder, 3);
  });

  test('rows saved before sortOrder existed default to 0', () {
    final category = Category.fromMap({'id': 'a', 'name': 'Food'});
    expect(category.sortOrder, 0);
  });

  test('display order uses sortOrder, then name', () {
    const items = [
      Category(id: '1', name: 'Rent', sortOrder: 1),
      Category(id: '2', name: 'Food', sortOrder: 0),
      Category(id: '3', name: 'Bills', sortOrder: 1),
    ];
    final sorted = [...items]..sort(Category.compareForDisplay);
    expect(sorted.map((c) => c.name), ['Food', 'Bills', 'Rent']);
  });
}
