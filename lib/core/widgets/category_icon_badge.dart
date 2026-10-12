import 'package:flutter/material.dart';

/// Renders a category's icon/emoji inside a styled rounded container.
class CategoryIconBadge extends StatelessWidget {
  final String iconOrEmoji;
  final int colorValue;
  final double size;
  final double fontSize;

  const CategoryIconBadge({
    super.key,
    required this.iconOrEmoji,
    this.colorValue = 0xFF6366F1,
    this.size = 40,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(colorValue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: baseColor.withOpacity(0.35),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        iconOrEmoji,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}
