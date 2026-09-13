import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

class WeightGrowthChart extends StatelessWidget {
  const WeightGrowthChart({super.key, required this.points});

  final List<ChartPointData> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                color: AppColors.textSecondary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'No weigh-in data logged yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Flock weight trajectory will plot here as daily weigh-ins are recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedPoints = [...points]
      ..sort((a, b) => (a.day ?? 0).compareTo(b.day ?? 0));

    final spotsActual = sortedPoints
        .map((p) => FlSpot((p.day ?? 0).toDouble(), p.value))
        .toList();

    final maxRecordedDay = sortedPoints.fold<int>(
      7,
      (max, p) => (p.day != null && p.day! > max) ? p.day! : max,
    );
    final chartMaxX = (maxRecordedDay < 7 ? 7 : maxRecordedDay).toDouble();

    // Standard benchmark curve points (Cobb500 / SKM)
    final spotsTarget = <FlSpot>[];
    spotsTarget.add(const FlSpot(0, 0.040)); // ~40g Day 0 chick
    for (int d = 1; d <= chartMaxX.toInt() && d <= 42; d++) {
      final stdGrams = PerformanceCalculator.skmBodyWeightStd[d];
      if (stdGrams != null) {
        spotsTarget.add(FlSpot(d.toDouble(), stdGrams / 1000.0));
      }
    }

    final computedMax = sortedPoints.fold<double>(
      0.5,
      (max, p) => p.value > max ? p.value : max,
    );
    final targetMax = spotsTarget.isNotEmpty ? spotsTarget.last.y : 0.5;
    final highestVal = computedMax > targetMax ? computedMax : targetMax;
    final safeMaxY = (highestVal * 1.18).clamp(0.2, 5.0);

    final bottomInterval = chartMaxX <= 14 ? 2.0 : (chartMaxX <= 28 ? 7.0 : 7.0);

    return SizedBox(
      height: 230,
      child: Column(
        children: [
          // Legend Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.primary, 'Actual Weight', isDashed: false),
              const SizedBox(width: 18),
              _legendItem(
                const Color(0xFFE49B25),
                'Standard Target (SKM/Cobb)',
                isDashed: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: chartMaxX,
                minY: 0,
                maxY: safeMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 0.8,
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isActual = spot.barIndex == 0;
                        final label = isActual ? 'Actual' : 'Target';
                        final grams = (spot.y * 1000).toInt();
                        return LineTooltipItem(
                          'D${spot.x.toInt()} $label: ${spot.y.toStringAsFixed(2)}kg (${grams}g)',
                          TextStyle(
                            color: isActual ? Colors.white : const Color(0xFFFDE68A),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: bottomInterval,
                      getTitlesWidget: (val, meta) {
                        final d = val.toInt();
                        if (d >= 0 && d <= chartMaxX.toInt()) {
                          return Text(
                            'D$d',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toStringAsFixed(1)}kg',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual Weight Line
                  LineChartBarData(
                    spots: spotsActual,
                    isCurved: spotsActual.length > 2,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  // Target Benchmark Line
                  if (spotsTarget.isNotEmpty)
                    LineChartBarData(
                      spots: spotsTarget,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFFE49B25),
                      barWidth: 2.0,
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

  Widget _legendItem(Color color, String label, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
