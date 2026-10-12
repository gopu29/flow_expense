import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';

/// Minimalist, ultra-clean transaction row matching Quanto (IMG_6026.PNG).
class TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final Category? category = categoriesAsync.maybeWhen(
      data: (cats) => cats.firstWhere(
        (c) => c.id == transaction.categoryId,
        orElse: () => const Category(id: '', name: 'General', iconOrEmoji: '🏷️'),
      ),
      orElse: () => null,
    );

    final Account? account = accountsAsync.maybeWhen(
      data: (accs) => accs.firstWhere(
        (a) => a.id == transaction.accountId,
        orElse: () => const Account(id: '', name: 'Account', type: AccountType.bank),
      ),
      orElse: () => null,
    );

    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;

    final amountColor = isExpense
        ? AppColors.textPrimary
        : isIncome
            ? AppColors.income
            : AppColors.transfer;

    final amountPrefix = isIncome ? '+' : '';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Transaction?'),
            content: Text(
              'Delete ${AppFormatters.currency(transaction.amount)} for ${category?.name ?? 'this item'}?',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionsProvider.notifier).deleteTransaction(transaction);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121921).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1B2530),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Squircle icon matching Quanto
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: Color(category?.color ?? 0xFF6366F1).withValues(alpha: 0.16),
                border: Border.all(
                  color: Color(category?.color ?? 0xFF6366F1).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category?.iconOrEmoji ?? '📁',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),

            // Title & optional note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Transaction',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  if (transaction.note?.isNotEmpty == true || account != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note?.isNotEmpty == true
                          ? transaction.note!
                          : account!.name,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
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
              '$amountPrefix${AppFormatters.currency(transaction.amount)}',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
