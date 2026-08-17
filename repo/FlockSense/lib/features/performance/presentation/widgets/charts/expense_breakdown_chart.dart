import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class ExpenseBreakdownChart extends StatelessWidget {
  const ExpenseBreakdownChart({super.key, required this.categories});

  final List<ExpenseCategoryData> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No expense data available', style: TextStyle(color: AppColors.textSecondary)));
    }

    final computedMax = categories.fold<double>(1000.0, (max, c) => c.amount > max ? c.amount : max) * 1.15;
    final safeMaxY = computedMax > 10.0 ? computedMax : 1000.0;

    final categoryColors = [
      const Color(0xFF1B4D3E),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFF283593),
      const Color(0xFFE65100),
      const Color(0xFF37474F),
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
      BarChartData(
        maxY: safeMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < categories.length) {
                  return Text(categories[idx].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                if (val >= 1000) {
                  return Text('₹${(val / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                }
                return Text('₹${val.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: categories.asMap().entries.map((e) {
          final color = categoryColors[e.key % categoryColors.length];
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.amount,
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    ),
    );
  }
}
