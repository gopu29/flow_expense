import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

class MonthDualBarData {
  final DateTime month;
  final double income;
  final double expense;

  const MonthDualBarData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// Dual-bar chart comparing Income vs Expense over past 6 months matching Quanto IMG_6029.PNG.
class IncomeVsExpenseChart extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime selectedMonth;

  const IncomeVsExpenseChart({
    super.key,
    required this.transactions,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Generate data for 6 months ending at selectedMonth
    final monthsData = List.generate(6, (i) {
      final m = DateTime(selectedMonth.year, selectedMonth.month - 5 + i, 1);
      double inc = 0.0;
      double exp = 0.0;

      for (final tx in transactions) {
        if (tx.date.year == m.year && tx.date.month == m.month) {
          if (tx.type == TransactionType.income) {
            inc += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            exp += tx.amount;
          }
        }
      }

      return MonthDualBarData(month: m, income: inc, expense: exp);
    });

    // Current selected month totals for header
    final currentMonthData = monthsData.last;

    // Determine max value for Y-axis scaling
    double maxVal = 0.0;
    for (final d in monthsData) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expense > maxVal) maxVal = d.expense;
    }
    if (maxVal <= 0) maxVal = 1000.0;

    // Y-Axis labels
    final yMaxLabel = AppFormatters.compact(maxVal);
    final yMidLabel = AppFormatters.compact(maxVal / 2);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1E2A38),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Metrics Header matching IMG_6029.PNG
          Row(
            children: [
              // Income Metric
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Income',
                          style: TextStyle(
                            color: Color(0xFF8E9BAE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.currency(currentMonthData.income),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Expenses Metric
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            color: Color(0xFF8E9BAE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.currency(currentMonthData.expense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart Bars and Right Y-Axis
          LayoutBuilder(
            builder: (context, constraints) {
              const chartHeight = 170.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Chart Bars Area
                  Expanded(
                    child: SizedBox(
                      height: chartHeight + 36, // bars + month labels
                      child: Column(
                        children: [
                          // Vertical Bars / Horizontal Dashes
                          SizedBox(
                            height: chartHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: monthsData.map((data) {
                                final incHeight = maxVal > 0
                                    ? (data.income / maxVal) * (chartHeight - 14)
                                    : 0.0;
                                final expHeight = maxVal > 0
                                    ? (data.expense / maxVal) * (chartHeight - 14)
                                    : 0.0;

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Income Bar (Mint Green)
                                    _buildBarOrDash(
                                      height: incHeight,
                                      hasValue: data.income > 0,
                                      color: const Color(0xFF34D399),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF34D399),
                                          Color(0xFF059669),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Expense Bar (Bright Cyan)
                                    _buildBarOrDash(
                                      height: expHeight,
                                      hasValue: data.expense > 0,
                                      color: const Color(0xFF38BDF8),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF38BDF8),
                                          Color(0xFF0284C7),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Month Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: monthsData.map((data) {
                              final isCurrent = data.month.year == selectedMonth.year &&
                                  data.month.month == selectedMonth.month;
                              final label = DateFormat('MMM').format(data.month);

                              if (isCurrent) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF283647),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              return Text(
                                label,
                                style: const TextStyle(
                                  color: Color(0xFF6B7E93),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Y-Axis Labels (e.g. 28k, 14k, 0) matching IMG_6029.PNG
                  SizedBox(
                    height: chartHeight + 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          yMaxLabel,
                          style: const TextStyle(
                            color: Color(0xFF6B7E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          yMidLabel,
                          style: const TextStyle(
                            color: Color(0xFF6B7E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          '0',
                          style: TextStyle(
                            color: Color(0xFF6B7E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22), // matches month label height
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarOrDash({
    required double height,
    required bool hasValue,
    required Color color,
    required Gradient gradient,
  }) {
    if (!hasValue || height <= 0) {
      // Horizontal dash pill on baseline matching IMG_6029.PNG
      return Container(
        width: 13,
        height: 3.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Tall vertical pill bar
    return Container(
      width: 13,
      height: height.clamp(8.0, 170.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
