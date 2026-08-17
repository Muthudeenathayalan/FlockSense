import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class ProfitTrendChart extends StatelessWidget {
  const ProfitTrendChart({super.key, required this.points});

  final List<MultiLinePointData> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No profit data available', style: TextStyle(color: AppColors.textSecondary)));
    }

    final revenueSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];

    double maxY = 1000.0;
    double minY = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      revenueSpots.add(FlSpot(i.toDouble(), p.revenue));
      expenseSpots.add(FlSpot(i.toDouble(), p.expense));
      profitSpots.add(FlSpot(i.toDouble(), p.profit));

      if (p.revenue > maxY) maxY = p.revenue;
      if (p.expense > maxY) maxY = p.expense;
      if (p.profit > maxY) maxY = p.profit;
      if (p.profit < minY) minY = p.profit;
    }

    maxY *= 1.15;
    if (maxY <= minY) maxY = minY + 100.0;
    final bottomInterval = (points.length / 5).clamp(1.0, 10.0);

    return SizedBox(
      height: 220,
      child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Legend(color: Color(0xFF2E7D32), label: 'Revenue'),
            SizedBox(width: 14),
            _Legend(color: Color(0xFFD32F2F), label: 'Expense'),
            SizedBox(width: 14),
            _Legend(color: Color(0xFF1976D2), label: 'Profit'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
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
                      if (idx >= 0 && idx < points.length) {
                        final p = points[idx];
                        return Text('${p.date.month}/${p.date.day}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
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
                      if (val.abs() >= 1000) {
                        return Text('₹${(val / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                      }
                      return Text('₹${val.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: revenueSpots,
                  isCurved: true,
                  color: const Color(0xFF2E7D32),
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: const Color(0xFFD32F2F),
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: profitSpots,
                  isCurved: true,
                  color: const Color(0xFF1976D2),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}
