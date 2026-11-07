import 'package:flow_expense/core/providers/entry_field_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('date, account and name are visible by default', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      await container.read(visibleEntryFieldsProvider.future),
      defaultVisibleEntryFields,
    );
  });

  test('a changed entry field is remembered and can be changed back', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    addTearDown(first.dispose);
    await first.read(visibleEntryFieldsProvider.future);

    await first
        .read(visibleEntryFieldsProvider.notifier)
        .setVisible(EntryField.calculator, isVisible: true);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(
      await second.read(visibleEntryFieldsProvider.future),
      contains(EntryField.calculator),
    );

    await second
        .read(visibleEntryFieldsProvider.notifier)
        .setVisible(EntryField.calculator, isVisible: false);
    expect(
      second.read(visibleEntryFieldsProvider).value,
      defaultVisibleEntryFields,
    );
  });
}
