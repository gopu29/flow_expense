import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flagship category budget keypad modal sheet matching Quanto reference mockup.
class CategoryBudgetNumpadSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final double initialAmount;
  final ValueChanged<double> onConfirmed;

  const CategoryBudgetNumpadSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialAmount,
    required this.onConfirmed,
  });

  static Future<double?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double initialAmount,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CategoryBudgetNumpadSheet(
        title: title,
        subtitle: subtitle,
        initialAmount: initialAmount,
        onConfirmed: (val) => Navigator.pop(ctx, val),
      ),
    );
  }

  @override
  State<CategoryBudgetNumpadSheet> createState() =>
      _CategoryBudgetNumpadSheetState();
}

class _CategoryBudgetNumpadSheetState extends State<CategoryBudgetNumpadSheet> {
  late String _amountString;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      if (widget.initialAmount % 1 == 0) {
        _amountString = widget.initialAmount.toInt().toString();
      } else {
        _amountString = widget.initialAmount.toString();
      }
    } else {
      _amountString = '0';
    }
  }

  void _onKeyPress(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (val == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0') {
          _amountString = val;
        } else if (_amountString.length < 9) {
          _amountString += val;
        }
      }
    });
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amountString.length > 1) {
        _amountString = _amountString.substring(0, _amountString.length - 1);
      } else {
        _amountString = '0';
      }
    });
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountString = '0';
    });
  }

  void _onSubmit() {
    HapticFeedback.mediumImpact();
    final value = double.tryParse(_amountString) ?? 0.0;
    widget.onConfirmed(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Grab Handle
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 2. Header Bar: Left circular back button + Centered Title & Subtitle
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2633),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF28394C),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7E91A4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Balance spacing for back button
                const SizedBox(width: 40),
              ],
            ),

            const SizedBox(height: 38),

            // 3. Huge Centered Amount Display with Backspace button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '₹',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _amountString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 12),
                if (_amountString != '0')
                  GestureDetector(
                    onTap: _onDelete,
                    onLongPress: _onClear,
                    child: Container(
                      width: 36,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2936),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2B3C4E),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: Color(0xFF8E9BAE),
                        size: 16,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 36),
              ],
            ),

            const SizedBox(height: 40),

            // 4. On-Screen Custom Keypad (1-9, ., 0, →)
            _buildNumpad(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          children: [
            _buildKey('1'),
            const SizedBox(width: 10),
            _buildKey('2'),
            const SizedBox(width: 10),
            _buildKey('3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKey('4'),
            const SizedBox(width: 10),
            _buildKey('5'),
            const SizedBox(width: 10),
            _buildKey('6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKey('7'),
            const SizedBox(width: 10),
            _buildKey('8'),
            const SizedBox(width: 10),
            _buildKey('9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKey('.'),
            const SizedBox(width: 10),
            _buildKey('0'),
            const SizedBox(width: 10),
            _buildActionKey(
              icon: Icons.arrow_forward_rounded,
              onTap: _onSubmit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(label),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2531),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF263444),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF202E3D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2F445A),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
