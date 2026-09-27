import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_stat_card.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// 2x2 Executive KPI grid with locked slot heights and aligned baselines.
/// Uses Row-Expanded pairs to eliminate aspect-ratio clipping and text overflow.
class HomeKpiGrid extends StatelessWidget {
  const HomeKpiGrid({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final hasFlock = data.liveBirds > 0;
    final fcr = data.estFcr;

    return Column(
      children: [
        // Row 1: Active Batches & Live Birds
        Row(
          children: [
            Expanded(
              child: HomeStatCard(
                icon: Icons.layers_rounded,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF0284C7),
                cardBg: const Color(0xFFF0F7FF),
                borderColor: const Color(0xFFBAE6FD),
                value: data.activeBatchCount.toString(),
                unit: 'batches',
                valueColor: const Color(0xFF0369A1),
                label: 'Active Batches',
                badgeText: data.activeBatchCount > 0
                    ? '${data.activeBatchCount} in shed'
                    : '0 batches',
                badgeColor: const Color(0xFF0284C7),
                badgeBg: const Color(0xFFE0F2FE),
              ),
            ),
            const SizedBox(width: HomeTokens.gapNormal),
            Expanded(
              child: HomeStatCard(
                icon: Icons.groups_rounded,
                iconBg: HomeTokens.greenTint,
                iconColor: HomeTokens.primary,
                cardBg: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                value: NumberFormat('#,###').format(data.liveBirds),
                unit: 'birds',
                valueColor: const Color(0xFF15803D),
                label: 'Live Population',
                badgeText: hasFlock ? 'Active Census' : '0 birds',
                badgeColor: HomeTokens.primary,
                badgeBg: HomeTokens.greenTint,
              ),
            ),
          ],
        ),
        const SizedBox(height: HomeTokens.gapNormal),

        // Row 2: Today's Mortality & Est. FCR
        Row(
          children: [
            Expanded(
              child: HomeStatCard(
                icon: Icons.health_and_safety_rounded,
                iconBg: const Color(0xFFFFE4E6),
                iconColor: const Color(0xFFE11D48),
                cardBg: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                value: hasFlock ? data.todayMortality.toString() : '--',
                unit: hasFlock ? 'losses' : null,
                valueColor: const Color(0xFFBE123C),
                label: "Today's Mortality",
                badgeText: !hasFlock
                    ? 'No flock'
                    : (data.todayMortality == 0 ? '0.0% • Safe' : '${data.todayMortality} Losses'),
                badgeColor: const Color(0xFFE11D48),
                badgeBg: const Color(0xFFFFE4E6),
              ),
            ),
            const SizedBox(width: HomeTokens.gapNormal),
            Expanded(
              child: HomeStatCard(
                icon: Icons.trending_up_rounded,
                iconBg: HomeTokens.amberTint,
                iconColor: const Color(0xFFD97706),
                cardBg: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                value: fcr != null ? fcr.toStringAsFixed(2) : '--',
                unit: fcr != null ? 'ratio' : null,
                valueColor: const Color(0xFFB45309),
                label: 'Est. FCR',
                badgeText: fcr != null ? 'Target: 1.50' : 'No telemetry',
                badgeColor: const Color(0xFFD97706),
                badgeBg: HomeTokens.amberTint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
