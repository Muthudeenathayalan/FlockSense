import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/widgets/hen_icon.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_farm_switcher_bar.dart';
import 'package:flock_sense/features/home/presentation/widgets/home_telemetry_button.dart';

/// Top SliverAppBar greeting header with live date badge, telemetry status, facility switcher, and notification trigger.
class HomeCommandHeader extends ConsumerWidget {
  const HomeCommandHeader({
    super.key,
    required this.displayName,
    required this.onNotificationTap,
    this.data,
  });

  final String? displayName;
  final VoidCallback onNotificationTap;
  final HomeDashboardData? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);
    final greeting = (displayName == null || displayName!.isEmpty)
        ? 'Command Center'
        : 'Hello, ${displayName!.split(' ').first}';

    final dashboardData = data;
    final activeFarmName = dashboardData?.activeFarm?.farmName ??
        (dashboardData != null && dashboardData.farms.isNotEmpty
            ? dashboardData.farms.first.farmName
            : 'Main Facility');
    final todayMortality = dashboardData?.todayMortality ?? 0;
    final isSafe = todayMortality == 0;

    return SliverAppBar(
      expandedHeight: 156,
      pinned: true,
      backgroundColor: HomeTokens.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF104422), Color(0xFF14522A), Color(0xFF14532D)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HomeTokens.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: HomeTokens.screenGutter,
                right: HomeTokens.screenGutter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Date Badge & (Live Telemetry Status + Notification Bell)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Live Date badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Controls: Live Telemetry Pill + Notification Bell
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Interactive Live Telemetry Pill
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: dashboardData == null
                                    ? null
                                    : () => HomeTelemetryButton.openSheet(
                                          context,
                                          dashboardData,
                                        ),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSafe
                                          ? Colors.white.withValues(alpha: 0.22)
                                          : const Color(0xFFFCA5A5)
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isSafe
                                              ? const Color(0xFF4ADE80)
                                              : const Color(0xFFF87171),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isSafe
                                                      ? const Color(0xFF4ADE80)
                                                      : const Color(0xFFF87171))
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'Live Telemetry',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSafe
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB91C1C),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isSafe
                                              ? 'Online'
                                              : '$todayMortality Loss${todayMortality == 1 ? "" : "es"}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Notification Bell Trigger
                            GestureDetector(
                              onTap: onNotificationTap,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: HomeTokens.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Greeting
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Integrated Current Facility Switcher Pill
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: dashboardData == null
                            ? null
                            : () => HomeFarmSwitcherBar.showSwitcherSheet(
                                  context,
                                  ref,
                                  dashboardData,
                                ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HenIcon(
                                size: 13,
                                color: Color(0xFF86EFAC),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'CURRENT FACILITY',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  activeFarmName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 15,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
