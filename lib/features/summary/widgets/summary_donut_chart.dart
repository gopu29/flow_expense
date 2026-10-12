import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

class CategorySpendData {
  final String categoryName;
  final String iconOrEmoji;
  final double amount;
  final int colorValue;
  final double percentage;

  const CategorySpendData({
    required this.categoryName,
    required this.iconOrEmoji,
    required this.amount,
    required this.colorValue,
    required this.percentage,
  });
}

/// Segmented donut chart matching Quanto's summary breakdown.
class SummaryDonutChart extends StatefulWidget {
  final List<CategorySpendData> categories;
  final double totalSpend;

  const SummaryDonutChart({
    super.key,
    required this.categories,
    required this.totalSpend,
  });

  @override
  State<SummaryDonutChart> createState() => _SummaryDonutChartState();
}

class _SummaryDonutChartState extends State<SummaryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.totalSpend <= 0 || widget.categories.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder, width: 8),
                ),
                child: const Center(
                  child: Text('0%', style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
              const SizedBox(height: 12),
              Text('No expenses recorded', style: AppTypography.caption),
            ],
          ),
        ),
      );
    }

    final sections = widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 36.0 : 30.0;

      return PieChartSectionData(
        color: Color(data.colorValue),
        value: data.amount,
        title: '',
        radius: radius,
        badgeWidget: isTouched
            ? Text(
                data.iconOrEmoji,
                style: const TextStyle(fontSize: 16),
              )
            : null,
        badgePositionPercentageOffset: .98,
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 65,
              sections: sections,
            ),
          ),
          // Center Info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _touchedIndex >= 0 && _touchedIndex < widget.categories.length
                    ? widget.categories[_touchedIndex].categoryName
                    : 'Total Spent',
                style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                _touchedIndex >= 0 && _touchedIndex < widget.categories.length
                    ? AppFormatters.currency(widget.categories[_touchedIndex].amount)
                    : AppFormatters.currency(widget.totalSpend),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_touchedIndex >= 0 && _touchedIndex < widget.categories.length)
                Text(
                  '${widget.categories[_touchedIndex].percentage.toStringAsFixed(1)}%',
                  style: AppTypography.caption.copyWith(color: AppColors.accent),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
