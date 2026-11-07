import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

/// Flagship circular progress ring matching Quanto (IMG_6028.PNG)
/// with animated progress sweep and smooth balance transitions.
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
    final targetProgress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    // Glowing coral crimson when over budget, vibrant emerald when safe
    final ringColor = isOverBudget
        ? const Color(0xFFF43F5E)
        : const Color(0xFF10B981);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Smooth animated circular progress ring
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: isOverBudget ? 1.0 : targetProgress),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return CustomPaint(
                  size: const Size(260, 260),
                  painter: _FullCircleBudgetPainter(
                    progress: animatedProgress,
                    ringColor: ringColor,
                    trackColor: isOverBudget
                        ? const Color(0xFF4C121E)
                        : const Color(0xFF182330),
                    isOverBudget: isOverBudget,
                  ),
                );
              },
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

                // Main Balance (smooth animated rolling counter)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: remaining),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    final isNeg = val < 0;
                    return Text(
                      isNeg
                          ? '-${AppFormatters.currency(val.abs())}'
                          : AppFormatters.currency(val),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),

                // Subtext: "of ₹10,000"
                Text(
                  'of ${AppFormatters.currency(limit)}',
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FullCircleBudgetPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final bool isOverBudget;

  const _FullCircleBudgetPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.isOverBudget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    // 1. Background full track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      final activePaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;

      // Start at top center (-pi / 2)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullCircleBudgetPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isOverBudget != isOverBudget;
  }
}
