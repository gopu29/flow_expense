import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/entry_field_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Lets the user choose which optional tools appear on the add screen.
class EntryFieldsSheet extends ConsumerWidget {
  const EntryFieldsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EntryFieldsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        ref.watch(visibleEntryFieldsProvider).value ?? defaultVisibleEntryFields;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF162330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2B3F54), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entry fields',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose what shows when you add a transaction.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final field in EntryField.values)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _iconFor(field),
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                title: Text(
                  _titleFor(field),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                value: visible.contains(field),
                onChanged: (isVisible) {
                  AppHaptics.selectionClick();
                  ref
                      .read(visibleEntryFieldsProvider.notifier)
                      .setVisible(field, isVisible: isVisible);
                },
              ),
          ],
        ),
      ),
    );
  }

  static String _titleFor(EntryField field) => switch (field) {
        EntryField.date => 'Date',
        EntryField.name => 'Name',
        EntryField.account => 'Accounts',
        EntryField.currencyConverter => 'Currency converter',
        EntryField.budget => 'Budgets',
        EntryField.calculator => 'Calculator',
      };

  static IconData _iconFor(EntryField field) => switch (field) {
        EntryField.date => Icons.calendar_today_outlined,
        EntryField.name => Icons.sticky_note_2_outlined,
        EntryField.account => Icons.account_balance_wallet_outlined,
        EntryField.currencyConverter => Icons.currency_exchange_rounded,
        EntryField.budget => Icons.donut_large_rounded,
        EntryField.calculator => Icons.calculate_outlined,
      };
}
