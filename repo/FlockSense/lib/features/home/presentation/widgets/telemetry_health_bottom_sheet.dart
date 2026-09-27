import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Modal bottom sheet displaying detailed telemetry audit and sensor diagnostics.
class TelemetryHealthBottomSheet extends StatelessWidget {
  const TelemetryHealthBottomSheet({
    super.key,
    required this.data,
  });

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final liveBirdsStr = NumberFormat('#,###').format(data.liveBirds);
    final fcr = data.estFcr != null ? data.estFcr!.toStringAsFixed(2) : '--';
    final farmName = data.activeFarm?.farmName ?? 'Main Facility';
    final isSafe = data.todayMortality == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title & Sync Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Shed Telemetry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: HomeTokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$farmName • Firebase Real-Time Stream',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HomeTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HomeTokens.greenTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_rounded, size: 12, color: HomeTokens.primary),
                      SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HomeTokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Health Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSafe ? HomeTokens.greenTint.withValues(alpha: 0.5) : HomeTokens.redTint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
                border: Border.all(
                  color: isSafe ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSafe ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: isSafe ? HomeTokens.primary : HomeTokens.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSafe
                          ? 'Zero bird losses recorded today. All environmental indicators optimal.'
                          : '${data.todayMortality} bird mortality logged today. Inspect drinker lines and ventilation.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSafe ? HomeTokens.primaryDark : const Color(0xFF991B1B),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4-Tile Telemetry Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _telemetryTile(
                    label: "Today's Losses",
                    value: '${data.todayMortality} birds',
                    color: isSafe ? HomeTokens.primary : HomeTokens.red,
                    icon: Icons.health_and_safety_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _telemetryTile(
                    label: 'Live Census',
                    value: '$liveBirdsStr birds',
                    color: HomeTokens.blue,
                    icon: Icons.groups_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _telemetryTile(
                    label: 'Estimated FCR',
                    value: fcr,
                    color: HomeTokens.amber,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _telemetryTile(
                    label: 'Active Batches',
                    value: '${data.activeBatchCount} in sheds',
                    color: HomeTokens.indigo,
                    icon: Icons.layers_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HomeTokens.textSecondary,
                      side: const BorderSide(color: HomeTokens.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
                      ),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyRecordsDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.post_add_rounded, size: 16),
                    label: const Text('Add Daily Log', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeTokens.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeTokens.background,
        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: HomeTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
