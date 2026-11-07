import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// App-wide formatting utilities for currency, dates, and amounts.
///
/// Currency output follows the user's settings, applied with [configure].
class AppFormatters {
  AppFormatters._();

  static String _symbol = AppConstants.currencySymbol;
  static String _locale = 'en_US';
  static String _pattern = '¤#,##0.00';
  static bool _showCents = true;
  static bool _hideBalances = false;

  static NumberFormat _currencyFormat = _buildCurrency();
  static NumberFormat _compactCurrency = _buildCompact();

  static const String hiddenAmount = '••••••';

  /// Applies the user's currency settings.
  static void configure({
    required String symbol,
    required String locale,
    required String pattern,
    required bool showCents,
    required bool hideBalances,
  }) {
    _symbol = symbol;
    _locale = locale;
    _pattern = pattern;
    _showCents = showCents;
    _hideBalances = hideBalances;
    _currencyFormat = _buildCurrency();
    _compactCurrency = _buildCompact();
  }

  static NumberFormat _buildCurrency() => NumberFormat.currency(
        locale: _locale,
        symbol: '$_symbol ',
        customPattern: _pattern,
        decimalDigits: _showCents ? 2 : 0,
      );

  static NumberFormat _buildCompact() => NumberFormat.compactCurrency(
        locale: _locale,
        symbol: '$_symbol ',
      );

  /// The selected currency symbol (e.g. "₹").
  static String get symbol => _symbol;

  /// Whether account balances should be masked.
  static bool get hideBalances => _hideBalances;

  /// Format an amount into currency string (e.g., "₹ 1,250.00").
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Like [currency], but masked when Hide balances is on.
  static String balance(double amount) {
    return _hideBalances ? '$_symbol $hiddenAmount' : currency(amount);
  }

  /// Format an amount into compact currency (e.g., "₹ 1.2K").
  static String compact(double amount) {
    return _compactCurrency.format(amount);
  }

  /// Sample of the chosen number style, e.g. "₹1,234.56".
  static String sample({
    required String symbol,
    required String locale,
    required String pattern,
    required bool showCents,
  }) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      customPattern: pattern,
      decimalDigits: showCents ? 2 : 0,
    ).format(1234.56);
  }

  /// Format a DateTime into relative or readable string:
  /// - "Today"
  /// - "Yesterday"
  /// - "dd MMM yyyy" (e.g., "12 Oct 2026")
  static String dateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(date.year, date.month, date.day);

    if (compDate == today) {
      return 'Today';
    } else if (compDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('EEE, dd MMM').format(date);
    }
  }

  /// Format month-year display (e.g. "October 2026").
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Short time format (e.g. "10:30 AM").
  static String time(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
