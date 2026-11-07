import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF162330),
            Color(0xFF0F1722),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2B3F54),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Period',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF1E2A38)),
                  itemBuilder: (context, index) {
                    final m = months[index];
                    final isSelected =
                        m.year == selectedDate.year && m.month == selectedDate.month;
                    final isCurrent =
                        m.year == now.year && m.month == now.month;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                              : const Color(0xFF1F2E3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                : const Color(0xFF2B3C4E),
                          ),
                        ),
                        child: Icon(
                          Icons.calendar_month_outlined,
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        DateFormat('MMMM yyyy').format(m),
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF38BDF8)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20)
                          : isCurrent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF26374A), Color(0xFF1A2634)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF344A61)),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
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
      ),
    );
  }
}
