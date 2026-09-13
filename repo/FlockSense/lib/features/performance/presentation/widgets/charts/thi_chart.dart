import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class ThiChart extends StatelessWidget {
  const ThiChart({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    if (data.dailyRecords.isEmpty || !data.hasEnvironmentalData) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.thermostat_outlined,
                color: AppColors.textSecondary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'No environmental telemetry recorded',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Record shed temperature (°C) and humidity (%) in daily logs to monitor heat index.',
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

    final sortedRecords = [...data.dailyRecords]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));

    final spotsTemp = <FlSpot>[];
    final spotsHumid = <FlSpot>[];

    for (final r in sortedRecords) {
      final day = r.batchAgeDay.toDouble();
      if (r.temperature != null && r.temperature! > 0) {
        spotsTemp.add(FlSpot(day, r.temperature!));
      }
      if (r.humidity != null && r.humidity! > 0) {
        spotsHumid.add(FlSpot(day, r.humidity!));
      }
    }

    final allDays = [
      ...spotsTemp.map((s) => s.x.toInt()),
      ...spotsHumid.map((s) => s.x.toInt()),
    ];

    final minDay = allDays.isEmpty ? 1 : allDays.reduce((a, b) => a < b ? a : b);
    final maxDay = allDays.isEmpty ? 7 : (allDays.reduce((a, b) => a > b ? a : b) < 7 ? 7 : allDays.reduce((a, b) => a > b ? a : b));

    return SizedBox(
      height: 230,
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
                minX: minDay.toDouble(),
                maxX: maxDay.toDouble(),
                minY: 10.0,
                maxY: 100.0,
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
                        final isTemp = spot.barIndex == 0;
                        final label = isTemp ? 'Temperature' : 'Humidity';
                        final unit = isTemp ? '°C' : '%';
                        return LineTooltipItem(
                          'D${spot.x.toInt()} $label: ${spot.y.toStringAsFixed(1)}$unit',
                          TextStyle(
                            color: isTemp ? const Color(0xFFFCA5A5) : const Color(0xFFBAE6FD),
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
                      interval: 20.0,
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
                  // Temperature Line
                  LineChartBarData(
                    spots: spotsTemp,
                    isCurved: spotsTemp.length > 2,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFE53935),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: const Color(0xFFE53935),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                  ),
                  // Humidity Line
                  LineChartBarData(
                    spots: spotsHumid,
                    isCurved: spotsHumid.length > 2,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF0284C7),
                    barWidth: 2.2,
                    dashArray: [5, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: const Color(0xFF0284C7),
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                    ),
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
      mainAxisSize: MainAxisSize.min,
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
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
