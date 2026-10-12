import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/bottom_nav_dock.dart';
import '../core/widgets/speed_dial_fab.dart';
import '../core/providers/expense_providers.dart';
import '../core/services/platform_intent_service.dart';
import '../features/activity/screens/activity_screen.dart';
import '../features/summary/screens/summary_screen.dart';
import '../features/budget/screens/budget_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/accounts/screens/accounts_screen.dart';
import '../features/quick_input/screens/quick_input_modal.dart';
import '../features/voice_logging/screens/voice_logger_sheet.dart';
import '../features/receipt_scanner/screens/receipt_scanner_sheet.dart';

/// Main scaffold container hosting the 5 core tabs with smooth page transitions.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate platform intent sync service
    ref.watch(platformIntentServiceProvider);

    final currentIndex = ref.watch(activeNavIndexProvider);

    final screens = const [
      ActivityScreen(),
      SummaryScreen(),
      BudgetScreen(),
      AnalyticsScreen(),
      AccountsScreen(),
    ];

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, alt: true): () {
          QuickInputModal.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyE, alt: true): () {
          QuickInputModal.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.backgroundBottom,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.appBackgroundGradient,
            ),
            child: Stack(
              children: [
              // Smooth animated screen transitions
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.015),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(currentIndex),
                  child: screens[currentIndex],
                ),
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
                ),
              ),

              // Floating Action Button at bottom-right (Tap: Quick add, Hold: Voice + Scan)
              Positioned(
                right: 20,
                bottom: 84,
                child: SpeedDialFab(
                  onQuickAdd: () {
                    QuickInputModal.show(context);
                  },
                  onVoiceLog: () {
                    VoiceLoggerSheet.show(context);
                  },
                  onScanReceipt: () {
                    ReceiptScannerSheet.show(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
