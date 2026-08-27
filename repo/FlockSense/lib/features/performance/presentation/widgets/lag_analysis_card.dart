import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

class LagAnalysisCard extends StatelessWidget {
  const LagAnalysisCard({super.key, required this.data});

  final GrowthAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final lags = _computeLags();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: lags.any((l) => l.isCritical)
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.border.withValues(alpha: 0.8),
          width: lags.any((l) => l.isCritical) ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C173D24),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: lags.any((l) => l.isCritical)
                    ? [const Color(0xFFFEF2F2), Colors.white]
                    : [const Color(0xFFE0F2FE), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lags.any((l) => l.isCritical)
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    lags.any((l) => l.isCritical)
                        ? Icons.report_problem_rounded
                        : Icons.analytics_rounded,
                    color: lags.any((l) => l.isCritical)
                        ? AppColors.danger
                        : const Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lag & Bottleneck Diagnostic',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lags.isEmpty
                            ? 'All key performance indicators are on target'
                            : '${lags.length} performance bottlenecks detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: lags.any((l) => l.isCritical)
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: lags.isEmpty
                        ? const Color(0xFF10B981)
                        : (lags.any((l) => l.isCritical)
                              ? AppColors.danger
                              : const Color(0xFFE49B25)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lags.isEmpty
                        ? 'HEALTHY'
                        : (lags.any((l) => l.isCritical)
                              ? 'ATTENTION'
                              : 'WARNING'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Lag Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: lags.isEmpty
                ? const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Flock performance meets or exceeds target benchmarks.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: lags.map((lag) => _buildLagTile(lag)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  List<_LagMetric> _computeLags() {
    final list = <_LagMetric>[];

    // 1. FCR Check (Target: ~1.50)
    if (data.fcr > 1.55) {
      final fcrDiff = ((data.fcr - 1.50) / 1.50 * 100).toStringAsFixed(1);
      list.add(
        _LagMetric(
          title: 'Feed Conversion Ratio (FCR) Lagging',
          metric: 'FCR ${data.fcr.toStringAsFixed(2)}',
          target: 'Target: 1.50',
          description:
              'Current FCR is $fcrDiff% higher than target. Check feed waste, water availability, or feed formula energy level.',
          isCritical: data.fcr > 1.70,
          icon: Icons.rice_bowl_rounded,
        ),
      );
    }

    // 2. Average Weight Check
    if (data.averageWeightGrams > 0) {
      const targetWeightGrams = 2000.0;
      if (data.averageWeightGrams < 1850) {
        final gapGrams = (targetWeightGrams - data.averageWeightGrams)
            .toStringAsFixed(0);
        list.add(
          _LagMetric(
            title: 'Body Weight Growth Deficit',
            metric: '${data.averageWeightGrams.toStringAsFixed(0)}g',
            target: 'Target: ${targetWeightGrams.toInt()}g',
            description:
                'Flock average weight is lagging by ${gapGrams}g. Inspect brooding temperatures and feed intake per bird.',
            isCritical: data.averageWeightGrams < 1700,
            icon: Icons.monitor_weight_rounded,
          ),
        );
      }
    }

    // 3. Water-to-Feed Ratio Check (Optimal: 1.8 to 2.1)
    if (data.totalFeedConsumedKg > 0 && data.totalWaterConsumedLiters > 0) {
      final ratio = data.totalWaterConsumedLiters / data.totalFeedConsumedKg;
      if (ratio < 1.6 || ratio > 2.3) {
        list.add(
          _LagMetric(
            title: 'Water-to-Feed Ratio Anomaly',
            metric: '${ratio.toStringAsFixed(2)} : 1',
            target: 'Optimal: 1.8 - 2.1 : 1',
            description: ratio < 1.6
                ? 'Low water intake detected. Reduced drinking limits feed consumption and suppresses growth.'
                : 'High water intake detected. Possible drinker leakage, heat stress, or excessive mineral salt in water.',
            isCritical: ratio < 1.4 || ratio > 2.5,
            icon: Icons.water_drop_rounded,
          ),
        );
      }
    }

    // 4. Mortality Rate Check (Target Livability > 97.0%)
    final livability = data.totalInitialBirds > 0
        ? ((data.totalInitialBirds - data.totalMortality) /
              data.totalInitialBirds *
              100)
        : 100.0;

    if (livability < 96.5) {
      final mortalityRate = (100.0 - livability).toStringAsFixed(1);
      list.add(
        _LagMetric(
          title: 'Mortality Threshold Exceeded',
          metric: '$mortalityRate% Mortality (${data.totalMortality} birds)',
          target: 'Livability Target: 97.0%+',
          description:
              'Cumulative mortality rate is elevated. Review biosecurity, ventilation airflow, and vaccination history.',
          isCritical: livability < 95.0,
          icon: Icons.warning_amber_rounded,
        ),
      );
    }

    return list;
  }

  Widget _buildLagTile(_LagMetric lag) {
    final color = lag.isCritical ? AppColors.danger : const Color(0xFFE49B25);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(lag.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lag.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      lag.metric,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lag.target,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lag.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LagMetric {
  final String title;
  final String metric;
  final String target;
  final String description;
  final bool isCritical;
  final IconData icon;

  _LagMetric({
    required this.title,
    required this.metric,
    required this.target,
    required this.description,
    required this.isCritical,
    required this.icon,
  });
}
