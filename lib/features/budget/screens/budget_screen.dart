import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../../../models/transaction.dart';
import '../widgets/budget_gauge.dart';

/// Budget Screen featuring circular gauge and category-specific spending caps.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    Budget? currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget != null && currentBudget.monthlyLimit > 0
          ? currentBudget.monthlyLimit.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Monthly Budget Limit', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            hintText: 'e.g. 25000',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceHover,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(controller.text) ?? 0.0;
              final monthKey =
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';

              final budget = Budget(
                id: currentBudget?.id ?? const Uuid().v4(),
                profileName: 'Personal',
                monthlyLimit: limit,
                categoryLimits: currentBudget?.categoryLimits ?? const {},
                monthYear: monthKey,
              );

              final repo = ref.read(repositoryProvider);
              await repo.saveBudget(budget);
              ref.invalidate(budgetProvider);

              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final budgetAsync = ref.watch(budgetProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

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
              // Header
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
                  Text('Budget Planner', style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: budgetAsync.when(
                  data: (budget) {
                    final limit = budget?.monthlyLimit ?? 0.0;
                    final remaining = limit > 0 ? limit - monthlyExpense : 0.0;

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: [
                        // Circular Gauge Card
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              BudgetGauge(
                                spent: monthlyExpense,
                                limit: limit,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text('Spent', style: AppTypography.caption),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppFormatters.compact(monthlyExpense),
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: AppColors.surfaceBorder,
                                  ),
                                  Column(
                                    children: [
                                      Text('Remaining', style: AppTypography.caption),
                                      const SizedBox(height: 2),
                                      Text(
                                        limit > 0
                                            ? AppFormatters.compact(remaining)
                                            : 'No Cap',
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: limit > 0 && remaining < 0
                                              ? AppColors.expense
                                              : AppColors.income,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: AppColors.surfaceBorder,
                                  ),
                                  Column(
                                    children: [
                                      Text('Limit', style: AppTypography.caption),
                                      const SizedBox(height: 2),
                                      Text(
                                        limit > 0
                                            ? AppFormatters.compact(limit)
                                            : 'Not Set',
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showSetBudgetDialog(
                                  context,
                                  ref,
                                  selectedDate,
                                  budget,
                                ),
                                icon: const Icon(Icons.tune, size: 16),
                                label: Text(limit > 0 ? 'Edit Limit' : 'Set Monthly Budget'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceHover,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: AppColors.surfaceBorder,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('Category Breakdown', style: AppTypography.titleMedium),
                        const SizedBox(height: 8),

                        // List of categories and their spending vs limits
                        categoriesAsync.when(
                          data: (categories) {
                            return transactionsAsync.when(
                              data: (txs) {
                                final monthTxs = txs
                                    .where((t) =>
                                        t.type == TransactionType.expense &&
                                        t.date.year == selectedDate.year &&
                                        t.date.month == selectedDate.month)
                                    .toList();

                                final Map<String, double> catSpent = {};
                                for (final tx in monthTxs) {
                                  catSpent[tx.categoryId] =
                                      (catSpent[tx.categoryId] ?? 0.0) +
                                          tx.amount;
                                }

                                final expenseCats = categories
                                    .where((c) => c.type == CategoryType.expense)
                                    .toList();

                                return Column(
                                  children: expenseCats.map((cat) {
                                    final spent = catSpent[cat.id] ?? 0.0;
                                    final catLimit =
                                        budget?.categoryLimits[cat.id] ?? 0.0;
                                    final ratio = catLimit > 0
                                        ? spent / catLimit
                                        : (monthlyExpense > 0
                                            ? spent / monthlyExpense
                                            : 0.0);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.surfaceBorder
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              CategoryIconBadge(
                                                iconOrEmoji: cat.iconOrEmoji,
                                                colorValue: cat.color,
                                                size: 38,
                                                fontSize: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  cat.name,
                                                  style: AppTypography.bodyLarge
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                AppFormatters.currency(spent),
                                                style: AppTypography.bodyLarge
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: ratio.clamp(0.0, 1.0),
                                              backgroundColor:
                                                  AppColors.surfaceHover,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(cat.color),
                                              ),
                                              minHeight: 5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (_, _) => const SizedBox(),
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (_, _) => const SizedBox(),
                        ),
                      ],
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
