import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';

/// Interactive tile displaying a single transaction with swipe-to-delete.
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

    final amountPrefix = isExpense
        ? '-'
        : isIncome
            ? '+'
            : '';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction?'),
            content: Text(
              'Are you sure you want to delete ${AppFormatters.currency(transaction.amount)} for ${category?.name ?? 'this item'}?',
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            CategoryIconBadge(
              iconOrEmoji: category?.iconOrEmoji ?? '🏷️',
              colorValue: category?.color ?? 0xFF6366F1,
              size: 42,
              fontSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category?.name ?? 'Transaction',
                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (account != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            account.name,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : AppFormatters.time(transaction.date),
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${AppFormatters.currency(transaction.amount)}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.time(transaction.date),
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
