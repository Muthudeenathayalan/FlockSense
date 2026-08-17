import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AiChartView extends StatelessWidget {
  final String chartType;

  const AiChartView({super.key, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final type = chartType.toLowerCase().trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getChartTitle(type),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B5E20)),
              ),
              const Icon(Icons.analytics, size: 16, color: Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildChartWidget(type)),
        ],
      ),
    );
  }

  String _getChartTitle(String type) {
    switch (type) {
      case 'weight':
        return 'BODY WEIGHT GROWTH CURVE (GRAMS)';
      case 'mortality':
        return 'DAILY MORTALITY COUNT TREND';
      case 'feed':
        return 'DAILY FEED INTAKE (KG)';
      case 'water':
        return 'DAILY WATER INTAKE (L)';
      case 'profit':
        return 'REVENUE VS EXPENSE OVERVIEW (₹)';
      default:
        return 'FLOCK TELEMETRY TREND';
    }
  }

  Widget _buildChartWidget(String type) {
    switch (type) {
      case 'weight':
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(1, 56), FlSpot(7, 185), FlSpot(14, 500),
                  FlSpot(21, 913), FlSpot(28, 1475), FlSpot(35, 2115),
                ],
                isCurved: true,
                color: const Color(0xFF1B5E20),
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        );
      case 'mortality':
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2, color: Colors.red.shade400)]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1, color: Colors.red.shade400)]),
              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: Colors.red.shade600)]),
              BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 2, color: Colors.red.shade400)]),
              BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 3, color: Colors.red.shade400)]),
            ],
          ),
        );
      case 'feed':
        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 120, color: const Color(0xFF00838F))]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 180, color: const Color(0xFF00838F))]),
              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 240, color: const Color(0xFF00838F))]),
              BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 310, color: const Color(0xFF00838F))]),
              BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 380, color: const Color(0xFF00838F))]),
            ],
          ),
        );
      case 'profit':
      default:
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(1, 10), FlSpot(2, 25), FlSpot(3, 45), FlSpot(4, 70), FlSpot(5, 110),
                ],
                isCurved: true,
                color: Colors.amber.shade700,
                barWidth: 3,
              ),
            ],
          ),
        );
    }
  }
}
