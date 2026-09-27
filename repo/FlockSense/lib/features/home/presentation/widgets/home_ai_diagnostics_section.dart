import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Real-time AI biosecurity and telemetry diagnostics section.
class HomeAiDiagnosticsSection extends StatelessWidget {
  const HomeAiDiagnosticsSection({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HomeTokens.indigo, HomeTokens.blue],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'AI Intelligence',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Real-Time Diagnostics',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeTokens.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: HomeTokens.gapHeaderToBody),
        if (data.activeBatchCount == 0 || data.liveBirds == 0)
          Container(
            padding: const EdgeInsets.all(HomeTokens.cardPadding),
            decoration: BoxDecoration(
              color: HomeTokens.surface,
              borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
              border: Border.all(color: HomeTokens.border),
              boxShadow: HomeTokens.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HomeTokens.indigoTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: HomeTokens.indigo,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Intelligence on Standby',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HomeTokens.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Register your farm and start an active flock batch to receive automated telemetry diagnostics on feed conversion, mortality risk, and harvest readiness.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HomeTokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Diagnostic Tiles Stack
          if (data.todayMortality == 0)
            const _AiDiagnosticTile(
              category: 'HEALTH & BIOSECURITY',
              title: 'Zero Mortality Logged Today',
              subtitle: 'Flock mortality is under strict control across active sheds.',
              color: HomeTokens.primary,
              icon: Icons.health_and_safety_rounded,
            )
          else
            _AiDiagnosticTile(
              category: 'MORTALITY ALERT',
              title: '${data.todayMortality} Bird Losses Recorded Today',
              subtitle: 'Check shed ventilation, drinker line flow, and heat stress indicators.',
              color: HomeTokens.red,
              icon: Icons.warning_amber_rounded,
            ),
          const SizedBox(height: HomeTokens.gapTight),
          if (data.estFcr != null)
            _AiDiagnosticTile(
              category: 'FEED EFFICIENCY',
              title: 'Estimated FCR: ${data.estFcr!.toStringAsFixed(2)}',
              subtitle: data.estFcr! <= 1.60
                  ? 'Feed conversion is optimal and meeting commercial benchmarks.'
                  : 'FCR is elevated. Review feed spillage and feed formulation energy ratio.',
              color: data.estFcr! <= 1.60 ? HomeTokens.primary : HomeTokens.amber,
              icon: Icons.trending_up_rounded,
            )
          else
            const _AiDiagnosticTile(
              category: 'LOGGING ADVICE',
              title: 'Daily Telemetry Recommended',
              subtitle: 'Log daily feed intake and body weights to unlock live FCR tracking.',
              color: HomeTokens.sky,
              icon: Icons.edit_note_rounded,
            ),
          const SizedBox(height: HomeTokens.gapTight),
          _AiDiagnosticTile(
            category: 'SHED OCCUPANCY',
            title: '${NumberFormat('#,###').format(data.liveBirds)} Birds Under Active Care',
            subtitle: 'Telemetry streaming across ${data.activeBatchCount} flock cycle(s) in ${data.activeFarm?.farmName ?? "Main Facility"}.',
            color: HomeTokens.indigo,
            icon: Icons.warehouse_rounded,
          ),
        ],
      ],
    );
  }
}

class _AiDiagnosticTile extends StatelessWidget {
  const _AiDiagnosticTile({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String category;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
        border: Border.all(color: HomeTokens.border, width: 1),
        boxShadow: HomeTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: HomeTokens.textSecondary,
                    height: 1.25,
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
