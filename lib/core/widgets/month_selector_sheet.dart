import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Modal bottom sheet allowing users to select any month/year.
class MonthSelectorSheet extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const MonthSelectorSheet({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MonthSelectorSheet(
        selectedDate: initialDate,
        onDateSelected: onDateSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Generate list of past 12 months and next 2 months
    final months = List.generate(15, (index) {
      return DateTime(now.year, now.month - 12 + index, 1);
    }).reversed.toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Period',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: months.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.surfaceBorder),
                itemBuilder: (context, index) {
                  final m = months[index];
                  final isSelected =
                      m.year == selectedDate.year && m.month == selectedDate.month;
                  final isCurrent =
                      m.year == now.year && m.month == now.month;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      DateFormat('MMMM yyyy').format(m),
                      style: AppTypography.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
                        : isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHover,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Current', style: AppTypography.caption),
                              )
                            : null,
                    onTap: () {
                      onDateSelected(m);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
