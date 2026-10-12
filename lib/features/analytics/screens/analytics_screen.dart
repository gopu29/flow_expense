import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../widgets/income_vs_expense_chart.dart';
import '../widgets/calendar_heatmap.dart';

/// Analytics Screen providing multi-month comparisons and calendar heatmap.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _viewMode = 0; // 0: Comparisons, 1: Calendar Heatmap

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    final netSaved = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome > 0
        ? ((netSaved / monthlyIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

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
                            AppFormatters.monthYear(selectedDate),
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
                  Text('Financial Analytics', style: AppTypography.caption),
                ],
              ),
              const SizedBox(height: 14),

              // View Mode Selector Pill
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    _buildModeChip('Income vs Spend', 0),
                    _buildModeChip('Calendar Heatmap', 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: [
                        // "Income Left" Card (IMG_6030.PNG)
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Income Left', style: AppTypography.caption),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (netSaved >= 0
                                              ? AppColors.income
                                              : AppColors.expense)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(0)}% Saved',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: netSaved >= 0
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppFormatters.currency(netSaved),
                                style: AppTypography.amountDisplay.copyWith(
                                  fontSize: 32,
                                  color: netSaved >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Earned', style: AppTypography.caption),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppFormatters.compact(monthlyIncome),
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Spent', style: AppTypography.caption),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppFormatters.compact(monthlyExpense),
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_viewMode == 0) ...[
                          Text('6-Month Trend', style: AppTypography.titleMedium),
                          const SizedBox(height: 8),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: IncomeVsExpenseChart(transactions: txs),
                          ),
                        ] else ...[
                          Text('Daily Spend Intensity', style: AppTypography.titleMedium),
                          const SizedBox(height: 8),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: CalendarHeatmap(
                              selectedMonth: selectedDate,
                              transactions: txs,
                            ),
                          ),
                        ],
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

  Widget _buildModeChip(String title, int mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
