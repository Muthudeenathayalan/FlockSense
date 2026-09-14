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
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 30),
              SizedBox(height: 8),
              Text(
                'No daily telemetry records available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedRecords = [...data.dailyRecords]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));

    final spotsActual = <FlSpot>[];
    final spotsTarget = <FlSpot>[];

    double cumFeed = 0;
    double runningBirds = data.totalInitialBirds > 0
        ? data.totalInitialBirds.toDouble()
        : (sortedRecords.first.openingBirds > 0
            ? sortedRecords.first.openingBirds.toDouble()
            : 1000.0);
    double latestWeightGrams = 0.0;

    for (final r in sortedRecords) {
      cumFeed += r.feedConsumedKg;
      if (r.closingBirds > 0) {
        runningBirds = r.closingBirds.toDouble();
      } else {
        runningBirds -= (r.mortalityCount + r.cullCount);
      }

      if (r.avgWeightGrams > 0) {
        latestWeightGrams = r.avgWeightGrams;
      }

      final day = r.batchAgeDay;

      // Only plot actual FCR once a genuine weight reading is available
      if (latestWeightGrams > 0 && cumFeed > 0 && runningBirds > 0) {
        final totalLiveBiomassKg = runningBirds * (latestWeightGrams / 1000.0);
        if (totalLiveBiomassKg > 0) {
          final fcr = cumFeed / totalLiveBiomassKg;
          spotsActual.add(FlSpot(day.toDouble(), fcr.clamp(0.5, 4.0)));
        }
      }
    }

    if (spotsActual.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 30),
              SizedBox(height: 8),
              Text(
                'Awaiting bird weigh-in records',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Feed Conversion Ratio (FCR) curve will appear once average weight is recorded.',
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

    final minDay = spotsActual.first.x.toInt();
    final maxDay = spotsActual.last.x.toInt() < 7 ? 7 : spotsActual.last.x.toInt();

    // Standard target curve points (SKM/Cobb FCR standard)
    for (int d = minDay; d <= maxDay; d++) {
      spotsTarget.add(FlSpot(d.toDouble(), _getStandardTargetFcr(d)));
    }

    double highestVal = 2.0;
    for (final s in spotsActual) {
      if (s.y > highestVal) highestVal = s.y;
    }
    final safeMaxY = (highestVal * 1.15).clamp(2.0, 4.0);

    return SizedBox(
      height: 230,
      child: Column(
        children: [
          // Legend Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.primaryDark, 'Actual Cumulative FCR'),
              const SizedBox(width: 18),
              _legendDot(
                const Color(0xFF10B981),
                'Standard Target (SKM)',
                isDashed: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minX: minDay.toDouble(),
                maxX: maxDay.toDouble(),
                minY: 0.5,
                maxY: safeMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 0.8,
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isActual = spot.barIndex == 0;
                        final label = isActual ? 'Actual FCR' : 'Target FCR';
                        return LineTooltipItem(
                          'D${spot.x.toInt()} $label: ${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: isActual ? Colors.white : const Color(0xFFA7F3D0),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 0.5,
                      getTitlesWidget: (val, meta) => Text(
                        val.toStringAsFixed(1),
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
                      interval: (maxDay - minDay <= 14) ? 2.0 : 7.0,
                      getTitlesWidget: (val, meta) {
                        final d = val.toInt();
                        if (d >= minDay && d <= maxDay) {
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
                    isCurved: spotsActual.length > 2,
                    curveSmoothness: 0.3,
                    color: AppColors.primaryDark,
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: AppColors.primaryDark,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                    ),
                  ),
                  // Target FCR Benchmark Line
                  if (spotsTarget.isNotEmpty)
                    LineChartBarData(
                      spots: spotsTarget,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF10B981),
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

  double _getStandardTargetFcr(int day) {
    if (day <= 7) return 0.88;
    if (day <= 14) return 0.88 + (day - 7) * (1.06 - 0.88) / 7.0;
    if (day <= 21) return 1.06 + (day - 14) * (1.27 - 1.06) / 7.0;
    if (day <= 28) return 1.27 + (day - 21) * (1.41 - 1.27) / 7.0;
    if (day <= 35) return 1.41 + (day - 28) * (1.54 - 1.41) / 7.0;
    if (day <= 42) return 1.54 + (day - 35) * (1.69 - 1.54) / 7.0;
    return 1.69;
  }

  Widget _legendDot(Color color, String label, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDashed ? 14 : 9,
          height: isDashed ? 3 : 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDashed ? 2 : 5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
