import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/numpad_3d_key.dart';
import '../../../core/widgets/animated_typing_amount_text.dart';

/// Flagship category budget keypad modal sheet matching Quanto reference mockup.
/// Dynamically updates the "budget left" in the header in real-time as the user types.
class CategoryBudgetNumpadSheet extends StatefulWidget {
  final String title;
  final double availableBudget;
  final double initialAmount;
  final ValueChanged<double> onConfirmed;

  const CategoryBudgetNumpadSheet({
    super.key,
    required this.title,
    required this.availableBudget,
    required this.initialAmount,
    required this.onConfirmed,
  });

  static Future<double?> show(
    BuildContext context, {
    required String title,
    required double availableBudget,
    required double initialAmount,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryBudgetNumpadSheet(
        title: title,
        availableBudget: availableBudget,
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
    // Dynamically calculate budget left as the user types
    final currentAmount = double.tryParse(_amountString) ?? 0.0;
    final dynamicBudgetLeft = widget.availableBudget - currentAmount;
    final isOverBudget = dynamicBudgetLeft < 0;

    final subtitleText = isOverBudget
        ? '-${AppFormatters.currency(dynamicBudgetLeft.abs())} budget left'
        : '${AppFormatters.currency(dynamicBudgetLeft)} budget left';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF162330),
            Color(0xFF0F1722),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2B3F54),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Grab Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Header Bar: Left circular back button + Centered Title & Dynamic Subtitle
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E2D3E), Color(0xFF141F2B)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2C3E52),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 15,
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
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            color: isOverBudget
                                ? const Color(0xFFF43F5E)
                                : const Color(0xFF7E91A4),
                            fontSize: 13,
                            fontWeight:
                                isOverBudget ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: Text(
                            subtitleText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Balance spacing for back button
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 32),

              // 3. Huge Centered Amount Display with typing/erasing animation & tactile Backspace button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedTypingAmountText(
                    text: _amountString,
                    prefix: '₹',
                    prefixStyle: const TextStyle(
                      color: Color(0xFF8E9BAE),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_amountString != '0')
                    Numpad3DKey(
                      icon: Icons.backspace_outlined,
                      expanded: false,
                      height: 34,
                      onTap: _onDelete,
                      onLongPress: _onClear,
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),

              const SizedBox(height: 34),

              // 4. On-Screen 3D Keypad (1-9, ., 0, →)
              _buildNumpad(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          children: [
            Numpad3DKey(label: '1', onTap: () => _onKeyPress('1')),
            Numpad3DKey(label: '2', onTap: () => _onKeyPress('2')),
            Numpad3DKey(label: '3', onTap: () => _onKeyPress('3')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Numpad3DKey(label: '4', onTap: () => _onKeyPress('4')),
            Numpad3DKey(label: '5', onTap: () => _onKeyPress('5')),
            Numpad3DKey(label: '6', onTap: () => _onKeyPress('6')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Numpad3DKey(label: '7', onTap: () => _onKeyPress('7')),
            Numpad3DKey(label: '8', onTap: () => _onKeyPress('8')),
            Numpad3DKey(label: '9', onTap: () => _onKeyPress('9')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Numpad3DKey(label: '.', onTap: () => _onKeyPress('.')),
            Numpad3DKey(label: '0', onTap: () => _onKeyPress('0')),
            Numpad3DKey(
              icon: Icons.arrow_forward_rounded,
              isAction: true,
              onTap: _onSubmit,
            ),
          ],
        ),
      ],
    );
  }
}
