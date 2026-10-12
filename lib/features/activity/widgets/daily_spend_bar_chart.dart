import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/transaction.dart';

/// Ultra-sleek, borderless daily spending bar chart matching Quanto (IMG_6026.PNG).
/// Features 31-day vertical slot tracks, bright spend bars, dashed average line,
/// and right-aligned Y-axis labels.
class DailySpendBarChart extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime selectedMonth;

  const DailySpendBarChart({
    super.key,
    required this.transactions,
    required this.selectedMonth,
  });

  @override
  State<DailySpendBarChart> createState() => _DailySpendBarChartState();
}

class _DailySpendBarChartState extends State<DailySpendBarChart> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month + 1,
      0,
    ).day;

    // Calculate daily expenses
    final Map<int, double> dailyTotals = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0.0;
    }

    double totalMonthSpend = 0.0;
    for (final tx in widget.transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == widget.selectedMonth.year &&
          tx.date.month == widget.selectedMonth.month) {
        final d = tx.date.day;
        dailyTotals[d] = (dailyTotals[d] ?? 0.0) + tx.amount;
        totalMonthSpend += tx.amount;
      }
    }

    double maxSpend = 0.0;
    dailyTotals.forEach((_, val) {
      if (val > maxSpend) maxSpend = val;
    });

    if (maxSpend <= 0) maxSpend = 1000.0;

    final now = DateTime.now();
    final isCurrentMonth = widget.selectedMonth.year == now.year &&
        widget.selectedMonth.month == now.month;
    final activeDays = isCurrentMonth ? now.day : daysInMonth;
    final avgSpend = activeDays > 0 ? (totalMonthSpend / activeDays) : 0.0;

    String formatK(double val) {
      if (val >= 1000) {
        return '${(val / 1000).toStringAsFixed(1)}k';
      }
      return val.toStringAsFixed(0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip display on tap
        if (_selectedDay != null && dailyTotals[_selectedDay!]! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    'Day $_selectedDay: ₹${dailyTotals[_selectedDay!]!.toStringAsFixed(0)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          height: 140,
          child: Row(
            children: [
              // Main Chart Tracks Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = constraints.maxWidth;
                    final chartHeight = constraints.maxHeight - 20; // 20 for x-labels

                    return GestureDetector(
                      onTapDown: (details) {
                        final dx = details.localPosition.dx;
                        final dayWidth = chartWidth / daysInMonth;
                        final tappedDay = ((dx / dayWidth).floor() + 1)
                            .clamp(1, daysInMonth);
                        setState(() {
                          _selectedDay = (_selectedDay == tappedDay) ? null : tappedDay;
                        });
                      },
                      child: CustomPaint(
                        size: Size(chartWidth, constraints.maxHeight),
                        painter: _QuantoBarChartPainter(
                          dailyTotals: dailyTotals,
                          daysInMonth: daysInMonth,
                          maxSpend: maxSpend,
                          avgSpend: avgSpend,
                          selectedDay: _selectedDay,
                          chartHeight: chartHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              // Right-aligned Y-axis labels matching IMG_6026.PNG
              SizedBox(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatK(maxSpend),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      formatK(avgSpend),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '0',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantoBarChartPainter extends CustomPainter {
  final Map<int, double> dailyTotals;
  final int daysInMonth;
  final double maxSpend;
  final double avgSpend;
  final int? selectedDay;
  final double chartHeight;

  _QuantoBarChartPainter({
    required this.dailyTotals,
    required this.daysInMonth,
    required this.maxSpend,
    required this.avgSpend,
    required this.selectedDay,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFF182430)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final selectedBarPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final dashedPaint = Paint()
      ..color = const Color(0xFF3B4E5E).withValues(alpha: 0.85)
      ..strokeWidth = 1.0;

    final slotWidth = size.width / daysInMonth;

    // 1. Draw dashed average horizontal line across the chart
    final avgRatio = (avgSpend / maxSpend).clamp(0.0, 1.0);
    final avgY = chartHeight - (avgRatio * chartHeight);

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset((startX + dashWidth).clamp(0.0, size.width), avgY),
        dashedPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Draw 31-day slot tracks and active spend bars
    for (int day = 1; day <= daysInMonth; day++) {
      final x = (day - 0.5) * slotWidth;
      final spend = dailyTotals[day] ?? 0.0;

      // Background track pillar (subtle dark line spanning chart height)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, chartHeight),
        trackPaint,
      );

      // Active spend bar
      if (spend > 0) {
        final heightRatio = (spend / maxSpend).clamp(0.05, 1.0);
        final barHeight = heightRatio * chartHeight;
        final barTop = chartHeight - barHeight;

        final isSel = selectedDay == day;
        canvas.drawLine(
          Offset(x, chartHeight),
          Offset(x, barTop),
          isSel ? selectedBarPaint : barPaint,
        );
      }
    }

    // 3. Draw X-axis day labels (1, 9, 16, 24, 31) matching IMG_6026.PNG
    final labelDays = [1, 9, 16, 24, daysInMonth];
    final textStyle = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10,
      fontFamily: 'Inter',
    );

    for (final day in labelDays) {
      final textSpan = TextSpan(text: '$day', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final x = (day - 0.5) * slotWidth - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(x, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _QuantoBarChartPainter oldDelegate) {
    return oldDelegate.maxSpend != maxSpend ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.dailyTotals != dailyTotals;
  }
}
