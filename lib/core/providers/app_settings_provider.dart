import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_haptics.dart';
import '../utils/formatters.dart';

/// A currency the user can pick in Settings.
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption(this.code, this.symbol, this.name);
}

const List<CurrencyOption> supportedCurrencies = [
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('USD', '\$', 'US Dollar'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('GBP', '£', 'British Pound'),
  CurrencyOption('JPY', '¥', 'Japanese Yen'),
  CurrencyOption('AED', 'د.إ', 'UAE Dirham'),
  CurrencyOption('SAR', '﷼', 'Saudi Riyal'),
  CurrencyOption('AUD', 'A\$', 'Australian Dollar'),
  CurrencyOption('CAD', 'C\$', 'Canadian Dollar'),
  CurrencyOption('SGD', 'S\$', 'Singapore Dollar'),
];

CurrencyOption currencyForCode(String code) => supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );

/// Digit grouping and decimal separator styles.
enum NumberStyle {
  /// 1,234,567.89
  standard('en_US', '¤#,##0.00'),

  /// 12,34,567.89
  indian('en_IN', '¤#,##,##0.00'),

  /// 1.234.567,89
  european('de_DE', '¤#,##0.00'),

  /// 1 234 567,89
  spaced('fr_FR', '¤#,##0.00');

  /// Locale that supplies the grouping and decimal separators.
  final String locale;

  /// Digit grouping. The symbol always comes first, as in "₹1,234.56".
  final String pattern;
  const NumberStyle(this.locale, this.pattern);
}

/// User preferences shown on the Settings screen.
class AppSettings {
  final String currencyCode;
  final NumberStyle numberStyle;
  final bool showCents;
  final bool hapticsEnabled;
  final bool hideBalances;

  /// `DateTime.monday` or `DateTime.sunday`.
  final int firstDayOfWeek;

  const AppSettings({
    this.currencyCode = 'INR',
    this.numberStyle = NumberStyle.standard,
    this.showCents = true,
    this.hapticsEnabled = true,
    this.hideBalances = false,
    this.firstDayOfWeek = DateTime.monday,
  });

  CurrencyOption get currency => currencyForCode(currencyCode);

  AppSettings copyWith({
    String? currencyCode,
    NumberStyle? numberStyle,
    bool? showCents,
    bool? hapticsEnabled,
    bool? hideBalances,
    int? firstDayOfWeek,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      numberStyle: numberStyle ?? this.numberStyle,
      showCents: showCents ?? this.showCents,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hideBalances: hideBalances ?? this.hideBalances,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.currencyCode == currencyCode &&
      other.numberStyle == numberStyle &&
      other.showCents == showCents &&
      other.hapticsEnabled == hapticsEnabled &&
      other.hideBalances == hideBalances &&
      other.firstDayOfWeek == firstDayOfWeek;

  @override
  int get hashCode => Object.hash(currencyCode, numberStyle, showCents,
      hapticsEnabled, hideBalances, firstDayOfWeek);

  static const _kCurrency = 'settings_currency';
  static const _kNumberStyle = 'settings_number_style';
  static const _kShowCents = 'settings_show_cents';
  static const _kHaptics = 'settings_haptics';
  static const _kHideBalances = 'settings_hide_balances';
  static const _kFirstDay = 'settings_first_day_of_week';

  static AppSettings fromPrefs(SharedPreferences prefs) {
    final styleName = prefs.getString(_kNumberStyle);
    return AppSettings(
      currencyCode: prefs.getString(_kCurrency) ?? 'INR',
      numberStyle: NumberStyle.values.firstWhere(
        (s) => s.name == styleName,
        orElse: () => NumberStyle.standard,
      ),
      showCents: prefs.getBool(_kShowCents) ?? true,
      hapticsEnabled: prefs.getBool(_kHaptics) ?? true,
      hideBalances: prefs.getBool(_kHideBalances) ?? false,
      firstDayOfWeek: prefs.getInt(_kFirstDay) ?? DateTime.monday,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(_kCurrency, currencyCode);
    await prefs.setString(_kNumberStyle, numberStyle.name);
    await prefs.setBool(_kShowCents, showCents);
    await prefs.setBool(_kHaptics, hapticsEnabled);
    await prefs.setBool(_kHideBalances, hideBalances);
    await prefs.setInt(_kFirstDay, firstDayOfWeek);
  }

  /// Pushes these settings into the static formatters and haptics helpers.
  void applyGlobally() {
    AppFormatters.configure(
      symbol: currency.symbol,
      locale: numberStyle.locale,
      pattern: numberStyle.pattern,
      showCents: showCents,
      hideBalances: hideBalances,
    );
    AppHaptics.enabled = hapticsEnabled;
  }

  /// Loads saved settings and applies them. Call once before `runApp`.
  static Future<AppSettings> loadAndApply() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = fromPrefs(prefs)..applyGlobally();
    _initial = settings;
    return settings;
  }

  static AppSettings _initial = const AppSettings();
}

/// Holds the user's settings. Every change is saved and applied right away.
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings._initial;

  Future<void> update(AppSettings Function(AppSettings) change) async {
    final next = change(state)..applyGlobally();
    state = next;
    await next.save(await SharedPreferences.getInstance());
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
