import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/account.dart';

/// Account row card matching Quanto IMG_6032.PNG:
/// - Rounded container (#16202A) with border (#1E2A38)
/// - Left squircle emoji/icon container (#1E2936)
/// - Middle column: Account name (#8E9BAE) and Balance (Bold White)
/// - Right reorder handle: Two parallel horizontal bars (#6B7E93)
class AccountCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16202A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1E2A38),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Squircle Icon / Emoji Box matching IMG_6032.PNG
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2936),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    account.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Account Name & Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.currency(account.balance),
                        style: TextStyle(
                          color: account.balance >= 0
                              ? Colors.white
                              : const Color(0xFFF87171),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Drag Handle '=' matching IMG_6032.PNG
                if (dragHandle != null)
                  dragHandle!
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
                            color: const Color(0xFF6B7E93),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4.5),
                        Container(
                          width: 18,
                          height: 2.2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B7E93),
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
    );
  }
}
