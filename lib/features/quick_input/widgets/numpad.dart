import 'package:flutter/material.dart';
import '../../../core/utils/amount_expression.dart';
import '../../../core/widgets/numpad_3d_key.dart';

/// Custom 3D tactile numpad matching Quanto's sleek on-screen keypad with realistic depth.
class CustomNumpad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final ValueChanged<String> onOperator;
  final VoidCallback onSubmit;
  final bool showOperators;

  const CustomNumpad({
    super.key,
    required this.onKeyPress,
    required this.onOperator,
    required this.onSubmit,
    this.showOperators = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showOperators) ...[
          Row(
            children: [
              for (final operator in amountOperators)
                Numpad3DKey(
                  label: operator,
                  isAction: true,
                  height: 44,
                  onTap: () => onOperator(operator),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((key) => Numpad3DKey(
                label: key,
                height: 52,
                onTap: () => onKeyPress(key),
              ))
          .toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Numpad3DKey(
          label: '.',
          height: 52,
          onTap: () => onKeyPress('.'),
        ),
        Numpad3DKey(
          label: '0',
          height: 52,
          onTap: () => onKeyPress('0'),
        ),
        Numpad3DKey(
          icon: Icons.arrow_forward_rounded,
          isAction: true,
          height: 52,
          onTap: onSubmit,
        ),
      ],
    );
  }
}
