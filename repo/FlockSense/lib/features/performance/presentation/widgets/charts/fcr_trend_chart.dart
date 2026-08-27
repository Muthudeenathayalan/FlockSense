import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class FcrTrendChart extends StatelessWidget {
  const FcrTrendChart({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.dailyRecords.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No daily telemetry records available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final records = data.dailyRecords;
    final spotsActual = <FlSpot>[];
    final spotsTarget = <FlSpot>[];

    double cumFeed = 0;
    double runningBirds = data.totalInitialBirds > 0
        ? data.totalInitialBirds.toDouble()
        : 1000.0;

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      cumFeed += r.feedConsumedKg;
      runningBirds -= r.mortalityCount;

      final ageDays = i + 1;
      final avgWeightKg = r.avgWeightGrams > 0
          ? (r.avgWeightGrams / 1000.0)
          : 0.1;
      final totalLiveWeight = runningBirds > 0
          ? (runningBirds * avgWeightKg)
          : 1.0;

      final actualFcr = totalLiveWeight > 0 ? (cumFeed / totalLiveWeight) : 1.5;
      final targetFcr =
          1.10 + (ageDays * 0.011); // Standard Cobb500/Ross308 FCR curve

      spotsActual.add(FlSpot(i.toDouble(), actualFcr.clamp(0.8, 3.0)));
      spotsTarget.add(FlSpot(i.toDouble(), targetFcr.clamp(0.8, 3.0)));
    }

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          // Legend Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.danger, 'Actual FCR'),
              const SizedBox(width: 20),
              _legendDot(AppColors.primary, 'Target Benchmark (1.50)'),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0.5,
                maxY: 3.0,
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
                      reservedSize: 36,
                      interval: 0.5,
                      getTitlesWidget: (val, meta) => Text(
                        val.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
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
                          return Text(
                            'D${idx + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual FCR Line
                  LineChartBarData(
                    spots: spotsActual,
                    isCurved: true,
                    color: AppColors.danger,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.danger.withValues(alpha: 0.08),
                    ),
                  ),
                  // Target FCR Line
                  LineChartBarData(
                    spots: spotsTarget,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    dashArray: [6, 4],
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

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
