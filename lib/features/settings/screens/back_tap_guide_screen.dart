import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/glass_card.dart';

/// Step-by-step setup guide for iOS Back Tap instant expense logging.
class BackTapGuideScreen extends StatelessWidget {
  const BackTapGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'step': '1',
        'title': 'Open iOS Settings',
        'subtitle': 'Navigate to Settings > Accessibility > Touch on your iPhone.',
        'icon': Icons.settings_rounded,
      },
      {
        'step': '2',
        'title': 'Find "Back Tap"',
        'subtitle': 'Scroll to the bottom of the Touch menu and tap "Back Tap".',
        'icon': Icons.touch_app_rounded,
      },
      {
        'step': '3',
        'title': 'Choose Double or Triple Tap',
        'subtitle': 'Select "Double Tap" or "Triple Tap" depending on your preference.',
        'icon': Icons.fingerprint_rounded,
      },
      {
        'step': '4',
        'title': 'Link Quanto / Flow Expense',
        'subtitle': 'Scroll to the Shortcuts section and choose "Log Flow Expense".',
        'icon': Icons.bolt_rounded,
      },
      {
        'step': '5',
        'title': 'Ready for Zero-Friction Logging',
        'subtitle': 'Tap the back of your iPhone twice anytime to trigger the instant logging popup!',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('iOS Back Tap Setup', style: AppTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              // Hero banner
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.vibration_rounded, color: AppColors.accent, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Zero-Friction Logging',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Log any expense without unlocking or opening the full app by double-tapping the back of your phone.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Step-by-Step Instructions', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              ...steps.map((item) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item['step'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['subtitle'] as String,
                              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Icon(item['icon'] as IconData, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
