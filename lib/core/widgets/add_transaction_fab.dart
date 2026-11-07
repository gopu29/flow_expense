import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';

const double _kButtonSize = 56;

/// Bottom-right '+' button that opens the add-transaction screen.
class AddTransactionFab extends StatelessWidget {
  final VoidCallback onTap;

  const AddTransactionFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add transaction',
      child: GestureDetector(
        onTap: () {
          AppHaptics.lightImpact();
          onTap();
        },
        child: Container(
          width: _kButtonSize,
          height: _kButtonSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F5F9), Color(0xFFD3DFEB)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF0D1620),
            size: 32,
          ),
        ),
      ),
    );
  }
}
