import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class _WeighInPoint {
  final int day;
  final double weightGrams;
  const _WeighInPoint(this.day, this.weightGrams);
}

class _AdgBarItem {
  final int x;
  final String label;
  final String tooltip;
  final double adg;
  final Color color;

  const _AdgBarItem({
    required this.x,
    required this.label,
    required this.tooltip,
    required this.adg,
    required this.color,
  });
}

class AdgChart extends StatelessWidget {
  const AdgChart({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final weighIns = <_WeighInPoint>[];

    // Starting chick weight milestone (Day 0)
    final chickWeightGrams = (data.activeBatch?.chickAvgWeight != null &&
            data.activeBatch!.chickAvgWeight! > 0)
        ? (data.activeBatch!.chickAvgWeight! <= 1.0
            ? data.activeBatch!.chickAvgWeight! * 1000.0
            : data.activeBatch!.chickAvgWeight!)
        : 40.0;

    weighIns.add(_WeighInPoint(0, chickWeightGrams));

    // Gather unique actual weigh-ins sorted by batchAgeDay
    final sortedRecords = [...data.dailyRecords]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));

    for (final r in sortedRecords) {
      if (r.avgWeightGrams > 0) {
        // Avoid duplicate entry for the same day
        if (weighIns.isNotEmpty && weighIns.last.day == r.batchAgeDay) {
          weighIns.removeLast();
        }
        weighIns.add(_WeighInPoint(r.batchAgeDay, r.avgWeightGrams));
      }
    }

    // If only Day 0 exists (no user weigh-ins recorded yet)
    if (weighIns.length <= 1) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up_rounded,
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
                'Average Daily Gain (ADG) calculates automatically between recorded weigh-in days.',
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

    final barItems = <_AdgBarItem>[];

    for (int i = 1; i < weighIns.length; i++) {
      final prev = weighIns[i - 1];
      final curr = weighIns[i];
      final daysDiff = curr.day - prev.day;

      if (daysDiff > 0) {
        final gain = ((curr.weightGrams - prev.weightGrams) / daysDiff).clamp(0.0, 200.0);
        final Color barColor;
        if (gain >= 45.0) {
          barColor = const Color(0xFF10B981);
        } else if (gain >= 30.0) {
          barColor = const Color(0xFFE49B25);
        } else {
          barColor = AppColors.danger;
        }

        final label = prev.day == 0 ? 'D${curr.day}' : 'D${prev.day}-${curr.day}';
        final tooltip = 'D${prev.day}→D${curr.day}: ${gain.toStringAsFixed(1)}g/day';

        barItems.add(
          _AdgBarItem(
            x: barItems.length,
            label: label,
            tooltip: tooltip,
            adg: gain,
            color: barColor,
          ),
        );
      }
    }

    if (barItems.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Insufficient weigh-in intervals for ADG calculation',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final groups = barItems.map((item) {
      return BarChartGroupData(
        x: item.x,
        barRods: [
          BarChartRodData(
            toY: item.adg,
            color: item.color,
            width: barItems.length <= 4 ? 22 : 12,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
            ),
          ),
        ],
      );
    }).toList();

    double maxGain = 0;
    for (final item in barItems) {
      if (item.adg > maxGain) maxGain = item.adg;
    }
    final safeMaxY = (maxGain > 10 ? maxGain * 1.2 : 60.0).clamp(30.0, 160.0);

    return SizedBox(
      height: 230,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF10B981), 'Good (≥45g/d)'),
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
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 0.8,
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex >= 0 && groupIndex < barItems.length) {
                        return BarTooltipItem(
                          barItems[groupIndex].tooltip,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}g',
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
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < barItems.length) {
                          return Text(
                            barItems[idx].label,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
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
