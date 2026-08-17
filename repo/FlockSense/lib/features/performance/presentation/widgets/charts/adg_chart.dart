import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class AdgChart extends StatelessWidget {
  const AdgChart({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.dailyRecords.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No daily weight telemetry available', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final records = data.dailyRecords;
    final groups = <BarChartGroupData>[];

    double prevWeight = 50.0; // Day 0 chick weight (~50g)

    for (int i = 0; i < records.length; i++) {
      final currentWeight = records[i].avgWeightGrams > 0
          ? records[i].avgWeightGrams
          : (prevWeight + 50.0);
      final gain = (currentWeight - prevWeight).clamp(0.0, 150.0);
      prevWeight = currentWeight;

      // Color code gain: Green if > 45g/day, Amber if 30-45g/day, Red if < 30g/day (stagnant)
      Color barColor;
      if (gain >= 45) {
        barColor = const Color(0xFF10B981);
      } else if (gain >= 30) {
        barColor = const Color(0xFFE49B25);
      } else {
        barColor = AppColors.danger;
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: gain,
              color: barColor,
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    double maxGain = 0;
    for (final g in groups) {
      for (final rod in g.barRods) {
        if (rod.toY > maxGain) maxGain = rod.toY;
      }
    }
    final safeMaxY = maxGain > 10 ? maxGain * 1.15 : 60.0;
    final bottomInterval = (records.length / 5).clamp(1.0, 10.0);

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF10B981), 'Good (>45g/d)'),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFE49B25), 'Moderate (30-45g/d)'),
              const SizedBox(width: 14),
              _legendDot(AppColors.danger, 'Lagging (<30g/d)'),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: BarChart(
              BarChartData(
                maxY: safeMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}g',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (records.length / 5).clamp(1.0, 10.0),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < records.length) {
                          return Text('D${idx + 1}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ],
    );
  }
}
