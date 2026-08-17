import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';

class PopulationPieChart extends StatelessWidget {
  const PopulationPieChart({
    super.key,
    required this.currentBirds,
    required this.deadBirds,
  });

  final int currentBirds;
  final int deadBirds;

  @override
  Widget build(BuildContext context) {
    final total = currentBirds + deadBirds;
    if (total == 0) {
      return const Center(child: Text('No bird data available', style: TextStyle(color: AppColors.textSecondary)));
    }

    final livePct = ((currentBirds / total) * 100).toStringAsFixed(1);
    final deadPct = ((deadBirds / total) * 100).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: AppColors.primary,
                  value: currentBirds.toDouble(),
                  title: '$livePct%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: AppColors.danger,
                  value: deadBirds > 0 ? deadBirds.toDouble() : 0.001,
                  title: '$deadPct%',
                  radius: 46,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem(color: AppColors.primary, label: 'Live Birds', count: currentBirds),
              const SizedBox(height: 12),
              _legendItem(color: AppColors.danger, label: 'Dead Birds', count: deadBirds),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label, required int count}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('$count birds', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
