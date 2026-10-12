import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

/// Circular progress gauge showing overall budget health matching Quanto.
class BudgetGauge extends StatelessWidget {
  final double spent;
  final double limit;

  const BudgetGauge({
    super.key,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
    final percentInt = (percentage * 100).toInt();

    final Color gaugeColor = percentage > 1.0
        ? AppColors.expense
        : percentage > 0.85
            ? AppColors.chartOrange
            : AppColors.income;

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _BudgetGaugePainter(
            percentage: percentage.clamp(0.0, 1.0),
            color: gaugeColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  limit > 0 ? '$percentInt%' : 'No Limit',
                  style: AppTypography.amountDisplay.copyWith(
                    fontSize: 34,
                    color: gaugeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.compact(spent)} / ${limit > 0 ? AppFormatters.compact(limit) : '∞'}',
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gaugeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    percentage > 1.0
                        ? 'Over Budget'
                        : limit > 0
                            ? '${(100 - percentInt).clamp(0, 100)}% Left'
                            : 'Set a limit',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: gaugeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetGaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _BudgetGaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track (240 degree arc)
    final bgPaint = Paint()
      ..color = AppColors.surfaceHover
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Draw background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Draw active progress
    if (percentage > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * percentage,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
