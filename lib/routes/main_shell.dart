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
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(activeNavIndexProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activate platform intent sync service
    ref.watch(platformIntentServiceProvider);

    final currentIndex = ref.watch(activeNavIndexProvider);

    // Keep PageView in sync when activeNavIndexProvider changes
    ref.listen<int>(activeNavIndexProvider, (previous, next) {
      if (previous != next && _pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final screens = const [
      ActivityScreen(),
      SummaryScreen(),
      BudgetScreen(),
      AnalyticsScreen(),
      AccountsScreen(),
    ];

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockBottom = bottomInset > 0 ? bottomInset + 8 : 16.0;

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
                // Smooth hardware-accelerated PageView without background opacity gaps
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: screens,
                ),

                // Floating Navigation Dock lifted above the system navigation bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: dockBottom,
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
                  bottom: dockBottom + 68,
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
