import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class FeedConsumptionChart extends StatelessWidget {
  const FeedConsumptionChart({super.key, required this.bars});

  final List<ChartPointData> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const Center(child: Text('No feed records recorded', style: TextStyle(color: AppColors.textSecondary)));
    }

    final computedMax = bars.fold<double>(10.0, (max, p) => p.value > max ? p.value : max) * 1.15;
    final safeMaxY = computedMax > 1.0 ? computedMax : 10.0;
    final bottomInterval = (bars.length / 5).clamp(1.0, 10.0);

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
              interval: bottomInterval,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < bars.length) {
                  return Text(bars[idx].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) {
                return Text('${val.toInt()}kg', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: const Color(0xFFE65100),
                width: bars.length > 20 ? 6 : 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    ),
    );
  }
}
