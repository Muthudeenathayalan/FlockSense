import 'package:flutter/material.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';
import 'package:flock_sense/features/home/presentation/widgets/telemetry_health_bottom_sheet.dart';

/// Clickable live telemetry pulse button.
/// Replaces the static telemetry strip with an interactive button that opens
/// the detailed [TelemetryHealthBottomSheet] on tap.
class HomeTelemetryButton extends StatelessWidget {
  const HomeTelemetryButton({
    super.key,
    required this.todayMortality,
    required this.activeBatchesCount,
    required this.data,
  });

  final int todayMortality;
  final int activeBatchesCount;
  final HomeDashboardData data;

  static void openSheet(BuildContext context, HomeDashboardData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TelemetryHealthBottomSheet(data: data),
    );
  }

  void _openSheet(BuildContext context) => openSheet(context, data);

  @override
  Widget build(BuildContext context) {
    final isSafe = todayMortality == 0;
    final statusColor = isSafe ? HomeTokens.primary : HomeTokens.red;
    final summaryText = isSafe
        ? '0 Losses • Optimal'
        : '$todayMortality ${todayMortality == 1 ? "Loss" : "Losses"} Today';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
            border: Border.all(
              color: isSafe ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 5,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Live pulsating status dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 5,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Live Telemetry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HomeTokens.textPrimary,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: HomeTokens.greenTint,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.primaryDeep,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                summaryText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: HomeTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
