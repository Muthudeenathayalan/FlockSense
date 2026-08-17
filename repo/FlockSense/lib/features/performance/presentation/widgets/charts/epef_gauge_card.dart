import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class EpefGaugeCard extends StatelessWidget {
  const EpefGaugeCard({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final ageDays = data.batchAgeDays > 0 ? data.batchAgeDays : 35;
    final livability = data.totalInitialBirds > 0
        ? ((data.totalInitialBirds - data.totalMortality) / data.totalInitialBirds * 100)
        : 97.0;
    final avgWeightKg = data.averageWeightGrams > 0 ? (data.averageWeightGrams / 1000.0) : 2.0;
    final fcr = data.fcr > 0 ? data.fcr : 1.55;

    final epef = (ageDays * fcr) > 0 ? ((livability * avgWeightKg) / (ageDays * fcr) * 100) : 0.0;

    String tierLabel;
    Color tierColor;
    if (epef >= 400) {
      tierLabel = 'EXCELLENT';
      tierColor = const Color(0xFF10B981);
    } else if (epef >= 350) {
      tierLabel = 'GOOD';
      tierColor = AppColors.primary;
    } else if (epef >= 300) {
      tierLabel = 'AVERAGE';
      tierColor = const Color(0xFFE49B25);
    } else {
      tierLabel = 'POOR / LAGGING';
      tierColor = AppColors.danger;
    }

    final progress = (epef / 500.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  epef.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: tierColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'EPEF Performance Score',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                tierLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: tierColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress Gauge Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppColors.surfaceSoft,
            valueColor: AlwaysStoppedAnimation<Color>(tierColor),
          ),
        ),
        const SizedBox(height: 12),

        // Formula Breakdown Strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricCell('Livability', '${livability.toStringAsFixed(1)}%'),
              _metricCell('Avg Weight', '${avgWeightKg.toStringAsFixed(2)}kg'),
              _metricCell('Age', '$ageDays d'),
              _metricCell('FCR', fcr.toStringAsFixed(2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCell(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
