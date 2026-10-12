import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/category.dart';
import '../../../models/transaction.dart';
import '../../../models/account.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/summary_donut_chart.dart';

/// Flagship Summary Screen matching Quanto's exact layout from IMG_6027.PNG:
/// - Atmospheric transparent background seamlessly revealing the midnight gradient
/// - Top-left settings nut button
/// - Borderless hero segmented donut chart with centered "This month ⌵" and large total
/// - Horizontal filter pills: [Expenses, Monthly, All accounts, All categories]
/// - Unified grouped card for category breakdown with colored icon borders, count pills, and percentage badges
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  String _selectedType = 'Expenses'; // 'Expenses', 'Income', 'All'
  String _selectedPeriod = 'Monthly'; // 'Monthly', 'Weekly', 'Yearly', 'All Time'
  String? _selectedAccountId;
  String? _selectedCategoryId;

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Transaction Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...['Expenses', 'Income', 'All'].map((type) {
                final isSelected = _selectedType == type;
                return ListTile(
                  title: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                      : null,
                  onTap: () {
                    setState(() => _selectedType = type);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Select Period',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...['Monthly', 'Weekly', 'Yearly', 'All Time'].map((period) {
                final isSelected = _selectedPeriod == period;
                return ListTile(
                  title: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                      : null,
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showAccountSelector(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Filter by Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'All accounts',
                  style: TextStyle(
                    color: _selectedAccountId == null
                        ? const Color(0xFF38BDF8)
                        : Colors.white,
                    fontWeight: _selectedAccountId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selectedAccountId == null
                    ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                    : null,
                onTap: () {
                  setState(() => _selectedAccountId = null);
                  Navigator.pop(context);
                },
              ),
              ...accounts.map((acc) {
                final isSelected = _selectedAccountId == acc.id;
                return ListTile(
                  title: Text(
                    acc.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    AppFormatters.currency(acc.balance),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                      : null,
                  onTap: () {
                    setState(() => _selectedAccountId = acc.id);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showCategorySelector(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Filter by Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'All categories',
                  style: TextStyle(
                    color: _selectedCategoryId == null
                        ? const Color(0xFF38BDF8)
                        : Colors.white,
                    fontWeight: _selectedCategoryId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selectedCategoryId == null
                    ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                    : null,
                onTap: () {
                  setState(() => _selectedCategoryId = null);
                  Navigator.pop(context);
                },
              ),
              ...categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ListTile(
                  leading: Text(cat.iconOrEmoji, style: const TextStyle(fontSize: 20)),
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF38BDF8))
                      : null,
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  bool _matchesDateFilter(DateTime txDate, DateTime selectedDate) {
    switch (_selectedPeriod) {
      case 'Weekly':
        final startOfWeek =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return txDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            txDate.isBefore(endOfWeek);
      case 'Yearly':
        return txDate.year == selectedDate.year;
      case 'All Time':
        return true;
      case 'Monthly':
      default:
        return txDate.year == selectedDate.year &&
            txDate.month == selectedDate.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;
    final monthLabel = isCurrentMonth
        ? 'This month'
        : AppFormatters.monthYear(selectedDate);

    final accountsList = accountsAsync.value ?? [];
    final categoriesList = categoriesAsync.value ?? [];

    final selectedAccountName = _selectedAccountId != null
        ? accountsList
            .firstWhere(
              (a) => a.id == _selectedAccountId,
              orElse: () => const Account(
                id: '',
                name: 'Account',
                type: AccountType.bank,
                balance: 0,
              ),
            )
            .name
        : 'All accounts';

    final selectedCategoryName = _selectedCategoryId != null
        ? categoriesList
            .firstWhere(
              (c) => c.id == _selectedCategoryId,
              orElse: () => const Category(id: '', name: 'Category', iconOrEmoji: '🏷️'),
            )
            .name
        : 'All categories';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 1. Top Bar: Left Hexagonal Nut/Settings button (Matching IMG_6027.PNG)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
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
              ),

              const SizedBox(height: 8),

              // Main Content Area
              Expanded(
                child: transactionsAsync.when(
                  data: (allTxs) {
                    return categoriesAsync.when(
                      data: (categories) {
                        // Filter transactions
                        final filteredTxs = allTxs.where((tx) {
                          // Date/Period filter
                          if (!_matchesDateFilter(tx.date, selectedDate)) {
                            return false;
                          }

                          // Type filter
                          if (_selectedType == 'Expenses' &&
                              tx.type != TransactionType.expense) {
                            return false;
                          }
                          if (_selectedType == 'Income' &&
                              tx.type != TransactionType.income) {
                            return false;
                          }

                          // Account filter
                          if (_selectedAccountId != null &&
                              tx.accountId != _selectedAccountId) {
                            return false;
                          }

                          // Category filter
                          if (_selectedCategoryId != null &&
                              tx.categoryId != _selectedCategoryId) {
                            return false;
                          }

                          return true;
                        }).toList();

                        // Calculate totals and group by category
                        double totalAmount = 0.0;
                        final Map<String, List<Transaction>> categoryGroups = {};

                        for (final tx in filteredTxs) {
                          totalAmount += tx.amount;
                          categoryGroups.putIfAbsent(tx.categoryId, () => []).add(tx);
                        }

                        final spendDataList = <CategorySpendData>[];
                        for (final entry in categoryGroups.entries) {
                          final cat = categories.firstWhere(
                            (c) => c.id == entry.key,
                            orElse: () => const Category(
                              id: '',
                              name: 'General',
                              iconOrEmoji: '🏷️',
                              color: 0xFF6366F1,
                            ),
                          );

                          final catTotal = entry.value.fold<double>(
                            0.0,
                            (sum, t) => sum + t.amount,
                          );

                          final percentage = totalAmount > 0
                              ? (catTotal / totalAmount) * 100
                              : 0.0;

                          spendDataList.add(
                            CategorySpendData(
                              categoryId: cat.id,
                              categoryName: cat.name,
                              iconOrEmoji: cat.iconOrEmoji,
                              amount: catTotal,
                              colorValue: cat.color,
                              percentage: percentage,
                              count: entry.value.length,
                            ),
                          );
                        }

                        // Sort descending by total amount
                        spendDataList.sort((a, b) => b.amount.compareTo(a.amount));

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            // 2. Hero Segmented Donut Chart (Matching IMG_6027.PNG)
                            SummaryDonutChart(
                              categories: spendDataList,
                              totalSpend: totalAmount,
                              monthLabel: monthLabel,
                              onMonthTap: () {
                                MonthSelectorSheet.show(
                                  context,
                                  initialDate: selectedDate,
                                  onDateSelected: (newDate) {
                                    ref
                                        .read(selectedDateProvider.notifier)
                                        .updateDate(newDate);
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // 3. Horizontal Filter Chips Row (Matching IMG_6027.PNG)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    label: _selectedType,
                                    onTap: _showTypeSelector,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: _selectedPeriod,
                                    onTap: _showPeriodSelector,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: selectedAccountName,
                                    onTap: () => _showAccountSelector(accountsList),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: selectedCategoryName,
                                    onTap: () =>
                                        _showCategorySelector(categoriesList),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 4. Unified Category Breakdown Card Container (Matching IMG_6027.PNG)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF121B24).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF202D3B),
                                  width: 1,
                                ),
                              ),
                              child: spendDataList.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 36,
                                        horizontal: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No category data for this period',
                                          style: TextStyle(
                                            color: Color(0xFF6B7E93),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (int i = 0; i < spendDataList.length; i++) ...[
                                          _buildCategoryRow(spendDataList[i]),
                                          if (i < spendDataList.length - 1)
                                            const Divider(
                                              height: 1,
                                              thickness: 0.8,
                                              color: Color(0xFF1B2633),
                                            ),
                                        ],
                                      ],
                                    ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF18222C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF263544),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD6E2EE),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(CategorySpendData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category Icon squircle with colored border matching category
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF151E28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Color(item.colorValue),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.iconOrEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),

          // Category Name & Transaction Count Badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2B37),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.count}',
                    style: const TextStyle(
                      color: Color(0xFF7D91A4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Category Total Amount
          Text(
            AppFormatters.currency(item.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 10),

          // Percentage Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2633),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.percentage.toStringAsFixed(2)}%',
              style: const TextStyle(
                color: Color(0xFF8B9EB2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
