import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

class CategorySpendData {
  final String categoryId;
  final String categoryName;
  final String iconOrEmoji;
  final double amount;
  final int colorValue;
  final double percentage;
  final int count;

  const CategorySpendData({
    this.categoryId = '',
    required this.categoryName,
    required this.iconOrEmoji,
    required this.amount,
    required this.colorValue,
    required this.percentage,
    this.count = 1,
  });
}

/// Hero Segmented Donut Chart matching Quanto's IMG_6027.PNG layout.
class SummaryDonutChart extends StatefulWidget {
  final List<CategorySpendData> categories;
  final double totalSpend;
  final String monthLabel;
  final VoidCallback onMonthTap;

  const SummaryDonutChart({
    super.key,
    required this.categories,
    required this.totalSpend,
    required this.monthLabel,
    required this.onMonthTap,
  });

  @override
  State<SummaryDonutChart> createState() => _SummaryDonutChartState();
}

class _SummaryDonutChartState extends State<SummaryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final hasData = widget.totalSpend > 0 && widget.categories.isNotEmpty;

    final sections = hasData
        ? widget.categories.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isTouched = index == _touchedIndex;
            final radius = isTouched ? 30.0 : 24.0;

            return PieChartSectionData(
              color: Color(data.colorValue),
              value: data.amount,
              title: '',
              radius: radius,
              showTitle: false,
            );
          }).toList()
        : [
            PieChartSectionData(
              color: const Color(0xFF1E2A38),
              value: 1,
              title: '',
              radius: 22.0,
              showTitle: false,
            ),
          ];

    final isCategorySelected =
        _touchedIndex >= 0 && _touchedIndex < widget.categories.length;
    final selectedCategory =
        isCategorySelected ? widget.categories[_touchedIndex] : null;

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segmented Donut Ring
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
              sectionsSpace: hasData ? 4.0 : 0.0,
              centerSpaceRadius: 92,
              sections: sections,
            ),
          ),

          // Center Text: "This month ⌵" + Large Total (Matching Quanto IMG_6027.PNG)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: widget.onMonthTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCategorySelected
                            ? selectedCategory!.categoryName
                            : widget.monthLabel,
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF8E9BAE),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isCategorySelected
                            ? Icons.close
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF8E9BAE),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCategorySelected
                    ? AppFormatters.currency(selectedCategory!.amount)
                    : AppFormatters.currency(widget.totalSpend),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              if (isCategorySelected)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${selectedCategory!.percentage.toStringAsFixed(1)}% of total',
                    style: TextStyle(
                      color: Color(selectedCategory.colorValue),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
