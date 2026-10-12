import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

class MonthIncomeLeftData {
  final DateTime month;
  final double income;
  final double expense;
  final double netSaved;

  const MonthIncomeLeftData({
    required this.month,
    required this.income,
    required this.expense,
    required this.netSaved,
  });
}

/// "Income left" card matching Quanto IMG_6029.PNG & IMG_6030.PNG.
/// Supports switching between currency balance and percentage savings,
/// and displays the 6-month progression with the glowing magenta active month pill.
class IncomeLeftCard extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime selectedMonth;

  const IncomeLeftCard({
    super.key,
    required this.transactions,
    required this.selectedMonth,
  });

  @override
  State<IncomeLeftCard> createState() => _IncomeLeftCardState();
}

class _IncomeLeftCardState extends State<IncomeLeftCard> {
  bool _isPercentageMode = false;

  @override
  Widget build(BuildContext context) {
    // 6-month historical calculations
    final monthsData = List.generate(6, (i) {
      final m = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month - 5 + i,
        1,
      );
      double inc = 0.0;
      double exp = 0.0;

      for (final tx in widget.transactions) {
        if (tx.date.year == m.year && tx.date.month == m.month) {
          if (tx.type == TransactionType.income) {
            inc += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            exp += tx.amount;
          }
        }
      }

      return MonthIncomeLeftData(
        month: m,
        income: inc,
        expense: exp,
        netSaved: inc - exp,
      );
    });

    final currentMonth = monthsData.last;
    final netSaved = currentMonth.netSaved;
    final savingsRate = currentMonth.income > 0
        ? ((netSaved / currentMonth.income) * 100).clamp(-100.0, 100.0)
        : 0.0;

    // Max value for Y-axis
    double maxVal = 0.0;
    for (final d in monthsData) {
      if (d.netSaved > maxVal) maxVal = d.netSaved;
    }
    if (maxVal <= 0) maxVal = 500.0;

    final yMaxLabel = AppFormatters.compact(maxVal);

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
          // Header Row: Title & Toggle Switcher matching IMG_6029.PNG
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Income left',
                style: TextStyle(
                  color: Color(0xFF8E9BAE),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Currency vs Percentage Switcher Pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2734),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF263747), width: 0.8),
                ),
                child: Row(
                  children: [
                    // Coin/Stack icon
                    GestureDetector(
                      onTap: () => setState(() => _isPercentageMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: !_isPercentageMode
                              ? const Color(0xFF2B3A4C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.layers_outlined,
                          size: 16,
                          color: !_isPercentageMode
                              ? Colors.white
                              : const Color(0xFF6B7E93),
                        ),
                      ),
                    ),

                    // Percent icon
                    GestureDetector(
                      onTap: () => setState(() => _isPercentageMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isPercentageMode
                              ? const Color(0xFF2B3A4C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.percent_rounded,
                          size: 16,
                          color: _isPercentageMode
                              ? Colors.white
                              : const Color(0xFF6B7E93),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Large Amount / Percentage Display
          Text(
            _isPercentageMode
                ? '${savingsRate >= 0 ? '' : '-'}${savingsRate.abs().toStringAsFixed(1)}%'
                : AppFormatters.currency(netSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 20),

          // 6-Month Progression Chart matching IMG_6030.PNG
          LayoutBuilder(
            builder: (context, constraints) {
              const chartHeight = 84.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Chart area with baseline
                        SizedBox(
                          height: chartHeight,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Dashed baseline
                              Positioned(
                                bottom: 2,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFF223142),
                                ),
                              ),

                              // Month items
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: monthsData.map((data) {
                                  final isCurrent = data.month.year ==
                                          widget.selectedMonth.year &&
                                      data.month.month ==
                                          widget.selectedMonth.month;

                                  if (!isCurrent) {
                                    // Inactive months: Horizontal white/gray dash pill
                                    return Container(
                                      width: 26,
                                      height: 3.5,
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }

                                  // Active month: Column track with glowing pink/magenta pill
                                  final pillHeight = maxVal > 0
                                      ? (data.netSaved.clamp(0.0, maxVal) /
                                              maxVal) *
                                          (chartHeight - 16)
                                      : 0.0;

                                  return Container(
                                    width: 32,
                                    height: chartHeight,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF162330)
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF243547)
                                            .withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 32,
                                      height: (pillHeight > 22
                                              ? pillHeight
                                              : 22.0)
                                          .clamp(22.0, chartHeight),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFF472B6), // Light Pink
                                            Color(0xFFEC4899), // Deep Magenta
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEC4899)
                                                .withValues(alpha: 0.65),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Month Labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: monthsData.map((data) {
                            final isCurrent = data.month.year ==
                                    widget.selectedMonth.year &&
                                data.month.month == widget.selectedMonth.month;
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

                  const SizedBox(width: 14),

                  // Right Y-Axis (max value and 0) matching IMG_6030.PNG
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
                        const Text(
                          '0',
                          style: TextStyle(
                            color: Color(0xFF6B7E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
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
}
