import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Initial Activity Screen shell showcasing our dark design system.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'This month',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Filters', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total Spend Display
              Text(
                '${AppConstants.currencySymbol} 0.00',
                style: AppTypography.amountDisplay.copyWith(fontSize: 38),
              ),
              const SizedBox(height: 24),

              // Overview Card Placeholder
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Average', style: AppTypography.caption),
                          Text('${AppConstants.currencySymbol} 0.00', style: AppTypography.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Budget Left', style: AppTypography.caption),
                          Text(
                            '${AppConstants.currencySymbol} 0.00',
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.income),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Quick Status Banner
              Center(
                child: Text(
                  'Flow Expense • Dark Theme Ready',
                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
