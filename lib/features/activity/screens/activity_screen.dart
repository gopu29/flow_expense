import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/transaction.dart';
import '../widgets/daily_spend_bar_chart.dart';
import '../widgets/transaction_tile.dart';
import '../../settings/screens/settings_screen.dart';

/// Flagship Activity Screen matching Quanto's exact gradient UI (IMG_6026.PNG).
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTypeFilter = 'All'; // Default to 'All'
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  late final AnimationController _searchAnimController;
  late final Animation<double> _searchExpandAnimation;
  late final Animation<double> _searchFadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _searchExpandAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _searchFadeAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchAnimController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchAnimController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;

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

              // 1. Top Header Row: Settings nut icon on left, Centered Month Dropdown
              Stack(
                alignment: Alignment.center,
                children: [
                  // Left Settings Nut / Gear Button
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

                  // Centered "This month ⌵" chip
                  GestureDetector(
                    onTap: () {
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCurrentMonth
                              ? 'This month'
                              : AppFormatters.monthYear(selectedDate),
                          style: TextStyle(
                            color: const Color(0xFF8FA2B2),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF8FA2B2),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 2. Huge Centered Amount Display (Matching IMG_6026.PNG)
              Text(
                AppFormatters.currency(monthlyExpense),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 14),

              // 3. Borderless Daily Spend Bar Chart (Directly on Midnight Gradient)
              transactionsAsync.when(
                data: (txs) => DailySpendBarChart(
                  transactions: txs,
                  selectedMonth: selectedDate,
                ),
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => SizedBox(
                  height: 140,
                  child: Center(child: Text('Error: $e')),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Horizontal Filter Chips (Search, All transactions, Expenses, Income, Monthly, All accounts)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Search toggle button with smooth icon rotation & background transition
                    GestureDetector(
                      onTap: _toggleSearchBar,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _showSearchBar
                              ? const Color(0xFF243545)
                              : const Color(0xFF15202B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _showSearchBar
                                ? const Color(0xFF33475A)
                                : const Color(0xFF212E3B),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: anim.drive(
                              Tween<double>(begin: 0.75, end: 1.0)
                                  .chain(CurveTween(curve: Curves.easeOutBack)),
                            ),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            _showSearchBar ? Icons.close : Icons.search_rounded,
                            key: ValueKey<bool>(_showSearchBar),
                            size: 18,
                            color: _showSearchBar
                                ? Colors.white
                                : const Color(0xFFB0C2D2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // All filter pill (DEFAULT SELECTED)
                    _buildFilterChip(
                      'All transactions',
                      isActive: _selectedTypeFilter == 'All',
                      onTap: () {
                        setState(() => _selectedTypeFilter = 'All');
                      },
                    ),
                    const SizedBox(width: 8),

                    // Expenses filter pill
                    _buildFilterChip(
                      'Expenses',
                      isActive: _selectedTypeFilter == 'Expenses',
                      onTap: () {
                        setState(() => _selectedTypeFilter = 'Expenses');
                      },
                    ),
                    const SizedBox(width: 8),

                    // Income filter pill
                    _buildFilterChip(
                      'Income',
                      isActive: _selectedTypeFilter == 'Income',
                      onTap: () {
                        setState(() => _selectedTypeFilter = 'Income');
                      },
                    ),
                    const SizedBox(width: 8),

                    // Monthly tag
                    _buildFilterChip('Monthly', isActive: false, onTap: () {}),
                    const SizedBox(width: 8),

                    // All accounts tag
                    _buildFilterChip('All accounts', isActive: false, onTap: () {}),
                  ],
                ),
              ),

              // Smoothly animated expanding search bar
              SizeTransition(
                sizeFactor: _searchExpandAnimation,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _searchFadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by merchant, note, or amount...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7E8E),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF131D26),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF6B7E8E),
                          size: 18,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF6B7E8E),
                                  size: 16,
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF22313F)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF22313F)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Grouped Transactions Timeline (Grouped by Date matching IMG_6026.PNG)
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    var filtered = txs.where((t) {
                      if (t.date.year != selectedDate.year ||
                          t.date.month != selectedDate.month) {
                        return false;
                      }
                      if (_selectedTypeFilter == 'Expenses' &&
                          t.type != TransactionType.expense) {
                        return false;
                      }
                      if (_selectedTypeFilter == 'Income' &&
                          t.type != TransactionType.income) {
                        return false;
                      }
                      if (_searchQuery.isNotEmpty) {
                        final note = (t.note ?? '').toLowerCase();
                        final amount = t.amount.toString();
                        if (!note.contains(_searchQuery) &&
                            !amount.contains(_searchQuery)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    Widget content;
                    if (filtered.isEmpty) {
                      content = Center(
                        key: const ValueKey('empty_tx_state'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: const Color(0xFF4A5D6E),
                              size: 44,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No transactions found',
                              style: TextStyle(
                                color: const Color(0xFF8FA2B2),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Group by date header (e.g. "Today", "Yesterday", "Fri, 09 Oct")
                      final Map<String, List<Transaction>> grouped = {};
                      for (final tx in filtered) {
                        final header = AppFormatters.dateHeader(tx.date);
                        grouped.putIfAbsent(header, () => []).add(tx);
                      }

                      final groupHeaders = grouped.keys.toList();

                      content = ListView.builder(
                        key: ValueKey('list_tx_$_selectedTypeFilter'),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: groupHeaders.length,
                        itemBuilder: (context, index) {
                          final header = groupHeaders[index];
                          final items = grouped[header]!;

                          final dayTotal = items.fold<double>(
                            0.0,
                            (sum, t) => t.type == TransactionType.expense
                                ? sum + t.amount
                                : sum,
                          );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 14,
                                bottom: 8,
                                left: 4,
                                right: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    header,
                                    style: const TextStyle(
                                      color: Color(0xFF7E91A1),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (dayTotal > 0)
                                    Text(
                                      AppFormatters.currency(dayTotal),
                                      style: const TextStyle(
                                        color: Color(0xFF7E91A1),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Single Unified Card Container for all items of this day!
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A22),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF1C2733),
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (int i = 0; i < items.length; i++) ...[
                                    TransactionTile(
                                      transaction: items[i],
                                      isFirst: i == 0,
                                      isLast: i == items.length - 1,
                                    ),
                                    if (i < items.length - 1)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFF1A242F),
                                        indent: 66,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: content,
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

  Widget _buildFilterChip(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF202E3B) : const Color(0xFF141F29),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF33475A) : const Color(0xFF1E2B38),
            width: 1,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF8FA2B2),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Inter',
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
