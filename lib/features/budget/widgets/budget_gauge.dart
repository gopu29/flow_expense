import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

/// Flagship circular progress ring matching Quanto (IMG_6028.PNG).
/// Displays a full 360-degree circular ring with centered timeframe dropdown,
/// large bold remaining balance, and total budget limit.
class BudgetGauge extends StatelessWidget {
  final double spent;
  final double limit;
  final String timeframeLabel;
  final VoidCallback onTimeframeTap;

  const BudgetGauge({
    super.key,
    required this.spent,
    required this.limit,
    required this.timeframeLabel,
    required this.onTimeframeTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = limit > 0 ? limit - spent : -spent;
    final isOverBudget = remaining < 0;

    // Active progress ratio (0.0 to 1.0)
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    // Glowing coral crimson when over budget, vibrant emerald when safe
    final ringColor = isOverBudget
        ? const Color(0xFFF43F5E)
        : const Color(0xFF10B981);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 260),
            painter: _FullCircleBudgetPainter(
              progress: isOverBudget ? 1.0 : progress,
              ringColor: ringColor,
              trackColor: isOverBudget
                  ? const Color(0xFF4C121E)
                  : const Color(0xFF182330),
              isOverBudget: isOverBudget,
            ),
          ),

          // Center Text: "Left this month ⌵" + "-₹16,656.59" + "of ₹10,000"
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onTimeframeTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeframeLabel,
                        style: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF8E9BAE),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Main Balance (e.g. -₹16,656.59 or ₹5,400.00)
              Text(
                remaining < 0
                    ? '-${AppFormatters.currency(remaining.abs())}'
                    : AppFormatters.currency(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),

              // Subtext: "of ₹10,000"
              Text(
                'of ${AppFormatters.currency(limit)}',
                style: const TextStyle(
                  color: Color(0xFF7E91A4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullCircleBudgetPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final bool isOverBudget;

  _FullCircleBudgetPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.isOverBudget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 20.0;

    // Background full circular track
    final bgPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    if (isOverBudget) {
      // Full solid crimson ring matching Quanto IMG_6028.PNG
      final overPaint = Paint()
        ..color = ringColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius, overPaint);
    } else if (progress > 0) {
      // Active progress arc starting from top (-90 degrees)
      final progressPaint = Paint()
        ..color = ringColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullCircleBudgetPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.isOverBudget != isOverBudget;
  }
}
