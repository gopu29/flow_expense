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
import '../../activity/widgets/transaction_tile.dart';
import '../widgets/summary_donut_chart.dart';

/// Subcategory spend breakdown info
class SubcategoryBreakdownItem {
  final Category subcategory;
  final double totalAmount;
  final int count;
  final double percentageOfParent;
  final double percentageOfTotal;
  final List<Transaction> transactions;

  const SubcategoryBreakdownItem({
    required this.subcategory,
    required this.totalAmount,
    required this.count,
    required this.percentageOfParent,
    required this.percentageOfTotal,
    required this.transactions,
  });
}

/// Main category spend breakdown item with nested subcategories
class MainCategoryBreakdownItem {
  final Category category;
  final double totalAmount;
  final int count;
  final double percentage;
  final List<Transaction> allTransactions;
  final List<Transaction> directTransactions;
  final List<SubcategoryBreakdownItem> subcategories;

  bool get hasSubcategories => subcategories.isNotEmpty;

  const MainCategoryBreakdownItem({
    required this.category,
    required this.totalAmount,
    required this.count,
    required this.percentage,
    required this.allTransactions,
    required this.directTransactions,
    required this.subcategories,
  });
}

/// Flagship Summary Screen matching Quanto's exact layout from IMG_6027.PNG:
/// - Atmospheric transparent background seamlessly revealing the midnight gradient
/// - Top-left settings nut button
/// - Borderless hero segmented donut chart with centered "This month ⌵" and large total
/// - Horizontal filter pills: [Expenses, Monthly, All accounts, All categories]
/// - Unified grouped card for category breakdown with:
///   - Tap-to-expand subcategories with animated accordion and rotating chevron
///   - Tap on subcategory or main category to view added transaction list in a modal sheet
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

  // Track expanded category IDs for smooth accordion expansion
  final Set<String> _expandedCategoryIds = {};

  void _toggleCategoryExpansion(String categoryId) {
    setState(() {
      if (_expandedCategoryIds.contains(categoryId)) {
        _expandedCategoryIds.remove(categoryId);
      } else {
        _expandedCategoryIds.add(categoryId);
      }
    });
  }

  void _showTransactionsSheet({
    required String title,
    required String iconOrEmoji,
    required int colorValue,
    required double totalAmount,
    required List<Transaction> transactions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Top Grab Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF151E28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Color(colorValue),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          iconOrEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'} • ${AppFormatters.currency(totalAmount)}',
                              style: const TextStyle(
                                color: Color(0xFF8E9BAE),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.8, color: Color(0xFF1E2A38)),

                // Transactions List
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions found for this period',
                            style: TextStyle(color: Color(0xFF6B7E93), fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151E28),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF223040)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: TransactionTile(
                                transaction: tx,
                                isFirst: true,
                                isLast: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
              orElse: () => const Category(
                id: '',
                name: 'Category',
                iconOrEmoji: '🏷️',
              ),
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
                        // Filter transactions according to selected filters
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

                        // Fast category lookup map
                        final Map<String, Category> categoryMap = {
                          for (final c in categories) c.id: c,
                        };

                        // Map subcategories by parentId
                        final Map<String, List<Category>> subsByParentId = {};
                        for (final c in categories) {
                          if (c.parentId != null && c.parentId!.isNotEmpty) {
                            subsByParentId.putIfAbsent(c.parentId!, () => []).add(c);
                          }
                        }

                        // Helper to find the parent category for any transaction
                        String getParentCatId(Transaction tx) {
                          final cat = categoryMap[tx.categoryId];
                          if (cat != null && cat.parentId != null && cat.parentId!.isNotEmpty) {
                            return cat.parentId!;
                          }
                          return tx.categoryId;
                        }

                        // Calculate grand total amount
                        double totalAmount = 0.0;
                        final Map<String, List<Transaction>> txsByParentCatId = {};

                        for (final tx in filteredTxs) {
                          totalAmount += tx.amount;
                          final parentId = getParentCatId(tx);
                          txsByParentCatId.putIfAbsent(parentId, () => []).add(tx);
                        }

                        // Build MainCategoryBreakdownItem list
                        final breakdownItems = <MainCategoryBreakdownItem>[];
                        final donutSpendData = <CategorySpendData>[];

                        // Find all parent categories that have transactions
                        for (final entry in txsByParentCatId.entries) {
                          final parentId = entry.key;
                          final parentTxs = entry.value;

                          final parentCat = categoryMap[parentId] ??
                              Category(
                                id: parentId,
                                name: 'General',
                                iconOrEmoji: '🏷️',
                                color: 0xFF6366F1,
                              );

                          final parentTotal = parentTxs.fold<double>(
                            0.0,
                            (sum, t) => sum + t.amount,
                          );

                          final percentage = totalAmount > 0
                              ? (parentTotal / totalAmount) * 100
                              : 0.0;

                          // Check defined subcategories
                          final definedSubs = subsByParentId[parentCat.id] ?? [];
                          final subItems = <SubcategoryBreakdownItem>[];
                          final Set<String> matchedTxIds = {};

                          for (final sub in definedSubs) {
                            final subTxs = parentTxs
                                .where((t) =>
                                    t.categoryId == sub.id ||
                                    t.subCategoryId == sub.id)
                                .toList();

                            for (final t in subTxs) {
                              matchedTxIds.add(t.id);
                            }

                            final subTotal = subTxs.fold<double>(
                              0.0,
                              (sum, t) => sum + t.amount,
                            );

                            final pctOfParent = parentTotal > 0
                                ? (subTotal / parentTotal) * 100
                                : 0.0;

                            final pctOfTotal = totalAmount > 0
                                ? (subTotal / totalAmount) * 100
                                : 0.0;

                            subItems.add(
                              SubcategoryBreakdownItem(
                                subcategory: sub,
                                totalAmount: subTotal,
                                count: subTxs.length,
                                percentageOfParent: pctOfParent,
                                percentageOfTotal: pctOfTotal,
                                transactions: subTxs,
                              ),
                            );
                          }

                          // Sort subcategories descending by amount
                          subItems.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

                          // Direct transactions (not belonging to any defined subcategory)
                          final directTxs = parentTxs
                              .where((t) => !matchedTxIds.contains(t.id))
                              .toList();

                          breakdownItems.add(
                            MainCategoryBreakdownItem(
                              category: parentCat,
                              totalAmount: parentTotal,
                              count: parentTxs.length,
                              percentage: percentage,
                              allTransactions: parentTxs,
                              directTransactions: directTxs,
                              subcategories: subItems,
                            ),
                          );

                          donutSpendData.add(
                            CategorySpendData(
                              categoryId: parentCat.id,
                              categoryName: parentCat.name,
                              iconOrEmoji: parentCat.iconOrEmoji,
                              amount: parentTotal,
                              colorValue: parentCat.color,
                              percentage: percentage,
                              count: parentTxs.length,
                            ),
                          );
                        }

                        // Sort main categories descending by total amount
                        breakdownItems.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
                        donutSpendData.sort((a, b) => b.amount.compareTo(a.amount));

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            // 2. Hero Segmented Donut Chart (Matching IMG_6027.PNG)
                            SummaryDonutChart(
                              categories: donutSpendData,
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

                            // 4. Unified Category Breakdown Card Container with Subcategory Expansion
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF121B24).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF202D3B),
                                  width: 1,
                                ),
                              ),
                              child: breakdownItems.isEmpty
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
                                        for (int i = 0; i < breakdownItems.length; i++) ...[
                                          _buildMainCategoryTile(breakdownItems[i]),
                                          if (i < breakdownItems.length - 1)
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

  /// Main Category Item with Tap-to-Expand Accordion for Subcategories
  Widget _buildMainCategoryTile(MainCategoryBreakdownItem item) {
    final isExpanded = _expandedCategoryIds.contains(item.category.id);
    final hasSubs = item.hasSubcategories;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Category Header Row
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (hasSubs) {
              _toggleCategoryExpansion(item.category.id);
            } else {
              // Directly view transaction list if no subcategories exist
              _showTransactionsSheet(
                title: item.category.name,
                iconOrEmoji: item.category.iconOrEmoji,
                colorValue: item.category.color,
                totalAmount: item.totalAmount,
                transactions: item.allTransactions,
              );
            }
          },
          onLongPress: () {
            // Long press always opens the transaction list for this category
            _showTransactionsSheet(
              title: item.category.name,
              iconOrEmoji: item.category.iconOrEmoji,
              colorValue: item.category.color,
              totalAmount: item.totalAmount,
              transactions: item.allTransactions,
            );
          },
          child: Padding(
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
                      color: Color(item.category.color),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.category.iconOrEmoji,
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
                          item.category.name,
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

                const SizedBox(width: 8),

                // Total Amount
                Text(
                  AppFormatters.currency(item.totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 8),

                // Percentage Badge
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

                // Expand Chevron (shown when category has subcategories)
                if (hasSubs) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF7D91A4),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Subcategory Accordion Expansion
        if (hasSubs)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: isExpanded
                ? Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D141C),
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFF182330),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Quick Action: View all transactions for this main category
                        InkWell(
                          onTap: () {
                            _showTransactionsSheet(
                              title: '${item.category.name} (All)',
                              iconOrEmoji: item.category.iconOrEmoji,
                              colorValue: item.category.color,
                              totalAmount: item.totalAmount,
                              transactions: item.allTransactions,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF152230),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF22364A),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: Color(0xFF38BDF8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'View all ${item.category.name} transactions',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '(${item.count})',
                                  style: const TextStyle(
                                    color: Color(0xFF7D91A4),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFF7D91A4),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Subcategory list rows
                        for (int s = 0; s < item.subcategories.length; s++) ...[
                          _buildSubcategoryRow(
                            parentCat: item.category,
                            subItem: item.subcategories[s],
                          ),
                          if (s < item.subcategories.length - 1)
                            const Padding(
                              padding: EdgeInsets.only(left: 60),
                              child: Divider(
                                height: 1,
                                thickness: 0.6,
                                color: Color(0xFF16202A),
                              ),
                            ),
                        ],

                        // Direct / Unassigned transactions row if any exist alongside subcategories
                        if (item.directTransactions.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 60),
                            child: Divider(
                              height: 1,
                              thickness: 0.6,
                              color: Color(0xFF16202A),
                            ),
                          ),
                          _buildDirectCategoryRow(
                            parentCat: item.category,
                            directTxs: item.directTransactions,
                            parentTotal: item.totalAmount,
                          ),
                        ],

                        const SizedBox(height: 6),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  /// Single Subcategory Row with Tap-to-View Transactions
  Widget _buildSubcategoryRow({
    required Category parentCat,
    required SubcategoryBreakdownItem subItem,
  }) {
    return InkWell(
      onTap: () {
        _showTransactionsSheet(
          title: '${parentCat.name} ↳ ${subItem.subcategory.name}',
          iconOrEmoji: subItem.subcategory.iconOrEmoji,
          colorValue: subItem.subcategory.color,
          totalAmount: subItem.totalAmount,
          transactions: subItem.transactions,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 24), // Indentation for subcategory

            // Subcategory Icon squircle with colored outline
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF141D26),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: Color(subItem.subcategory.color).withValues(alpha: 0.8),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                subItem.subcategory.iconOrEmoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Subcategory Name & Count
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      subItem.subcategory.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2530),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${subItem.count}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount
            Text(
              AppFormatters.currency(subItem.totalAmount),
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 8),

            // Percentage of Parent Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16212B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${subItem.percentageOfParent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF7A8D9F),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF5A6F82),
            ),
          ],
        ),
      ),
    );
  }

  /// Direct / Main-level Transactions Row
  Widget _buildDirectCategoryRow({
    required Category parentCat,
    required List<Transaction> directTxs,
    required double parentTotal,
  }) {
    final directTotal = directTxs.fold<double>(0.0, (sum, t) => sum + t.amount);
    final pctOfParent = parentTotal > 0 ? (directTotal / parentTotal) * 100 : 0.0;

    return InkWell(
      onTap: () {
        _showTransactionsSheet(
          title: '${parentCat.name} (Direct / General)',
          iconOrEmoji: parentCat.iconOrEmoji,
          colorValue: parentCat.color,
          totalAmount: directTotal,
          transactions: directTxs,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF141D26),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.folder_open_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      'General / Direct',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2530),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${directTxs.length}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppFormatters.currency(directTotal),
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16212B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${pctOfParent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF7A8D9F),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF5A6F82),
            ),
          ],
        ),
      ),
    );
  }
}
