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

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedAccountId;

  void _showAccountSelector(List<Account> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                      color:
                          isSelected ? const Color(0xFF38BDF8) : Colors.white,
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

  @override
  Widget build(BuildContext context) {
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

              const SizedBox(height: 14),

              // 2. Filter Pills: [Monthly ⌵, All accounts ⌵] matching IMG_6029.PNG
              Row(
                children: [
                  // Period Selector Pill
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2633),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF263747),
                          width: 1,
                        ),
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
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2633),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF263747),
                          width: 1,
                        ),
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
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        // Card 1: Income vs Expenses Dual-Bar Chart matching IMG_6029.PNG
                        IncomeVsExpenseChart(
                          transactions: filteredTxs,
                          selectedMonth: selectedDate,
                        ),

                        const SizedBox(height: 16),

                        // Card 2: Income Left Card matching IMG_6029.PNG & IMG_6030.PNG
                        IncomeLeftCard(
                          transactions: filteredTxs,
                          selectedMonth: selectedDate,
                        ),

                        const SizedBox(height: 16),

                        // Card 3: Calendar Heatmap Matrix matching IMG_6030.PNG
                        CalendarHeatmap(
                          selectedMonth: selectedDate,
                          transactions: filteredTxs,
                        ),

                        const SizedBox(height: 16),

                        // Card 4: Unlock Recurring Insights matching IMG_6030.PNG & IMG_6031.PNG
                        const InsightsTeaserCard(
                          buttonText: 'Unlock recurring insights',
                          title: 'Recurring Subscriptions',
                          description:
                              'Track and manage recurring subscriptions, automatic utility bills, and fixed charges effortlessly.',
                          showBarGraphic: false,
                        ),

                        const SizedBox(height: 16),

                        // Card 5: Unlock Budgeting Insights matching IMG_6031.PNG
                        const InsightsTeaserCard(
                          buttonText: 'Unlock budgeting insights',
                          title: 'Budgeting Intelligence',
                          description:
                              'Forecast your end-of-month financial trajectory and optimize your savings rate with smart spending velocity alerts.',
                          showBarGraphic: true,
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
