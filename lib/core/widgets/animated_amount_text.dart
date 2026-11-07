import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Smooth, high-performance counting number animation for financial figures.
class AnimatedAmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  /// Masks the amount when the Hide balances setting is on.
  final bool isBalance;

  const AnimatedAmountText({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isBalance && AppFormatters.hideBalances) {
      return Text(AppFormatters.balance(amount), style: style);
    }
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
