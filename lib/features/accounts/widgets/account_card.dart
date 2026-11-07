import 'package:flutter/material.dart';
import '../../../core/widgets/animated_amount_text.dart';
import '../../../models/account.dart';

/// Ultra-premium Account card matching Quanto IMG_6032.PNG:
/// - Refined obsidian surface gradient (#172433 -> #0F1722)
/// - Top-lit border highlight (#243649) and soft elevation drop shadow
/// - Squircle emoji/icon container (#223547 -> #162330) with fine border
/// - Crisp typography with tabular figures and interactive press scale
class AccountCard extends StatefulWidget {
  final Account account;
  final VoidCallback? onTap;
  final Widget? dragHandle;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.dragHandle,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF172433),
              Color(0xFF0F1722),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF243649),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.transparent,
            highlightColor: Colors.white.withValues(alpha: 0.04),
            onHighlightChanged: (highlighted) {
              setState(() => _isPressed = highlighted);
            },
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Squircle Icon / Emoji Box with multi-layer depth
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF223547),
                          Color(0xFF162330),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2E4358),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.account.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Account Name & Rolling Balance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.name,
                          style: const TextStyle(
                            color: Color(0xFF9AB0C2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedAmountText(
                          amount: widget.account.balance,
                          style: TextStyle(
                            color: widget.account.balance >= 0
                                ? Colors.white
                                : const Color(0xFFF87171),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Drag Handle '=' matching IMG_6032.PNG
                  if (widget.dragHandle != null)
                    widget.dragHandle!
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 2.2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A7288),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4.5),
                          Container(
                            width: 18,
                            height: 2.2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A7288),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
