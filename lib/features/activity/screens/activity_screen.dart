import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../widgets/daily_spend_bar_chart.dart';
import '../widgets/transaction_tile.dart';

/// Main Activity Screen showcasing the daily spend bar chart, stats, and timeline.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetAsync = ref.watch(budgetProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;
    final daysElapsed = isCurrentMonth
        ? now.day
        : DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final dailyAverage = daysElapsed > 0 ? monthlyExpense / daysElapsed : 0.0;

    final budgetLimit = budgetAsync.value?.monthlyLimit ?? 0.0;
    final budgetLeft = budgetLimit > 0 ? (budgetLimit - monthlyExpense) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      MonthSelectorSheet.show(
                        context,
                        initialDate: selectedDate,
                        onDateSelected: (newDate) {
                          ref
                              .read(selectedDateProvider.notifier)
                              .updateDate(newDate);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isCurrentMonth
                                ? 'This month'
                                : AppFormatters.monthYear(selectedDate),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filters',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Spend Display
              Text(
                AppFormatters.currency(monthlyExpense),
                style: AppTypography.amountDisplay.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 14),

              // Chart and Overview Card
              transactionsAsync.when(
                data: (txs) {
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DailySpendBarChart(
                          transactions: txs,
                          selectedMonth: selectedDate,
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.surfaceBorder),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Average', style: AppTypography.caption),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.currency(dailyAverage),
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Budget Left', style: AppTypography.caption),
                                const SizedBox(height: 2),
                                Text(
                                  budgetLimit > 0
                                      ? AppFormatters.currency(budgetLeft)
                                      : 'No Budget Set',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: budgetLimit > 0 && budgetLeft >= 0
                                        ? AppColors.income
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const GlassCard(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => GlassCard(
                  child: Text('Error loading transactions: $e'),
                ),
              ),
              const SizedBox(height: 18),

              // Transactions Timeline Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activity Timeline', style: AppTypography.titleMedium),
                  transactionsAsync.maybeWhen(
                    data: (txs) {
                      final count = txs
                          .where((t) =>
                              t.date.year == selectedDate.year &&
                              t.date.month == selectedDate.month)
                          .length;
                      return Text(
                        '$count transactions',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transactions Timeline List
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    final monthTxs = txs
                        .where((t) =>
                            t.date.year == selectedDate.year &&
                            t.date.month == selectedDate.month)
                        .toList();

                    if (monthTxs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.textTertiary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions yet',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button to log your first expense',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group transactions by date
                    final Map<String, List<Transaction>> grouped = {};
                    for (final tx in monthTxs) {
                      final header = AppFormatters.dateHeader(tx.date);
                      grouped.putIfAbsent(header, () => []).add(tx);
                    }

                    final groupHeaders = grouped.keys.toList();

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: groupHeaders.length,
                      itemBuilder: (context, index) {
                        final header = groupHeaders[index];
                        final items = grouped[header]!;

                        final dayTotal = items.fold<double>(
                          0.0,
                          (sum, t) => t.type == TransactionType.expense
                              ? sum + t.amount
                              : sum,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 6,
                                left: 4,
                                right: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    header,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (dayTotal > 0)
                                    Text(
                                      AppFormatters.currency(dayTotal),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (tx) => TransactionTile(transaction: tx),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
