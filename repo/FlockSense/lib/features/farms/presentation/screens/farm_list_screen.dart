import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({super.key});

  Future<void> _deleteFarm(BuildContext context, FarmModel farm) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Delete farm?',
      message: 'Delete ${farm.farmName} and all linked data?',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (!ok) return;

    try {
      await FarmService.deleteFarm(farm.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Farm deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  String _locationFor(FarmModel farm) {
    final parts = <String>[];
    if (farm.areaName?.trim().isNotEmpty ?? false) {
      parts.add(farm.areaName!.trim());
    }
    if (farm.district?.trim().isNotEmpty ?? false) {
      parts.add(farm.district!.trim());
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    if (farm.address.trim().isNotEmpty) {
      return farm.address.trim();
    }
    return 'Location not added';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton(
              label: 'New Farm',
              icon: Icons.add_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.farmSetup),
              variant: AppButtonVariant.gradient,
              size: AppButtonSize.small,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: farmsAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (_, __) => AppEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Unable to load farms',
            message: 'Check your connection and try again.',
            buttonLabel: 'Retry',
            onButtonPressed: () => ref.invalidate(farmListProvider),
          ),
          data: (farms) {
            if (farms.isEmpty) {
              return AppEmptyState(
                icon: Icons.holiday_village_outlined,
                title: 'No farms yet',
                message:
                    'Create your first farm to start managing batches and records.',
                buttonLabel: 'Create Farm',
                onButtonPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.farmSetup),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: farms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final farm = farms[index];
                final location = _locationFor(farm);

                return AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmCommandCenterScreen(farm: farm),
                      ),
                    );
                  },
                  onLongPress: () => _deleteFarm(context, farm),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: const BoxDecoration(
                          gradient: AppDesign.headerGreenGradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                farm.farmName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                farm.farmType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppDesign.statusChip(
                              farm.isActive ? 'Active' : 'Inactive',
                              Colors.white.withOpacity(0.2),
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.straighten_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${farm.lengthFt.toStringAsFixed(0)}×${farm.widthFt.toStringAsFixed(0)} ft • ${farm.totalSqFt.toStringAsFixed(0)} ft²',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    farm.farmType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.oceanLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    farm.flockType.isEmpty
                                        ? 'Broiler'
                                        : farm.flockType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ocean,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
