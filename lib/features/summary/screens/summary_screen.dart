import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';
import '../../../models/transaction.dart';
import '../widgets/summary_donut_chart.dart';

/// Summary screen showing category spending distributions and donut visualizations.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;

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
              // Header Row
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
                  Text(
                    'Spending Summary',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Income vs Expense Summary Cards
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.income.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: AppColors.income,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Income', style: AppTypography.caption),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.currency(monthlyIncome),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: AppColors.expense,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Spent', style: AppTypography.caption),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.currency(monthlyExpense),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories calculations
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    final monthTxs = txs
                        .where((t) =>
                            t.type == TransactionType.expense &&
                            t.date.year == selectedDate.year &&
                            t.date.month == selectedDate.month)
                        .toList();

                    return categoriesAsync.when(
                      data: (categories) {
                        final Map<String, double> categorySums = {};
                        for (final tx in monthTxs) {
                          categorySums[tx.categoryId] =
                              (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
                        }

                        final spendDataList = <CategorySpendData>[];
                        for (final entry in categorySums.entries) {
                          final cat = categories.firstWhere(
                            (c) => c.id == entry.key,
                            orElse: () => const Category(
                              id: '',
                              name: 'General',
                              iconOrEmoji: '🏷️',
                            ),
                          );

                          final percentage = monthlyExpense > 0
                              ? (entry.value / monthlyExpense) * 100
                              : 0.0;

                          spendDataList.add(
                            CategorySpendData(
                              categoryName: cat.name,
                              iconOrEmoji: cat.iconOrEmoji,
                              amount: entry.value,
                              colorValue: cat.color,
                              percentage: percentage,
                            ),
                          );
                        }

                        // Sort descending by amount
                        spendDataList.sort((a, b) => b.amount.compareTo(a.amount));

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 90),
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  SummaryDonutChart(
                                    categories: spendDataList,
                                    totalSpend: monthlyExpense,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Category Breakdown', style: AppTypography.titleMedium),
                            const SizedBox(height: 8),

                            if (spendDataList.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No category data available for this month',
                                    style: AppTypography.caption,
                                  ),
                                ),
                              )
                            else
                              ...spendDataList.map((item) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.surfaceBorder.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CategoryIconBadge(
                                            iconOrEmoji: item.iconOrEmoji,
                                            colorValue: item.colorValue,
                                            size: 38,
                                            fontSize: 18,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.categoryName,
                                                  style: AppTypography.bodyLarge
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.percentage.toStringAsFixed(1)}% of total',
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                    color: AppColors.textTertiary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            AppFormatters.currency(item.amount),
                                            style: AppTypography.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (item.percentage / 100).clamp(0.0, 1.0),
                                          backgroundColor: AppColors.surfaceHover,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(item.colorValue),
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
