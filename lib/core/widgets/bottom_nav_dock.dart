import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Floating bottom navigation dock matching Quanto's sleek aesthetic.
class BottomNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onQuickAddPressed;

  const BottomNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onQuickAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: AppColors.surfaceBorder.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.list_alt_rounded,
            label: 'Activity',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.pie_chart_outline_rounded,
            label: 'Summary',
          ),
          // Central Quick Add Button
          GestureDetector(
            onTap: onQuickAddPressed,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.track_changes_rounded,
            label: 'Budget',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.auto_graph_rounded,
            label: 'Analytics',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Accounts',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceHover : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
