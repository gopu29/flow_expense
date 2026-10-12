import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

class MonthComparisonData {
  final DateTime month;
  final double income;
  final double expense;

  const MonthComparisonData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// Dual-bar chart comparing Income vs Expense over past 6 months.
class IncomeVsExpenseChart extends StatelessWidget {
  final List<Transaction> transactions;

  const IncomeVsExpenseChart({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Prepare data for past 6 months
    final monthsData = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i, 1);
      double income = 0.0;
      double expense = 0.0;

      for (final tx in transactions) {
        if (tx.date.year == m.year && tx.date.month == m.month) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            expense += tx.amount;
          }
        }
      }

      return MonthComparisonData(month: m, income: income, expense: expense);
    });

    double maxVal = 0.0;
    for (final d in monthsData) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expense > maxVal) maxVal = d.expense;
    }
    if (maxVal <= 0) maxVal = 1000.0;

    final groups = monthsData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.income,
            color: AppColors.income,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: data.expense,
            color: AppColors.expense,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem('Income', AppColors.income),
            const SizedBox(width: 14),
            _buildLegendItem('Spend', AppColors.expense),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceHover,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = monthsData[group.x];
                    final isIncomeRod = rodIndex == 0;
                    return BarTooltipItem(
                      '${DateFormat('MMM').format(data.month)}\n${isIncomeRod ? 'Income' : 'Spend'}: ${AppFormatters.compact(rod.toY)}',
                      AppTypography.caption.copyWith(
                        color: isIncomeRod ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < monthsData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM').format(monthsData[idx].month),
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
