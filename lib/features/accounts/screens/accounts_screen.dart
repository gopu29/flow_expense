import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/account_card.dart';

/// Flagship Accounts Screen matching Quanto IMG_6032.PNG & IMG_6035.PNG:
/// - Atmospheric transparent background seamlessly revealing the midnight gradient
/// - Top-left settings nut button, top-right plus button
/// - Centered Hero display: "Total balance" + bold total amount
/// - Reorderable list of account cards with drag handles '='
/// - Interactive Add Account and Account Details bottom sheets
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  // Show sleek "Add New Account" bottom sheet
  void _showAddAccountSheet() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    AccountType selectedType = AccountType.bank;
    String selectedIcon = '🏦';

    final availableIcons = ['🏦', '💵', '💳', '🪙', '📈', '💎', '💼', '🏠', '🚗', '🛍️'];

    final iconsByType = {
      AccountType.bank: '🏦',
      AccountType.cash: '💵',
      AccountType.creditCard: '💳',
      AccountType.savings: '🪙',
      AccountType.investment: '📈',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top grab handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                const Text(
                  'New Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // Account Name field
                const Text(
                  'Account Name',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. Main Bank, Cash, Credit Card',
                    hintStyle: const TextStyle(color: Color(0xFF4B5E73)),
                    filled: true,
                    fillColor: const Color(0xFF162330),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF223142)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Account Type selector chips
                const Text(
                  'Account Type',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AccountType.values.map((type) {
                    final isSelected = selectedType == type;
                    final name =
                        type.name[0].toUpperCase() + type.name.substring(1);

                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedType = type;
                          selectedIcon = iconsByType[type] ?? selectedIcon;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF283647)
                              : const Color(0xFF162330),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF223142),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8E9BAE),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Icon picker
                const Text(
                  'Icon',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableIcons.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final icon = availableIcons[i];
                      final isSelected = selectedIcon == icon;

                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedIcon = icon),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF283647)
                                : const Color(0xFF162330),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF223142),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(icon, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Starting Balance field
                const Text(
                  'Starting Balance',
                  style: TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    prefixText: '${AppConstants.currencySymbol} ',
                    prefixStyle: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF162330),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF223142)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final balance =
                          double.tryParse(balanceController.text) ?? 0.0;

                      final newAccount = Account(
                        id: const Uuid().v4(),
                        name: name,
                        type: selectedType,
                        balance: balance,
                        icon: selectedIcon,
                        currency: 'INR',
                      );

                      await ref
                          .read(accountsProvider.notifier)
                          .addAccount(newAccount);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show Account Details and Options Sheet
  void _showAccountDetailsSheet(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final transactionsAsync = ref.watch(transactionsProvider);
        final accountTxs = transactionsAsync.maybeWhen(
          data: (txs) => txs.where((t) => t.accountId == account.id).toList(),
          orElse: () => <Transaction>[],
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Account Hero Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2936),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        account.icon,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.type.name.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF8E9BAE),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.currency(account.balance),
                      style: TextStyle(
                        color: account.balance >= 0
                            ? Colors.white
                            : const Color(0xFFF87171),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Action buttons: Edit Balance, Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditBalanceDialog(account);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Balance'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF263747)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteAccount(account);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFF87171),
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFF87171)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFFF87171).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Transactions under this account
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Transactions',
                      style: TextStyle(
                        color: Color(0xFF8E9BAE),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${accountTxs.length} items',
                      style: const TextStyle(
                        color: Color(0xFF6B7E93),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (accountTxs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No transactions recorded under this account',
                        style: TextStyle(color: Color(0xFF6B7E93)),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: accountTxs.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: Color(0xFF1E2A38),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final tx = accountTxs[index];
                        final isExpense = tx.type == TransactionType.expense;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tx.note?.isNotEmpty == true
                                ? tx.note!
                                : tx.categoryId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • hh:mm a').format(tx.date),
                            style: const TextStyle(
                              color: Color(0xFF6B7E93),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            '${isExpense ? '-' : '+'}${AppFormatters.currency(tx.amount)}',
                            style: TextStyle(
                              color: isExpense
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF34D399),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit Balance Dialog
  void _showEditBalanceDialog(Account account) {
    final controller =
        TextEditingController(text: account.balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121B24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Balance - ${account.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            prefixStyle: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: const Color(0xFF182430),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF263747)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E9BAE)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBal =
                  double.tryParse(controller.text) ?? account.balance;
              final updated = account.copyWith(balance: newBal);
              await ref.read(accountsProvider.notifier).updateAccount(updated);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Confirm delete account
  void _confirmDeleteAccount(Account account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121B24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete ${account.name}?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this account? Transactions associated with it will remain in history.',
          style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E9BAE)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(accountsProvider.notifier).deleteAccount(account.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netWorth = ref.watch(totalNetWorthProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 1. Top Bar: Left Hexagonal Nut & Right Plus Icon matching IMG_6032.PNG
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Hex Nut Settings Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF162330).withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF243545),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.hexagon_outlined,
                        color: Color(0xFFB0C2D2),
                        size: 20,
                      ),
                    ),
                  ),

                  // Right Plus Button
                  GestureDetector(
                    onTap: _showAddAccountSheet,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF162330).withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF243545),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFFB0C2D2),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Centered Hero Header: "Total balance" + Amount matching IMG_6032.PNG
              Column(
                children: [
                  const Text(
                    'Total balance',
                    style: TextStyle(
                      color: Color(0xFF8E9BAE),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.currency(netWorth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 3. Reorderable Accounts List matching IMG_6032.PNG & IMG_6035.PNG
              Expanded(
                child: accountsAsync.when(
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF162330),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.account_balance_outlined,
                                color: Color(0xFF6B7E93),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No accounts yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap the + button above to add your first account',
                              style: TextStyle(
                                color: Color(0xFF8E9BAE),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: accounts.length,
                      onReorderItem: (oldIndex, newIndex) {
                        ref
                            .read(accountsProvider.notifier)
                            .reorderAccounts(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final acc = accounts[index];

                        return AccountCard(
                          key: ValueKey(acc.id),
                          account: acc,
                          onTap: () => _showAccountDetailsSheet(acc),
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
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
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
