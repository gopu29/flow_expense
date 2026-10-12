import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

/// Calendar Heatmap visualizing daily spending intensity matching Quanto.
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

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    final daysInMonth =
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 0)
            .day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Aggregate daily expenses
    final Map<int, double> dailySpend = {};
    for (final tx in widget.transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == widget.selectedMonth.year &&
          tx.date.month == widget.selectedMonth.month) {
        dailySpend[tx.date.day] =
            (dailySpend[tx.date.day] ?? 0.0) + tx.amount;
      }
    }

    double maxDaily = 0.0;
    dailySpend.forEach((_, val) {
      if (val > maxDaily) maxDaily = val;
    });

    final now = DateTime.now();
    final isCurrentMonth = widget.selectedMonth.year == now.year &&
        widget.selectedMonth.month == now.month;

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
            return SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Grid of days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.85,
          ),
          itemCount: (startingWeekday - 1) + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startingWeekday - 1) {
              return const SizedBox.shrink(); // Empty slot before month start
            }

            final day = index - (startingWeekday - 1) + 1;
            final spend = dailySpend[day] ?? 0.0;
            final isToday = isCurrentMonth && day == now.day;
            final isSelected = _selectedDay == day;

            Color cellBg = AppColors.surfaceHover.withOpacity(0.4);
            if (spend > 0) {
              final intensity = maxDaily > 0 ? (spend / maxDaily).clamp(0.2, 1.0) : 0.3;
              cellBg = AppColors.chartBar.withOpacity(0.2 + (intensity * 0.6));
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = _selectedDay == day ? null : day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: cellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : isToday
                            ? AppColors.accent.withOpacity(0.6)
                            : Colors.transparent,
                    width: isSelected || isToday ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$day',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight:
                            isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (spend > 0)
                      FittedBox(
                        child: Text(
                          AppFormatters.compact(spend),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),

        if (_selectedDay != null && dailySpend[_selectedDay!] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMMM').format(widget.selectedMonth)} $_selectedDay',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppFormatters.currency(dailySpend[_selectedDay!]!),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
