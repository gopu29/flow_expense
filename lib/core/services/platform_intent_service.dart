import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../providers/expense_providers.dart';

/// Platform bridge syncing iOS Back Tap AppIntents and keyboard shortcuts.
class PlatformIntentService {
  static const MethodChannel _channel =
      MethodChannel('com.quanto.flow_expense/app_intent');

  final Ref _ref;

  PlatformIntentService(this._ref);

  bool _isSyncing = false;

  /// Checks for any pending transactions queued by iOS AppIntents / Back Tap.
  Future<void> syncPendingAppIntents() async {
    // Only query method channel on physical iOS / mobile
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    // Launch and resume can fire together; never import the same queue twice.
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final dynamic raw = await _channel.invokeMethod('getPendingIntents');
      if (raw is List && raw.isNotEmpty) {
        // Wait for the lists; reading `.value` at launch can still be empty.
        final categories = await _ref.read(categoriesProvider.future);
        final accounts = await _ref.read(accountsProvider.future);

        final defaultAccount = accounts.isNotEmpty
            ? accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first)
            : const Account(id: 'default', name: 'Main Account', type: AccountType.bank);

        for (final item in raw) {
          if (item is Map) {
            final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
            if (amount <= 0) continue;

            final String catName = item['category'] as String? ?? 'Food';
            final String note = item['note'] as String? ?? 'Back Tap Intent';

            final category = categories.firstWhere(
              (c) => c.name.toLowerCase() == catName.toLowerCase(),
              orElse: () => categories.isNotEmpty
                  ? categories.first
                  : const Category(id: 'default', name: 'Other', iconOrEmoji: '📦'),
            );

            final tx = Transaction(
              id: const Uuid().v4(),
              amount: amount,
              type: TransactionType.expense,
              categoryId: category.id,
              accountId: defaultAccount.id,
              date: DateTime.tryParse(item['timestamp'] as String? ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
              note: note,
              createdAt: DateTime.now(),
            );

            await _ref.read(transactionsProvider.notifier).addTransaction(tx);
          }
        }

        // Clear native queue after sync
        await _channel.invokeMethod('clearPendingIntents');
      }
    } catch (e) {
      debugPrint('PlatformIntentService sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

final platformIntentServiceProvider = Provider<PlatformIntentService>((ref) {
  final service = PlatformIntentService(ref);
  // Sync on startup, and again whenever the app returns to the foreground,
  // since Back Tap usually logs expenses while the app is in the background.
  service.syncPendingAppIntents();
  final listener = AppLifecycleListener(
    onResume: service.syncPendingAppIntents,
  );
  ref.onDispose(listener.dispose);
  return service;
});
