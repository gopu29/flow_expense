import 'package:flow_expense/core/providers/app_settings_provider.dart';
import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flow_expense/core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => const AppSettings().applyGlobally());

  test('currency settings change how amounts are formatted', () {
    const AppSettings(currencyCode: 'USD', showCents: false).applyGlobally();
    expect(AppFormatters.currency(1234.56), '\$ 1,235');

    const AppSettings(numberStyle: NumberStyle.european).applyGlobally();
    expect(AppFormatters.currency(1234.56), '₹ 1.234,56');

    const AppSettings(numberStyle: NumberStyle.indian).applyGlobally();
    expect(AppFormatters.currency(1234567), '₹ 12,34,567.00');
  });

  test('hide balances masks balances but not other amounts', () {
    const AppSettings(hideBalances: true).applyGlobally();
    expect(AppFormatters.balance(500), contains(AppFormatters.hiddenAmount));
    expect(AppFormatters.currency(500), '₹ 500.00');
  });

  test('a changed setting is saved and applied', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(appSettingsProvider.notifier)
        .update((s) => s.copyWith(hapticsEnabled: false, firstDayOfWeek: DateTime.sunday));

    expect(AppHaptics.enabled, isFalse);
    final saved = AppSettings.fromPrefs(await SharedPreferences.getInstance());
    expect(saved.hapticsEnabled, isFalse);
    expect(saved.firstDayOfWeek, DateTime.sunday);
  });
}
