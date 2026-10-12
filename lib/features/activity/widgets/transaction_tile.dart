import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';

/// Compact, ultra-clean transaction row matching Quanto (IMG_6026.PNG).
/// Sits inside the unified day-group card with:
/// - Zero red border bleed when idle.
/// - Swipe left to reveal red delete button (stays open on release).
/// - Over-drag further to directly trigger delete action.
class TransactionTile extends ConsumerStatefulWidget {
  final Transaction transaction;
  final bool isFirst;
  final bool isLast;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  ConsumerState<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends ConsumerState<TransactionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _slideAnimation;

  double _dragOffset = 0.0;
  bool _isOpen = false;

  static const double _actionWidth = 76.0;
  static const double _fullSwipeThreshold = 180.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _slideAnimation.value;
        });
      });

    _animController.forward(from: 0.0);
    _isOpen = (target == -_actionWidth);
  }

  void _close() {
    _animateTo(0.0);
  }

  Future<void> _confirmAndDelete(Category? category) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16202A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Delete ${AppFormatters.currency(widget.transaction.amount)} for ${category?.name ?? 'this item'}?',
          style: const TextStyle(
            color: Color(0xFF8FA2B2),
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF8FA2B2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(transactionsProvider.notifier).deleteTransaction(widget.transaction);
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final Category? category = categoriesAsync.maybeWhen(
      data: (cats) => cats.firstWhere(
        (c) => c.id == widget.transaction.categoryId,
        orElse: () => const Category(id: '', name: 'General', iconOrEmoji: '🏷️'),
      ),
      orElse: () => null,
    );

    final Account? account = accountsAsync.maybeWhen(
      data: (accs) => accs.firstWhere(
        (a) => a.id == widget.transaction.accountId,
        orElse: () => const Account(id: '', name: 'Account', type: AccountType.bank),
      ),
      orElse: () => null,
    );

    final isExpense = widget.transaction.type == TransactionType.expense;
    final isIncome = widget.transaction.type == TransactionType.income;

    final amountColor = isExpense
        ? AppColors.textPrimary
        : isIncome
            ? AppColors.income
            : AppColors.transfer;

    final amountPrefix = isIncome ? '+' : '';

    return ClipRect(
      child: Stack(
        children: [
          // 1. Revealed Red Delete Action (ONLY rendered when swiped to avoid red border bleed)
          if (_dragOffset < 0 || _isOpen)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _confirmAndDelete(category),
                  child: Container(
                    width: _actionWidth + 30,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    color: const Color(0xFFE11D48),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // 2. Sliding Foreground Content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: GestureDetector(
              onTap: () {
                if (_isOpen) {
                  _close();
                }
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset = (_dragOffset + (details.primaryDelta ?? 0.0))
                      .clamp(-350.0, 0.0);
                });
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0.0;
                if (_dragOffset < -_fullSwipeThreshold || velocity < -700) {
                  _confirmAndDelete(category);
                } else if (_dragOffset < -(_actionWidth / 2)) {
                  HapticFeedback.lightImpact();
                  _animateTo(-_actionWidth);
                } else {
                  _close();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF131A22), // seamless with day group card
                child: Row(
                  children: [
                    // Squircle icon matching Quanto (40x40 compact)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(category?.color ?? 0xFF6366F1)
                            .withValues(alpha: 0.16),
                        border: Border.all(
                          color: Color(category?.color ?? 0xFF6366F1)
                              .withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category?.iconOrEmoji ?? '📁',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & optional note / account
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'Transaction',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                            ),
                          ),
                          if (widget.transaction.note?.isNotEmpty == true ||
                              account != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.transaction.note?.isNotEmpty == true
                                  ? widget.transaction.note!
                                  : account!.name,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Amount matching Quanto
                    Text(
                      '$amountPrefix${AppFormatters.currency(widget.transaction.amount)}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: amountColor,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
