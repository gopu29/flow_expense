import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional tools on the add-transaction screen, in settings order.
enum EntryField { date, name, account, currencyConverter, budget, calculator }

const Set<EntryField> defaultVisibleEntryFields = {
  EntryField.date,
  EntryField.name,
  EntryField.account,
};

const String _kVisibleEntryFieldsKey = 'visible_entry_fields';

/// Remembers which optional tools the user shows on the add screen.
class VisibleEntryFieldsNotifier extends AsyncNotifier<Set<EntryField>> {
  @override
  Future<Set<EntryField>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNames = prefs.getStringList(_kVisibleEntryFieldsKey);
    if (storedNames == null) return defaultVisibleEntryFields;
    return EntryField.values
        .where((field) => storedNames.contains(field.name))
        .toSet();
  }

  Future<void> setVisible(EntryField field, {required bool isVisible}) async {
    final visible = {...await future};
    if (isVisible) {
      visible.add(field);
    } else {
      visible.remove(field);
    }
    state = AsyncData(visible);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kVisibleEntryFieldsKey,
      visible.map((field) => field.name).toList(),
    );
  }
}

final visibleEntryFieldsProvider =
    AsyncNotifierProvider<VisibleEntryFieldsNotifier, Set<EntryField>>(
  VisibleEntryFieldsNotifier.new,
);
