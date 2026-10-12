import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/bottom_nav_dock.dart';
import '../core/providers/expense_providers.dart';
import '../features/activity/screens/activity_screen.dart';
import '../features/summary/screens/summary_screen.dart';
import '../features/budget/screens/budget_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/accounts/screens/accounts_screen.dart';
import '../features/quick_input/screens/quick_input_modal.dart';

/// Main scaffold container hosting the 5 core tabs and floating bottom dock.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(activeNavIndexProvider);

    final screens = const [
      ActivityScreen(),
      SummaryScreen(),
      BudgetScreen(),
      AnalyticsScreen(),
      AccountsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Screen contents
          IndexedStack(
            index: currentIndex,
            children: screens,
          ),

          // Floating Navigation Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavDock(
              currentIndex: currentIndex,
              onTabSelected: (index) {
                ref.read(activeNavIndexProvider.notifier).setIndex(index);
              },
              onQuickAddPressed: () {
                QuickInputModal.show(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
