import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

/// Calendar Heatmap visualizing daily spending and income intensity matching Quanto IMG_6030.PNG.
class CalendarHeatmap extends StatefulWidget {
  final DateTime selectedMonth;
  final List<Transaction> transactions;

  const CalendarHeatmap({
    super.key,
    required this.selectedMonth,
    required this.transactions,
  });

  @override
  State<CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends State<CalendarHeatmap> {
  int? _selectedDay;

  void _showDayDetailsSheet(int day, List<Transaction> dayTxs, double expense, double income) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(
          DateTime(widget.selectedMonth.year, widget.selectedMonth.month, day),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (expense > 0)
                      Text(
                        'Total spent: ${AppFormatters.currency(expense)}   ',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (income > 0)
                      Text(
                        'Total income: +${AppFormatters.currency(income)}',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (dayTxs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No transactions on this day',
                        style: TextStyle(color: Color(0xFF6B7E93)),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: dayTxs.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: Color(0xFF1E2A38),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final tx = dayTxs[index];
                        final isExpense = tx.type == TransactionType.expense;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tx.note?.isNotEmpty == true
                                ? tx.note!
                                : tx.categoryId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('hh:mm a').format(tx.date),
                            style: const TextStyle(
                              color: Color(0xFF6B7E93),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            '${isExpense ? '-' : '+'}${AppFormatters.currency(tx.amount)}',
                            style: TextStyle(
                              color: isExpense
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF34D399),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    final daysInMonth =
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 0)
            .day;
    // 1 = Monday, 7 = Sunday
    final startingWeekday = firstDayOfMonth.weekday;

    // Aggregate daily expenses and incomes
    final Map<int, double> dailySpend = {};
    final Map<int, double> dailyIncome = {};
    final Map<int, List<Transaction>> dailyTransactions = {};

    for (final tx in widget.transactions) {
      if (tx.date.year == widget.selectedMonth.year &&
          tx.date.month == widget.selectedMonth.month) {
        final day = tx.date.day;
        dailyTransactions.putIfAbsent(day, () => []).add(tx);

        if (tx.type == TransactionType.expense) {
          dailySpend[day] = (dailySpend[day] ?? 0.0) + tx.amount;
        } else if (tx.type == TransactionType.income) {
          dailyIncome[day] = (dailyIncome[day] ?? 0.0) + tx.amount;
        }
      }
    }

    final totalSlots = (startingWeekday - 1) + daysInMonth;

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
          // Header title matching IMG_6030.PNG
          const Text(
            'Calendar',
            style: TextStyle(
              color: Color(0xFF8E9BAE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Weekday columns: M T W T F S S
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF6B7E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 7-Column Heatmap Grid matching IMG_6030.PNG
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.88,
            ),
            itemCount: totalSlots,
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                // Empty offset slot before 1st of month
                return const SizedBox.shrink();
              }

              final day = index - (startingWeekday - 1) + 1;
              final spend = dailySpend[day] ?? 0.0;
              final inc = dailyIncome[day] ?? 0.0;
              final dayTxs = dailyTransactions[day] ?? [];
              final isSelected = _selectedDay == day;

              final hasActivity = spend > 0 || inc > 0;
              final isIncomeDay = inc > 0 && (inc >= spend || spend == 0);

              // Background and Text colors
              Color cellBg;
              Color dayTextColor;
              Widget valueWidget;

              if (hasActivity) {
                // Vibrant Cyan/Blue Squircle matching IMG_6030.PNG
                cellBg = const Color(0xFF0284C7);
                dayTextColor = const Color(0xFFE0F2FE);

                if (isIncomeDay) {
                  // Mint green text with + prefix for income
                  valueWidget = Text(
                    '+${AppFormatters.compact(inc)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34D399), // Mint Green
                    ),
                  );
                } else {
                  // Bold white text for expense
                  valueWidget = Text(
                    AppFormatters.compact(spend),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }
              } else {
                // Zero / Empty day: Dark Navy squircle matching IMG_6030.PNG
                cellBg = const Color(0xFF18222C);
                dayTextColor = const Color(0xFF6B7E93);
                valueWidget = const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = day);
                  _showDayDetailsSheet(day, dayTxs, spend, inc);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.transparent,
                      width: isSelected ? 1.5 : 0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasActivity
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: dayTextColor,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: valueWidget,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
