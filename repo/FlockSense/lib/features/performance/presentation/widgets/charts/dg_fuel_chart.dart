import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

class DgFuelTrendChart extends StatelessWidget {
  final List<DailyRecordModel> records;

  const DgFuelTrendChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final dgRecords = records
        .where((r) => r.dgLevelLiters != null)
        .toList()
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    if (dgRecords.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text(
          'No DG telemetry data logged yet.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < dgRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), dgRecords[i].dgLevelLiters!));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.electric_bolt_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'DG Fuel Level Trend (Liters)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
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
}
