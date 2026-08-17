import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class WeightGrowthChart extends StatelessWidget {
  const WeightGrowthChart({super.key, required this.points});

  final List<ChartPointData> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No weight points recorded', style: TextStyle(color: AppColors.textSecondary)));
    }

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final computedMax = points.fold<double>(0.5, (max, p) => p.value > max ? p.value : max) * 1.15;
    final safeMaxY = computedMax > 0.1 ? computedMax : 1.0;
    final bottomInterval = (points.length / 5).clamp(1.0, 10.0);

    return SizedBox(
      height: 200,
      child: LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 0.8),
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
                if (idx >= 0 && idx < points.length) {
                  return Text(points[idx].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (val, meta) {
                return Text('${val.toStringAsFixed(1)}kg', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: safeMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
