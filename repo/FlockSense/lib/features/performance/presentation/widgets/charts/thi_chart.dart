import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class ThiChart extends StatelessWidget {
  const ThiChart({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.dailyRecords.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No environmental THI telemetry available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final records = data.dailyRecords;
    final spotsTemp = <FlSpot>[];
    final spotsHumid = <FlSpot>[];

    for (int i = 0; i < records.length; i++) {
      // Brooding target temperature curve: Starts ~32°C on Day 1, reduces gradually to ~20°C
      final temp = (32.0 - (i * 0.28)).clamp(20.0, 34.0);
      final humid = (60.0 + (i % 7 * 1.5)).clamp(50.0, 75.0);

      spotsTemp.add(FlSpot(i.toDouble(), temp));
      spotsHumid.add(FlSpot(i.toDouble(), humid));
    }

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFFE53935), 'Temperature (°C)'),
              const SizedBox(width: 20),
              _legendDot(const Color(0xFF0284C7), 'Relative Humidity (%)'),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 10.0,
                maxY: 90.0,
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
                        '${val.toInt()}°',
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
                  // Temperature Line
                  LineChartBarData(
                    spots: spotsTemp,
                    isCurved: true,
                    color: const Color(0xFFE53935),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // Humidity Line
                  LineChartBarData(
                    spots: spotsHumid,
                    isCurved: true,
                    color: const Color(0xFF0284C7),
                    barWidth: 2,
                    dashArray: [5, 4],
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
          width: 8,
          height: 8,
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
