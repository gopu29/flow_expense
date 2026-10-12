import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/month_selector_sheet.dart';
import '../../../core/providers/expense_providers.dart';
import '../../../models/budget.dart';
import '../../../models/category.dart';
import '../../../models/transaction.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/budget_gauge.dart';
import '../widgets/category_budget_numpad_sheet.dart';

/// Flagship Budget Screen matching Quanto's IMG_6028.PNG & design specification:
/// - Atmospheric transparent background seamlessly revealing the midnight gradient
/// - Top Bar: Left nut/settings button, Centered active profile pill (e.g. 'Personal'), Right edit icon
/// - Hero 360-degree circular budget progress ring with centered timeframe, remaining spend, and limit
/// - Multiple budget profile manager modal ("Budgets" sheet with '+' button & profile switcher)
/// - Dashed border "+ Add category" container opening the "Allocate your budget" modal sheet
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  // ---------------------------------------------------------------------------
  // 1. "Budgets" Modal Sheet (Multiple Budget Profiles Manager)
  // ---------------------------------------------------------------------------
  void _showBudgetsSheet(
    BuildContext context,
    List<Budget> budgets,
    double monthlyExpense,
    DateTime selectedDate,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final currentProfile = ref.watch(activeBudgetProfileProvider);

                return Column(
                  children: [
                    // Top Grab Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Header: "Budgets" + (+) button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Budgets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCreateBudgetDialog(
                              context,
                              ref,
                              selectedDate,
                            ),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D2B3A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF293B4E),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Color(0xFF1B2735),
                    ),

                    // Budget Profiles List
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        itemCount: budgets.length,
                        itemBuilder: (context, index) {
                          final b = budgets[index];
                          final isSelected = b.profileName.toLowerCase() ==
                              currentProfile.toLowerCase();
                          final limit = b.monthlyLimit;
                          final remaining =
                              limit > 0 ? limit - monthlyExpense : -monthlyExpense;
                          final remainingPct = limit > 0
                              ? ((remaining / limit) * 100).clamp(0.0, 100.0)
                              : 0.0;
                          final isOver = remaining < 0;

                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(activeBudgetProfileProvider.notifier)
                                  .setProfile(b.profileName);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF162534)
                                    : const Color(0xFF121B24),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFF1E2D3C),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Profile Name & Menu
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        b.profileName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF38BDF8)
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          color: Color(0xFF7E91A4),
                                          size: 20,
                                        ),
                                        color: const Color(0xFF1B2632),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showEditBudgetDialog(
                                              context,
                                              ref,
                                              b,
                                            );
                                          } else if (val == 'delete') {
                                            _deleteBudget(context, ref, b);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text(
                                              'Edit Limit & Name',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (budgets.length > 1)
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete Budget',
                                                style: TextStyle(
                                                  color: Color(0xFFF43F5E),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Balance left to spend
                                  Text(
                                    isOver
                                        ? '-${AppFormatters.currency(remaining.abs())} left to spend'
                                        : '${AppFormatters.currency(remaining)} left to spend',
                                    style: TextStyle(
                                      color: isOver
                                          ? const Color(0xFFF43F5E)
                                          : Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: limit > 0
                                          ? (monthlyExpense / limit)
                                              .clamp(0.0, 1.0)
                                          : 0.0,
                                      backgroundColor: const Color(0xFF1E2B38),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOver
                                            ? const Color(0xFFF43F5E)
                                            : const Color(0xFF10B981),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Bottom Row: % remaining & total limit
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${remainingPct.toStringAsFixed(0)}% remaining',
                                        style: const TextStyle(
                                          color: Color(0xFF7E91A4),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.currency(limit),
                                        style: const TextStyle(
                                          color: Color(0xFF7E91A4),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Create & Edit Budget Dialogs
  // ---------------------------------------------------------------------------
  void _showCreateBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final nameCtrl = TextEditingController(text: 'Personal');
    final limitCtrl = TextEditingController(text: '10000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141F2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Budget Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Profile Name (e.g. Business, Vacation)',
                labelStyle: const TextStyle(color: Color(0xFF7E91A4)),
                filled: true,
                fillColor: const Color(0xFF1B2836),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF28394C)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monthly Limit (₹)',
                labelStyle: const TextStyle(color: Color(0xFF7E91A4)),
                filled: true,
                fillColor: const Color(0xFF1B2836),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF28394C)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF7E91A4))),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim().isEmpty ? 'Budget' : nameCtrl.text.trim();
              final limit = double.tryParse(limitCtrl.text) ?? 10000.0;
              final monthKey =
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';

              final newBudget = Budget(
                id: const Uuid().v4(),
                profileName: name,
                monthlyLimit: limit,
                categoryLimits: const {},
                monthYear: monthKey,
              );

              final repo = ref.read(repositoryProvider);
              await repo.saveBudget(newBudget);
              ref.read(activeBudgetProfileProvider.notifier).setProfile(name);
              ref.invalidate(monthlyBudgetsProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) {
    final nameCtrl = TextEditingController(text: budget.profileName);
    final limitCtrl = TextEditingController(
      text: budget.monthlyLimit > 0
          ? budget.monthlyLimit.toStringAsFixed(0)
          : '10000',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141F2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Budget Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Profile Name',
                labelStyle: const TextStyle(color: Color(0xFF7E91A4)),
                filled: true,
                fillColor: const Color(0xFF1B2836),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF28394C)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monthly Limit (₹)',
                labelStyle: const TextStyle(color: Color(0xFF7E91A4)),
                filled: true,
                fillColor: const Color(0xFF1B2836),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF28394C)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF7E91A4))),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim().isEmpty ? budget.profileName : nameCtrl.text.trim();
              final limit = double.tryParse(limitCtrl.text) ?? budget.monthlyLimit;

              final updated = budget.copyWith(
                profileName: name,
                monthlyLimit: limit,
              );

              final repo = ref.read(repositoryProvider);
              await repo.saveBudget(updated);
              ref.read(activeBudgetProfileProvider.notifier).setProfile(name);
              ref.invalidate(monthlyBudgetsProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(BuildContext context, WidgetRef ref, Budget budget) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteBudget(budget.id);
    ref.read(activeBudgetProfileProvider.notifier).setProfile('Personal');
    ref.invalidate(monthlyBudgetsProvider);
  }

  // ---------------------------------------------------------------------------
  // 3. "Allocate your budget" Modal Sheet (Matching User Screenshot 1)
  // ---------------------------------------------------------------------------
  void _showAllocateBudgetSheet(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    List<Category> categories,
  ) {
    final expenseCats = categories
        .where((c) => c.type == CategoryType.expense && (c.parentId == null || c.parentId!.isEmpty))
        .toList();

    // Local mutable copy of allocations
    final Map<String, double> tempLimits = Map.of(budget.categoryLimits);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final totalLimit = budget.monthlyLimit > 0 ? budget.monthlyLimit : 10000.0;
            final allocatedSum = tempLimits.values.fold<double>(0.0, (s, l) => s + l);
            final percentSet = (totalLimit > 0 ? (allocatedSum / totalLimit) * 100 : 0.0).clamp(0.0, 100.0);
            final leftToAllocate = totalLimit - allocatedSum;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Top Grab Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Title: "Allocate your budget"
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Allocate your budget',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Overview Card (Matching User Screenshot 1)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14202C),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF223547),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${percentSet.toStringAsFixed(0)}% set',
                                style: const TextStyle(
                                  color: Color(0xFF8E9BAE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${AppFormatters.compact(allocatedSum)} / ${AppFormatters.currency(totalLimit)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percentSet / 100).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFF1E2B38),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                leftToAllocate < 0
                                    ? const Color(0xFFF43F5E)
                                    : const Color(0xFF38BDF8),
                              ),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // "₹10,000 left to allocate"
                          Text(
                            leftToAllocate >= 0
                                ? '${AppFormatters.currency(leftToAllocate)} left to allocate'
                                : 'Over-allocated by ${AppFormatters.currency(leftToAllocate.abs())}',
                            style: TextStyle(
                              color: leftToAllocate < 0
                                  ? const Color(0xFFF43F5E)
                                  : const Color(0xFF8E9BAE),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category Allocation List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: expenseCats.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Color(0xFF172330),
                        ),
                        itemBuilder: (context, index) {
                          final cat = expenseCats[index];
                          final currentCatLimit = tempLimits[cat.id] ?? 0.0;
                          final catPercent = totalLimit > 0
                              ? (currentCatLimit / totalLimit) * 100
                              : 0.0;

                          return InkWell(
                            onTap: () async {
                              final availableForCat =
                                  leftToAllocate + currentCatLimit;

                              final newLimit =
                                  await CategoryBudgetNumpadSheet.show(
                                context,
                                title:
                                    '${cat.iconOrEmoji} ${cat.name} monthly budget',
                                availableBudget: availableForCat,
                                initialAmount: currentCatLimit,
                              );
                              if (newLimit != null) {
                                setSheetState(() {
                                  if (newLimit <= 0) {
                                    tempLimits.remove(cat.id);
                                  } else {
                                    tempLimits[cat.id] = newLimit;
                                  }
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  // Squircle icon with colored outline border
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF151E28),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Color(cat.color),
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      cat.iconOrEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Category Name
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  // Category limit amount
                                  Text(
                                    AppFormatters.currency(currentCatLimit),
                                    style: const TextStyle(
                                      color: Color(0xFF8E9BAE),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Percentage pill badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF162330),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${catPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Color(0xFF7A8D9F),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Confirm Button (Matching User Screenshot 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final updated = budget.copyWith(
                              categoryLimits: tempLimits,
                            );
                            final repo = ref.read(repositoryProvider);
                            await repo.saveBudget(updated);
                            ref.invalidate(monthlyBudgetsProvider);
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              color: Color(0xFF0F1720),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final activeProfileName = ref.watch(activeBudgetProfileProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;
    final timeframeLabel = isCurrentMonth
        ? 'Left this month'
        : 'Left in ${AppFormatters.monthYear(selectedDate)}';

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

              // 1. Top Bar: Left Nut/Settings + Centered Profile Pill + Right Edit Icon Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Hexagonal Nut/Settings Button
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

                  // Center Active Profile Pill (e.g. "Personal")
                  GestureDetector(
                    onTap: () {
                      final list = budgetsAsync.value ?? [];
                      _showBudgetsSheet(
                        context,
                        list,
                        monthlyExpense,
                        selectedDate,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2633),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF283A4C),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        activeProfileName,
                        style: const TextStyle(
                          color: Color(0xFFD6E2EE),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Right Edit Pencil Button
                  GestureDetector(
                    onTap: () {
                      final list = budgetsAsync.value ?? [];
                      _showBudgetsSheet(
                        context,
                        list,
                        monthlyExpense,
                        selectedDate,
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
                        Icons.edit_outlined,
                        color: Color(0xFFB0C2D2),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Main Body Content
              Expanded(
                child: budgetsAsync.when(
                  data: (budgets) {
                    final activeBudget = budgets.firstWhere(
                      (b) =>
                          b.profileName.toLowerCase() ==
                          activeProfileName.toLowerCase(),
                      orElse: () => budgets.first,
                    );

                    final limit = activeBudget.monthlyLimit;

                    return categoriesAsync.when(
                      data: (categories) {
                        return transactionsAsync.when(
                          data: (txs) {
                            // Calculate category spend
                            final monthTxs = txs
                                .where((t) =>
                                    t.type == TransactionType.expense &&
                                    t.date.year == selectedDate.year &&
                                    t.date.month == selectedDate.month)
                                .toList();

                            final Map<String, double> catSpent = {};
                            for (final tx in monthTxs) {
                              catSpent[tx.categoryId] =
                                  (catSpent[tx.categoryId] ?? 0.0) + tx.amount;
                            }

                            // Allocated category cards
                            final allocatedEntries = activeBudget
                                .categoryLimits.entries
                                .where((e) => e.value > 0)
                                .toList();

                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 120),
                              children: [
                                const SizedBox(height: 12),

                                // 2. Hero 360-degree Budget Ring (IMG_6028.PNG)
                                BudgetGauge(
                                  spent: monthlyExpense,
                                  limit: limit,
                                  timeframeLabel: timeframeLabel,
                                  onTimeframeTap: () {
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

                                const SizedBox(height: 32),

                                // 3. Allocated Category Cards (if any)
                                if (allocatedEntries.isNotEmpty) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121B24)
                                          .withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: const Color(0xFF202D3B),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        for (int i = 0;
                                            i < allocatedEntries.length;
                                            i++) ...[
                                          _buildAllocatedCategoryTile(
                                            entry: allocatedEntries[i],
                                            categories: categories,
                                            catSpent: catSpent,
                                            onTap: () =>
                                                _showAllocateBudgetSheet(
                                              context,
                                              ref,
                                              activeBudget,
                                              categories,
                                            ),
                                          ),
                                          if (i < allocatedEntries.length - 1)
                                            const Divider(
                                              height: 1,
                                              thickness: 0.8,
                                              color: Color(0xFF1B2633),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // 4. Dashed Border "+ Add category" Container (IMG_6028.PNG)
                                GestureDetector(
                                  onTap: () => _showAllocateBudgetSheet(
                                    context,
                                    ref,
                                    activeBudget,
                                    categories,
                                  ),
                                  child: CustomPaint(
                                    painter: _DashedRectPainter(
                                      color: const Color(0xFF263544),
                                      strokeWidth: 1.5,
                                      gap: 6.0,
                                      dash: 7.0,
                                      radius: 20.0,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      height: 94,
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: Color(0xFF8E9BAE),
                                            size: 26,
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Add category',
                                            style: TextStyle(
                                              color: Color(0xFF8E9BAE),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

  Widget _buildAllocatedCategoryTile({
    required MapEntry<String, double> entry,
    required List<Category> categories,
    required Map<String, double> catSpent,
    required VoidCallback onTap,
  }) {
    final cat = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => Category(
        id: entry.key,
        name: 'Category',
        iconOrEmoji: '📁',
        color: 0xFF6366F1,
      ),
    );

    final catLimit = entry.value;
    final spent = catSpent[cat.id] ?? 0.0;
    final remaining = catLimit - spent;
    final isOver = remaining < 0;
    final progress = catLimit > 0 ? (spent / catLimit).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                // Category icon squircle with colored outline
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151E28),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(cat.color),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat.iconOrEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),

                // Category Name & limit text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatters.compact(spent)} / ${AppFormatters.compact(catLimit)}',
                        style: const TextStyle(
                          color: Color(0xFF7E91A4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remaining status text
                Text(
                  isOver
                      ? '-${AppFormatters.currency(remaining.abs())} over'
                      : '${AppFormatters.currency(remaining)} left',
                  style: TextStyle(
                    color: isOver ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF1B2633),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? const Color(0xFFF43F5E) : Color(cat.color),
                ),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dashed rounded border container
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dash > metric.length) ? metric.length - distance : dash;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}
