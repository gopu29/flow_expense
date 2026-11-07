import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Smooth, high-performance counting number animation for financial figures.
class AnimatedAmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedAmountText({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: amount),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(
          AppFormatters.currency(value),
          style: style,
        );
      },
    );
  }
}
