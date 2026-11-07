import 'package:flow_expense/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/account.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/income_vs_expense_chart.dart';
import '../widgets/income_left_card.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/insights_teaser_card.dart';
import '../../../core/widgets/staggered_entrance.dart';

/// Flagship Analytics Screen matching Quanto's exact layout from IMG_6029.PNG, IMG_6030.PNG, IMG_6031.PNG:
/// - Atmospheric transparent background seamlessly revealing the midnight gradient
/// - Top-left hexagonal settings nut button
/// - Horizontal filter pills: [Monthly ⌵, All accounts ⌵]
/// - Unified continuous vertical feed:
///   1. "Income vs expenses" dual-bar comparison card with green & cyan gradient pills and stats
///   2. "Income left" card with currency/% switcher and glowing magenta progression pill
///   3. "Calendar" heatmap matrix with 7-column squircle badges matching Quanto
///   4. "Unlock recurring insights" frosted teaser card
///   5. "Unlock budgeting insights" frosted teaser card
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String? _selectedAccountId;

  void _showAccountSelector(List<Account> accounts) {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF162330),
                Color(0xFF0F1722),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Color(0xFF2B3F54),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle pill
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Filter by Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.all_inclusive_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'All accounts',
                    style: TextStyle(
                      color: _selectedAccountId == null
                          ? const Color(0xFF38BDF8)
                          : Colors.white,
                      fontWeight: _selectedAccountId == null
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _selectedAccountId == null
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20)
                      : null,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() => _selectedAccountId = null);
                    Navigator.pop(context);
                  },
                ),
                ...accounts.map((acc) {
                  final isSelected = _selectedAccountId == acc.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E9BAE).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8E9BAE).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        acc.type == AccountType.bank
                            ? Icons.account_balance_outlined
                            : acc.type == AccountType.creditCard
                                ? Icons.credit_card_outlined
                                : Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      acc.name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppFormatters.balance(acc.balance),
                      style: TextStyle(
                        color: acc.balance < 0 ? const Color(0xFFF87171) : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20)
                        : null,
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() => _selectedAccountId = acc.id);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final accountsList = accountsAsync.value ?? [];
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

              // 1. Top Bar: Left Hexagonal Nut/Settings button (Matching IMG_6029.PNG)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1D2C3B),
                          Color(0xFF131D28),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2B3F54),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hexagon_outlined,
                      color: Color(0xFFC0D3E5),
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Filter Pills: [Monthly ⌵, All accounts ⌵] matching IMG_6029.PNG
              Row(
                children: [
                  // Period Selector Pill
                  GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1C2B3A),
                            Color(0xFF121C26),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF273A4D),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormatters.monthYear(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF8E9BAE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Account Selector Pill
                  GestureDetector(
                    onTap: () => _showAccountSelector(accountsList),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1C2B3A),
                            Color(0xFF121C26),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF273A4D),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedAccountName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF8E9BAE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Unified Continuous Vertical Feed matching Quanto
              Expanded(
                child: transactionsAsync.when(
                  data: (txs) {
                    // Filter transactions by account if specified
                    final filteredTxs = _selectedAccountId != null
                        ? txs
                            .where((t) => t.accountId == _selectedAccountId)
                            .toList()
                        : txs;

                    return ListView(
                      padding: EdgeInsets.only(
                        bottom: 120 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        // Card 1: Income vs Expenses Dual-Bar Chart matching IMG_6029.PNG
                        StaggeredEntrance(
                          index: 0,
                          child: IncomeVsExpenseChart(
                            transactions: filteredTxs,
                            selectedMonth: selectedDate,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 2: Income Left Card matching IMG_6029.PNG & IMG_6030.PNG
                        StaggeredEntrance(
                          index: 1,
                          child: IncomeLeftCard(
                            transactions: filteredTxs,
                            selectedMonth: selectedDate,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 3: Calendar Heatmap Matrix matching IMG_6030.PNG
                        StaggeredEntrance(
                          index: 2,
                          child: CalendarHeatmap(
                            selectedMonth: selectedDate,
                            transactions: filteredTxs,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 4: Unlock Recurring Insights matching IMG_6030.PNG & IMG_6031.PNG
                        const StaggeredEntrance(
                          index: 3,
                          child: InsightsTeaserCard(
                            buttonText: 'Unlock recurring insights',
                            title: 'Recurring Subscriptions',
                            description:
                                'Track and manage recurring subscriptions, automatic utility bills, and fixed charges effortlessly.',
                            showBarGraphic: false,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 5: Unlock Budgeting Insights matching IMG_6031.PNG
                        const StaggeredEntrance(
                          index: 4,
                          child: InsightsTeaserCard(
                            buttonText: 'Unlock budgeting insights',
                            title: 'Budgeting Intelligence',
                            description:
                                'Forecast your end-of-month financial trajectory and optimize your savings rate with smart spending velocity alerts.',
                            showBarGraphic: true,
                          ),
                        ),
                      ],
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
