import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating bottom navigation dock matching Quanto's sleek aesthetic (IMG_6026.PNG)
/// with a continuous fluid sliding active pill indicator and tactile micro-interactions.
class BottomNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1620).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF1C2735),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 5;
          return Stack(
            children: [
              // Continuously sliding active pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: currentIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D3B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Nav Tab Items
              Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.article_outlined,
                    label: 'Activity',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.timelapse_rounded,
                    label: 'Summary',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.wallet_outlined,
                    label: 'Budget',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.account_balance_outlined,
                    label: 'Accounts',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            onTabSelected(index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey<bool>(isSelected),
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF6B7E8E),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF6B7E8E),
                    ),
                    child: Text(label),
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
