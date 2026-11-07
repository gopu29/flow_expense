import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../categories/screens/category_management_screen.dart';
import '../widgets/settings_option_sheet.dart';
import '../widgets/settings_tiles.dart';
import '../../../core/services/android_shortcuts_service.dart';
import 'android_shortcuts_guide_screen.dart';
import 'back_tap_guide_screen.dart';

/// Settings screen grouped like Quanto: General, Automations, Preferences,
/// Privacy & security, and Data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Settings', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.horizontalPadding,
            8,
            AppConstants.horizontalPadding,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const SettingsSectionLabel('General'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.grid_view_rounded,
                title: 'Categories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                ),
              ),
              SettingsNavTile(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                value: settings.currencyCode,
                onTap: () => _pickCurrency(context, settings, notifier),
              ),
            ]),
            const SettingsSectionLabel('Automations'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.touch_app_outlined,
                title: 'Back tap',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isAndroid
                        ? const AndroidShortcutsGuideScreen()
                        : const BackTapGuideScreen(),
                  ),
                ),
              ),
              if (isAndroid) ...[
                SettingsNavTile(
                  icon: Icons.widgets_outlined,
                  title: 'Widgets & shortcuts',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AndroidShortcutsGuideScreen(),
                    ),
                  ),
                ),
                SettingsSwitchTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification shortcut',
                  value: settings.quickAddNotification,
                  onChanged: (v) => _setNotification(context, notifier, v),
                ),
              ],
            ]),
            const SettingsSectionLabel('Preferences'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.calendar_view_week_rounded,
                title: 'First day of week',
                value: settings.firstDayOfWeek == DateTime.sunday ? 'Sunday' : 'Monday',
                onTap: () => _pickFirstDay(context, settings, notifier),
              ),
              SettingsNavTile(
                icon: Icons.payments_outlined,
                title: 'Currency format',
                value: _formatSample(settings, settings.numberStyle),
                onTap: () => _pickNumberStyle(context, settings, notifier),
              ),
              SettingsSwitchTile(
                icon: Icons.toll_outlined,
                title: 'Display cents',
                value: settings.showCents,
                onChanged: (v) => notifier.update((s) => s.copyWith(showCents: v)),
              ),
              SettingsSwitchTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                value: settings.hapticsEnabled,
                onChanged: (v) {
                  notifier.update((s) => s.copyWith(hapticsEnabled: v));
                  AppHaptics.selectionClick();
                },
              ),
            ]),
            const SettingsSectionLabel('Privacy & security'),
            SettingsGroup(children: [
              SettingsSwitchTile(
                icon: Icons.visibility_off_outlined,
                title: 'Hide balances',
                value: settings.hideBalances,
                onChanged: (v) => notifier.update((s) => s.copyWith(hideBalances: v)),
              ),
            ]),
            const SettingsSectionLabel('Data'),
            SettingsGroup(children: [
              SettingsNavTile(
                icon: Icons.description_outlined,
                title: 'Export data',
                onTap: () => _exportCsv(context, ref),
              ),
              SettingsNavTile(
                icon: Icons.delete_outline_rounded,
                title: 'Erase data',
                isDestructive: true,
                onTap: () => _confirmErase(context, ref),
              ),
            ]),
            const SizedBox(height: 28),
            Center(
              child: Text(
                '${AppConstants.appName} v1.0.0 • Offline, stored on this device',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _setNotification(
    BuildContext context,
    AppSettingsNotifier notifier,
    bool enabled,
  ) async {
    await notifier.update((s) => s.copyWith(quickAddNotification: enabled));
    final shown = await setQuickAddNotification(enabled);
    if (enabled && !shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allow notifications to show the Add expense shortcut'),
        ),
      );
    }
  }

  static String _formatSample(AppSettings settings, NumberStyle style) {
    return AppFormatters.sample(
      symbol: settings.currency.symbol,
      locale: style.locale,
      pattern: style.pattern,
      showCents: settings.showCents,
    );
  }

  void _pickCurrency(BuildContext context, AppSettings settings, AppSettingsNotifier notifier) {
    showSettingsOptionSheet<String>(
      context: context,
      title: 'Currency',
      selected: settings.currencyCode,
      options: [
        for (final c in supportedCurrencies)
          SettingsOption(value: c.code, label: '${c.code} · ${c.name}', leading: c.symbol),
      ],
      onSelected: (code) => notifier.update((s) => s.copyWith(currencyCode: code)),
    );
  }

  void _pickFirstDay(BuildContext context, AppSettings settings, AppSettingsNotifier notifier) {
    showSettingsOptionSheet<int>(
      context: context,
      title: 'First day of week',
      selected: settings.firstDayOfWeek,
      options: const [
        SettingsOption(value: DateTime.monday, label: 'Monday'),
        SettingsOption(value: DateTime.sunday, label: 'Sunday'),
      ],
      onSelected: (day) => notifier.update((s) => s.copyWith(firstDayOfWeek: day)),
    );
  }

  void _pickNumberStyle(BuildContext context, AppSettings settings, AppSettingsNotifier notifier) {
    showSettingsOptionSheet<NumberStyle>(
      context: context,
      title: 'Currency format',
      selected: settings.numberStyle,
      options: [
        for (final style in NumberStyle.values)
          SettingsOption(value: style, label: _formatSample(settings, style)),
      ],
      onSelected: (style) => notifier.update((s) => s.copyWith(numberStyle: style)),
    );
  }

  static String _csvField(String value) {
    if (value.contains(RegExp(r'[",\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final txs = await ref.read(transactionsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    final accounts = await ref.read(accountsProvider.future);
    if (!context.mounted) return;

    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    final categoryNames = {for (final c in categories) c.id: c.name};
    final accountNames = {for (final a in accounts) a.id: a.name};

    final buffer = StringBuffer('Date,Type,Amount,Category,Account,Note\n');
    for (final t in txs) {
      buffer.writeln([
        t.date.toIso8601String(),
        t.type.name,
        t.amount.toStringAsFixed(2),
        _csvField(categoryNames[t.categoryId] ?? ''),
        _csvField(accountNames[t.accountId] ?? ''),
        _csvField(t.note ?? ''),
      ].join(','));
    }
    final csv = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Export data', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${txs.length} transactions as CSV.', style: AppTypography.caption),
            const SizedBox(height: 12),
            Container(
              height: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csv,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Erase data?', style: AppTypography.titleMedium),
        content: Text(
          'This deletes every transaction and budget and sets all account '
          'balances to zero. Accounts and categories are kept. This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    AppHaptics.mediumImpact();
    await ref.read(repositoryProvider).eraseActivity();
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(monthlyBudgetsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All transactions and budgets erased')),
    );
  }
}
