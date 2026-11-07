import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../providers/app_settings_provider.dart';
import '../providers/expense_providers.dart';
import '../utils/formatters.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

const MethodChannel _channel =
    MethodChannel('com.example.flow_expense/android_shortcuts');

/// Expense totals for today and this month, as shown on the spend widget.
({double today, double month}) widgetSpendTotals(
  List<Transaction> transactions,
  DateTime now,
) {
  var today = 0.0;
  var month = 0.0;
  for (final tx in transactions) {
    if (tx.type != TransactionType.expense) continue;
    if (tx.date.year != now.year || tx.date.month != now.month) continue;
    month += tx.amount;
    if (tx.date.day == now.day) today += tx.amount;
  }
  return (today: today, month: month);
}

/// Sends spend totals to the Android home screen widgets.
Future<void> updateAndroidWidgets(List<Transaction> transactions) async {
  if (!_isAndroid) return;
  final totals = widgetSpendTotals(transactions, DateTime.now());
  try {
    await _channel.invokeMethod('updateWidgets', {
      'today': AppFormatters.currency(totals.today),
      'month': AppFormatters.currency(totals.month),
    });
  } catch (e) {
    debugPrint('updateAndroidWidgets error: $e');
  }
}

/// Shows or hides the "Add expense" notification. Returns false when Android
/// first has to ask for notification permission.
Future<bool> setQuickAddNotification(bool enabled) async {
  if (!_isAndroid) return true;
  try {
    return await _channel.invokeMethod<bool>(
          'setNotificationEnabled',
          {'enabled': enabled},
        ) ??
        false;
  } catch (e) {
    debugPrint('setQuickAddNotification error: $e');
    return false;
  }
}

/// Keeps the widgets and notification in sync with the app.
///
/// The quick-add sheet runs in its own Flutter engine, so when the main app
/// comes back to the foreground it reloads its data.
final androidShortcutsServiceProvider = Provider<void>((ref) {
  if (!_isAndroid) return;

  ref.listen<AsyncValue<List<Transaction>>>(
    transactionsProvider,
    (_, next) {
      final txs = next.value;
      if (txs != null) updateAndroidWidgets(txs);
    },
    fireImmediately: true,
  );

  if (ref.read(appSettingsProvider).quickAddNotification) {
    setQuickAddNotification(true);
  }

  final listener = AppLifecycleListener(
    onResume: () {
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);
    },
  );
  ref.onDispose(listener.dispose);
});
