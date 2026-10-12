import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// App-wide formatting utilities for currency, dates, and amounts.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    symbol: '${AppConstants.currencySymbol} ',
  );

  /// Format an amount into currency string (e.g., "₹ 1,250.00").
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format an amount into compact currency (e.g., "₹ 1.2K").
  static String compact(double amount) {
    return _compactCurrency.format(amount);
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
