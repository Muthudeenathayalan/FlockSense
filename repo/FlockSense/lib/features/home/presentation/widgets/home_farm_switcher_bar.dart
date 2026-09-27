import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/widgets/hen_icon.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Farm selector bar placed directly above the telemetry button.
/// Allows instant multi-facility switching and navigation to farm setup.
class HomeFarmSwitcherBar extends ConsumerWidget {
  const HomeFarmSwitcherBar({
    super.key,
    required this.activeFarmName,
    required this.totalFarms,
    required this.data,
  });

  final String activeFarmName;
  final int totalFarms;
  final HomeDashboardData data;

  void _showSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Active Facility',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HomeTokens.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, AppRoutes.farmSetup);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: HomeTokens.primary),
                    label: const Text(
                      'Add Farm',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: HomeTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Switch the dashboard context to monitor live telemetry for a specific site.',
                style: TextStyle(fontSize: 12, color: HomeTokens.textSecondary),
              ),
              const SizedBox(height: 16),
              if (data.farms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HomeTokens.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HomeTokens.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No farms registered yet. Tap "Add Farm" above to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: HomeTokens.textSecondary),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: data.farms.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final f = data.farms[i];
                      final isSelected = data.activeFarm?.id == f.id;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            switchDashboardFarm(ref, f.id);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? HomeTokens.greenTint.withValues(alpha: 0.5) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? HomeTokens.primary : HomeTokens.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? HomeTokens.primary : HomeTokens.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: HenIcon(
                                    size: 16,
                                    color: isSelected ? Colors.white : HomeTokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.farmName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? HomeTokens.primaryDark : HomeTokens.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${f.farmType} • ${f.address.isNotEmpty ? f.address : "Main Shed"}',
                                        style: const TextStyle(fontSize: 11, color: HomeTokens.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: HomeTokens.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSwitcher(context, ref),
        borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
            border: Border.all(color: const Color(0xFFD1FAE5), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: HomeTokens.primaryDark.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4.5),
                decoration: BoxDecoration(
                  color: HomeTokens.greenTint,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const HenIcon(
                  size: 15,
                  color: HomeTokens.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CURRENT FACILITY',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: HomeTokens.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      activeFarmName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: HomeTokens.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HomeTokens.primaryDark, HomeTokens.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: HomeTokens.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_alt_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Switch',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 1),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 13,
                      color: Colors.white,
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
