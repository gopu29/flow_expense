import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/transaction.dart';

/// Interactive daily spending bar chart for the selected month.
class DailySpendBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime selectedMonth;

  const DailySpendBarChart({
    super.key,
    required this.transactions,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    // Calculate daily expenses
    final Map<int, double> dailyTotals = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0.0;
    }

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == selectedMonth.year &&
          tx.date.month == selectedMonth.month) {
        dailyTotals[tx.date.day] = (dailyTotals[tx.date.day] ?? 0.0) + tx.amount;
      }
    }

    double maxSpend = 0.0;
    dailyTotals.forEach((_, val) {
      if (val > maxSpend) maxSpend = val;
    });
    if (maxSpend <= 0) maxSpend = 100.0;

    final barGroups = <BarChartGroupData>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final spend = dailyTotals[day] ?? 0.0;
      final isToday = selectedMonth.year == DateTime.now().year &&
          selectedMonth.month == DateTime.now().month &&
          day == DateTime.now().day;

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: spend,
              color: isToday
                  ? AppColors.accent
                  : spend > 0
                      ? AppColors.chartBar
                      : AppColors.surfaceHover,
              width: 5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxSpend * 1.15,
                color: AppColors.surfaceHover.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSpend * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHover,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Day ${group.x}\n₹${rod.toY.toStringAsFixed(0)}',
                  AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
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
                  final day = value.toInt();
                  if (day == 1 || day == 10 || day == 20 || day == daysInMonth) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$day',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
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
          barGroups: barGroups,
        ),
      ),
    );
  }
}
