import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/account.dart';
import '../widgets/account_card.dart';

/// Accounts Screen displaying aggregated net worth and multi-account cards.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    AccountType selectedType = AccountType.bank;
    String selectedIcon = '🏦';

    final iconsByType = {
      AccountType.bank: '🏦',
      AccountType.cash: '💵',
      AccountType.creditCard: '💳',
      AccountType.savings: '🪙',
      AccountType.investment: '📈',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Add New Account', style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. HDFC Bank, Wallet',
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  value: selectedType,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: AccountType.values.map((type) {
                    final name =
                        type.name[0].toUpperCase() + type.name.substring(1);
                    return DropdownMenuItem(
                      value: type,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedType = val;
                        selectedIcon = iconsByType[val] ?? '🏦';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Initial Balance',
                    prefixText: '${AppConstants.currencySymbol} ',
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final balance = double.tryParse(balanceController.text) ?? 0.0;

                final newAccount = Account(
                  id: const Uuid().v4(),
                  name: name,
                  type: selectedType,
                  balance: balance,
                  icon: selectedIcon,
                  currency: 'INR',
                );

                await ref.read(accountsProvider.notifier).addAccount(newAccount);
                if (context.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBalanceDialog(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) {
    final controller =
        TextEditingController(text: account.balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Balance - ${account.name}', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            filled: true,
            fillColor: AppColors.surfaceHover,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBal = double.tryParse(controller.text) ?? account.balance;
              final updated = account.copyWith(balance: newBal);
              await ref.read(accountsProvider.notifier).updateAccount(updated);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorth = ref.watch(totalNetWorthProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Accounts & Balances', style: AppTypography.titleLarge),
                  IconButton(
                    onPressed: () => _showAddAccountDialog(context, ref),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                    tooltip: 'Add Account',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Net Worth Banner (IMG_6032.PNG)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Net Worth', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.currency(netWorth),
                      style: AppTypography.amountDisplay.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.income,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aggregated from all active accounts',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Accounts', style: AppTypography.titleMedium),
                  accountsAsync.maybeWhen(
                    data: (accs) => Text(
                      '${accs.length} accounts',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No accounts found',
                              style: AppTypography.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showAddAccountDialog(context, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                              ),
                              child: const Text('Add an Account'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        return AccountCard(
                          account: acc,
                          onTap: () => _showEditBalanceDialog(context, ref, acc),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
