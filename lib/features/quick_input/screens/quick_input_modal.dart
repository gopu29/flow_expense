import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../core/widgets/category_icon_badge.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../widgets/numpad.dart';

/// Modal bottom sheet allowing zero-friction instant logging of transactions.
class QuickInputModal extends ConsumerStatefulWidget {
  const QuickInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickInputModal(),
    );
  }

  @override
  ConsumerState<QuickInputModal> createState() => _QuickInputModalState();
}

class _QuickInputModalState extends ConsumerState<QuickInputModal> {
  String _amountString = '0';
  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount; // for transfers
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteField = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0') {
          _amountString = key;
        } else {
          // Limit to 2 decimals
          if (_amountString.contains('.')) {
            final parts = _amountString.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          if (_amountString.length < 9) {
            _amountString += key;
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_amountString.length > 1) {
        _amountString = _amountString.substring(0, _amountString.length - 1);
        if (_amountString.isEmpty) _amountString = '0';
      } else {
        _amountString = '0';
      }
    });
  }

  Future<void> _submitTransaction() async {
    final amount = double.tryParse(_amountString) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount greater than 0'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final tx = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: _selectedCategory!.id,
      accountId: _selectedAccount!.id,
      toAccountId: _type == TransactionType.transfer ? _selectedToAccount?.id : null,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(transactionsProvider.notifier).addTransaction(tx);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == TransactionType.expense ? 'Expense' : _type == TransactionType.income ? 'Income' : 'Transfer'} of ${AppConstants.currencySymbol} $amount logged!',
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Type Switcher: Expense / Income / Transfer
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    _buildTypeChip('Expense', TransactionType.expense, AppColors.expense),
                    _buildTypeChip('Income', TransactionType.income, AppColors.income),
                    _buildTypeChip('Transfer', TransactionType.transfer, AppColors.transfer),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Huge Amount Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppConstants.currencySymbol,
                    style: AppTypography.amountDisplay.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _amountString,
                    style: AppTypography.amountDisplay.copyWith(
                      fontSize: 44,
                      color: _type == TransactionType.expense
                          ? AppColors.textPrimary
                          : _type == TransactionType.income
                              ? AppColors.income
                              : AppColors.transfer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Picker Horizontal Row
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories
                      .where((c) =>
                          _type == TransactionType.transfer
                              ? c.type == CategoryType.transfer
                              : _type == TransactionType.income
                                  ? c.type == CategoryType.income
                                  : c.type == CategoryType.expense)
                      .toList();

                  // Auto select first if not selected
                  if (_selectedCategory == null && filtered.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedCategory = filtered.first);
                    });
                  }

                  return SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        final isSelected = _selectedCategory?.id == cat.id;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: CategoryIconBadge(
                                  iconOrEmoji: cat.iconOrEmoji,
                                  colorValue: cat.color,
                                  size: 46,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat.name,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, _) => const SizedBox(height: 80),
              ),
              const SizedBox(height: 12),

              // Context Chips (Account, Date, Note toggle)
              accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccount == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedAccount = accounts.first);
                    });
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Account chip
                        PopupMenuButton<Account>(
                          onSelected: (acc) => setState(() => _selectedAccount = acc),
                          color: AppColors.surface,
                          itemBuilder: (context) => accounts
                              .map(
                                (a) => PopupMenuItem(
                                  value: a,
                                  child: Text('${a.icon} ${a.name}'),
                                ),
                              )
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                Text(_selectedAccount?.icon ?? '🏦'),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedAccount?.name ?? 'Select Account',
                                  style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Date chip
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM').format(_selectedDate),
                                  style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Note toggle chip
                        GestureDetector(
                          onTap: () => setState(() => _showNoteField = !_showNoteField),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _showNoteField ? AppColors.surfaceHover : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('Note', style: AppTypography.caption.copyWith(color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
              const SizedBox(height: 12),

              // Optional note text field
              if (_showNoteField) ...[
                TextField(
                  controller: _noteController,
                  autofocus: true,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a note (e.g., Grocery at Walmart)',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // On-Screen Keypad
              CustomNumpad(
                onKeyPress: _onKeyPress,
                onDelete: _onDelete,
                onSubmit: _submitTransaction,
              ),
              const SizedBox(height: 12),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Save Transaction',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTypeChip(String title, TransactionType type, Color activeColor) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _selectedCategory = null; // reset category on type switch
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: activeColor.withOpacity(0.6)) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isSelected ? activeColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
