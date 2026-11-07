import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

/// Calendar Heatmap visualizing daily spending and income intensity matching Quanto IMG_6030.PNG.
class CalendarHeatmap extends ConsumerStatefulWidget {
  final DateTime selectedMonth;
  final List<Transaction> transactions;

  const CalendarHeatmap({
    super.key,
    required this.selectedMonth,
    required this.transactions,
  });

  @override
  ConsumerState<CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends ConsumerState<CalendarHeatmap> {
  int? _selectedDay;

  void _showDayDetailsSheet(int day, List<Transaction> dayTxs, double expense, double income) {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(
          DateTime(widget.selectedMonth.year, widget.selectedMonth.month, day),
        );

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF162330),
                Color(0xFF0F1722),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Color(0xFF2B3F54),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (expense > 0)
                        Text(
                          'Spent: ${AppFormatters.currency(expense)}   ',
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (income > 0)
                        Text(
                          'Income: +${AppFormatters.currency(income)}',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (dayTxs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transactions on this day',
                          style: TextStyle(color: Color(0xFF6B7E93), fontSize: 13),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (isExpense
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF34D399))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isExpense
                                          ? const Color(0xFFF87171)
                                          : const Color(0xFF34D399))
                                      .withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                isExpense
                                    ? Icons.shopping_bag_outlined
                                    : Icons.arrow_downward_rounded,
                                color: isExpense
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFF34D399),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              tx.note?.isNotEmpty == true
                                  ? tx.note!
                                  : tx.categoryId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('hh:mm a').format(tx.date),
                              style: const TextStyle(
                                color: Color(0xFF8E9BAE),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : '+'}${AppFormatters.currency(tx.amount)}',
                              style: TextStyle(
                                color: isExpense
                                    ? Colors.white
                                    : const Color(0xFF34D399),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
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
    final firstDayOfWeek =
        ref.watch(appSettingsProvider.select((s) => s.firstDayOfWeek));
    final weekdayLabels = firstDayOfWeek == DateTime.sunday
        ? const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Empty cells before the 1st, counted from the chosen first day of week.
    final leadingBlanks = (firstDayOfMonth.weekday - firstDayOfWeek + 7) % 7;

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

    final totalSlots = leadingBlanks + daysInMonth;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16212D),
            Color(0xFF0F1722),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF223446),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
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

          // Weekday columns, starting on the chosen first day of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels.map((day) {
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
              if (index < leadingBlanks) {
                // Empty offset slot before 1st of month
                return const SizedBox.shrink();
              }

              final day = index - leadingBlanks + 1;
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
                cellBg = const Color(0xFFA8834A);
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
                  AppHaptics.selectionClick();
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
                          ? const Color(0xFFD9B77E)
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
