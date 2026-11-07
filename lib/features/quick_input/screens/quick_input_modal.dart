import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/entry_field_providers.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';
import '../../../models/transaction.dart';
import '../../../core/utils/amount_expression.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_typing_amount_text.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/category_rail.dart';
import '../widgets/currency_converter_sheet.dart';
import '../widgets/entry_fields_sheet.dart';
import '../widgets/note_entry_sheet.dart';
import '../widgets/numpad.dart';

const double _kSheetHeightFactor = 0.985;
const double _kChipHeight = 44;
const double _kRoundButtonSize = 46;
const double _kChipLabelMaxWidth = 130;

/// Modal bottom sheet allowing zero-friction instant logging of transactions.
class QuickInputModal extends ConsumerStatefulWidget {
  const QuickInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      final segment = lastAmountSegment(_amountString);
      if (key == '.') {
        if (!segment.contains('.')) {
          _amountString += segment.isEmpty ? '0.' : '.';
        }
        return;
      }
      if (segment == '0') {
        _amountString =
            _amountString.substring(0, _amountString.length - 1) + key;
        return;
      }
      final hasFullDecimals =
          segment.contains('.') && segment.split('.')[1].length >= 2;
      if (!hasFullDecimals && segment.length < 9) _amountString += key;
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
    final fields = await ref.read(visibleEntryFieldsProvider.future);
    if (!mounted) return;
    final note = fields.contains(EntryField.name)
        ? _noteController.text.trim()
        : '';
    final amount = evaluateAmountExpression(_amountString) ?? 0.0;
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
      toAccountId: _type == TransactionType.transfer
          ? _selectedToAccount?.id
          : null,
      date: fields.contains(EntryField.date) ? _selectedDate : DateTime.now(),
      note: note.isEmpty ? null : note,
      createdAt: DateTime.now(),
    );

    await ref.read(transactionsProvider.notifier).addTransaction(tx);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == TransactionType.expense
                ? 'Expense'
                : _type == TransactionType.income
                ? 'Income'
                : 'Transfer'} of ${AppConstants.currencySymbol} $amount logged!',
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onOperator(String operator) {
    setState(() {
      var expression = _amountString;
      if (expression.endsWith('.') || endsWithAmountOperator(expression)) {
        expression = expression.substring(0, expression.length - 1);
      }
      _amountString = expression + operator;
    });
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
      _type = switch (category.type) {
        CategoryType.expense => TransactionType.expense,
        CategoryType.income => TransactionType.income,
        CategoryType.transfer => TransactionType.transfer,
      };
    });
  }

  void _clearAmount() {
    HapticFeedback.mediumImpact();
    setState(() => _amountString = '0');
  }

  CategoryType get _categoryType => switch (_type) {
    TransactionType.expense => CategoryType.expense,
    TransactionType.income => CategoryType.income,
    TransactionType.transfer => CategoryType.transfer,
  };

  Future<void> _openCategoryPicker() async {
    final picked = await CategoryPickerSheet.show(
      context,
      initialType: _categoryType,
      selected: _selectedCategory,
    );
    if (picked != null && mounted) _selectCategory(picked);
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openConverter() async {
    HapticFeedback.selectionClick();
    final converted = await CurrencyConverterSheet.show(context);
    if (converted != null && mounted) {
      setState(() => _amountString = formatAmountInput(converted));
    }
  }

  /// Money left in the selected category's limit, or in the whole budget when
  /// the category has no limit of its own.
  String get _budgetChipLabel {
    final budget = ref.watch(budgetProvider).value;
    if (budget == null) return 'No budget';

    final mainId = _selectedCategory?.parentId ?? _selectedCategory?.id;
    final categoryLimit = budget.categoryLimits[mainId];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final parentIds = {for (final c in categories) c.id: c.parentId};
    final month = ref.watch(selectedDateProvider);

    var spent = 0.0;
    for (final tx
        in ref.watch(transactionsProvider).value ?? const <Transaction>[]) {
      final isThisMonth =
          tx.date.year == month.year && tx.date.month == month.month;
      if (tx.type != TransactionType.expense || !isThisMonth) continue;
      final txMainId = parentIds[tx.categoryId] ?? tx.categoryId;
      if (categoryLimit == null || txMainId == mainId) spent += tx.amount;
    }

    final left = (categoryLimit ?? budget.monthlyLimit) - spent;
    return '${AppFormatters.currency(left)} left';
  }

  Future<void> _editNote() async {
    HapticFeedback.selectionClick();
    await NoteEntrySheet.show(context, controller: _noteController);
    if (mounted) setState(() {});
  }

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dayDifference = today.difference(selected).inDays;
    if (dayDifference == 0) return 'Today';
    if (dayDifference == 1) return 'Yesterday';
    return DateFormat('dd MMM').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return FractionallySizedBox(
      heightFactor: _kSheetHeightFactor,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162330), Color(0xFF0F1722)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF2B3F54), width: 1.5)),
        ),
        padding: const EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Handle pill
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              _buildTopBar(),

              // Huge amount display with typing/erasing animation
              Expanded(child: _buildAmountArea()),

              // Context chips: date, account, name
              accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccount == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedAccount = accounts.first);
                      }
                    });
                  }
                  return _buildContextChips(accounts);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Main categories: tap to select, hold for sub-categories
              categoriesAsync.when(
                data: (categories) {
                  final ofType = categories
                      .where((c) => c.type == _categoryType)
                      .toList();

                  // Auto select the first main category if none is selected
                  final firstMain = ofType
                      .where((c) => !c.isSubCategory)
                      .firstOrNull;
                  if (_selectedCategory == null && firstMain != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedCategory = firstMain);
                      }
                    });
                  }

                  return CategoryRail(
                    categories: ofType,
                    selected: _selectedCategory,
                    onSelected: _selectCategory,
                    onOpenPicker: _openCategoryPicker,
                  );
                },
                loading: () => const SizedBox(
                  height: 56,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const SizedBox(height: 56),
              ),
              const SizedBox(height: 12),

              // On-screen keypad; the arrow key saves the transaction
              CustomNumpad(
                onKeyPress: _onKeyPress,
                onOperator: _onOperator,
                onSubmit: _submitTransaction,
                showOperators:
                    (ref.watch(visibleEntryFieldsProvider).value ??
                            defaultVisibleEntryFields)
                        .contains(EntryField.calculator),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: 'Options',
        child: GestureDetector(
          onTap: () => EntryFieldsSheet.show(context),
          child: Container(
            width: _kRoundButtonSize,
            height: _kRoundButtonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2B3A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF273A4D)),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedTypingAmountText(
              text: _amountString,
              prefix: AppConstants.currencySymbol,
              prefixStyle: AppTypography.amountDisplay.copyWith(
                color: AppColors.textSecondary,
                fontSize: 28,
              ),
              style: AppTypography.amountDisplay.copyWith(
                fontSize: 64,
                color: _type == TransactionType.expense
                    ? AppColors.textPrimary
                    : _type == TransactionType.income
                    ? AppColors.income
                    : AppColors.transfer,
              ),
            ),
          ),
        ),
        if (hasAmountOperator(_amountString))
          Align(
            alignment: const Alignment(0, 0.7),
            child: Text(
              '= ${AppConstants.currencySymbol}'
              '${formatAmountInput(evaluateAmountExpression(_amountString) ?? 0)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: 'Delete, hold to clear',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                _onDelete();
              },
              onLongPress: _clearAmount,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.backspace_rounded,
                  size: 26,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextChips(List<Account> accounts) {
    final note = _noteController.text.trim();
    final fields =
        ref.watch(visibleEntryFieldsProvider).value ??
        defaultVisibleEntryFields;

    final chips = <Widget>[
      if (fields.contains(EntryField.date))
        GestureDetector(
          onTap: _pickDate,
          child: _buildChip(
            icon: Icons.calendar_today_outlined,
            label: _dateLabel,
          ),
        ),
      if (fields.contains(EntryField.account))
        PopupMenuButton<Account>(
          tooltip: 'Account',
          onSelected: (account) {
            HapticFeedback.selectionClick();
            setState(() => _selectedAccount = account);
          },
          color: const Color(0xFF162330),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2B3F54)),
          ),
          itemBuilder: (_) => accounts
              .map(
                (account) => PopupMenuItem(
                  value: account,
                  child: Text('${account.icon} ${account.name}'),
                ),
              )
              .toList(),
          child: _buildChip(
            icon: Icons.account_balance_wallet_outlined,
            label: _selectedAccount?.name ?? 'Account',
          ),
        ),
      if (fields.contains(EntryField.name))
        GestureDetector(
          onTap: _editNote,
          child: _buildChip(
            icon: Icons.sticky_note_2_outlined,
            label: note.isEmpty ? 'Name' : note,
            isMuted: note.isEmpty,
          ),
        ),
      if (fields.contains(EntryField.currencyConverter))
        GestureDetector(
          onTap: _openConverter,
          child: _buildChip(
            icon: Icons.currency_exchange_rounded,
            label: 'Convert',
          ),
        ),
      if (fields.contains(EntryField.budget))
        _buildChip(icon: Icons.donut_large_rounded, label: _budgetChipLabel),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < chips.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              chips[index],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    bool isMuted = false,
  }) {
    final color = isMuted ? AppColors.textTertiary : AppColors.textPrimary;

    return Container(
      height: _kChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(_kChipHeight / 2),
        border: Border.all(color: const Color(0xFF273A4D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kChipLabelMaxWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
