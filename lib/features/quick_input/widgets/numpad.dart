import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Custom numpad matching Quanto's sleek on-screen keypad with tactile press micro-animations.
class CustomNumpad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const CustomNumpad({
    super.key,
    required this.onKeyPress,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 10),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((key) => _NumpadButton(
                value: key,
                onTap: () => onKeyPress(key),
              ))
          .toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _NumpadButton(
          value: '.',
          onTap: () => onKeyPress('.'),
        ),
        _NumpadButton(
          value: '0',
          onTap: () => onKeyPress('0'),
        ),
        _NumpadButton(
          icon: Icons.backspace_outlined,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String? value;
  final IconData? icon;
  final VoidCallback onTap;

  const _NumpadButton({
    this.value,
    this.icon,
    required this.onTap,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 54,
              decoration: BoxDecoration(
                color: _isPressed
                    ? AppColors.surfaceHover
                    : AppColors.surfaceHover.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.surfaceBorder.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      color: AppColors.textSecondary,
                      size: 22,
                    )
                  : Text(
                      widget.value!,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
