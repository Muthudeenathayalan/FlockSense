import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

/// Sliver AppBar header for Farm Command Center matching the reference design:
/// lush green gradient, ambient circular glow, status chips, and 4 key header stats.
class FarmIdentityHeader extends StatelessWidget {
  const FarmIdentityHeader({
    super.key,
    required this.farm,
    required this.liveBirds,
    required this.activeBatchesCount,
    required this.shedsCount,
    required this.onFarmUpdated,
    required this.onDeleteFarm,
    this.onRefresh,
  });

  final FarmModel farm;
  final int liveBirds;
  final int activeBatchesCount;
  final int shedsCount;
  final ValueChanged<FarmModel> onFarmUpdated;
  final VoidCallback onDeleteFarm;
  final VoidCallback? onRefresh;

  String get _fmtDate {
    final d = farm.createdAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  String get _typePill {
    if (farm.farmType.trim().isNotEmpty) return farm.farmType.trim();
    if (farm.flockType.trim().isNotEmpty) return farm.flockType.trim();
    return 'Broiler';
  }

  String get _areaOrFlockPill {
    if (farm.totalSqFt > 0) {
      return '${farm.totalSqFt.toInt()} ft²';
    } else if (farm.lengthFt > 0 && farm.widthFt > 0) {
      return '${(farm.lengthFt * farm.widthFt).toInt()} ft²';
    }
    return farm.flockType.trim().isNotEmpty ? farm.flockType.trim() : 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      title: Text(farm.farmName),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: onRefresh,
          ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
          tooltip: 'Edit Farm',
          onPressed: () async {
            final updated = await Navigator.of(context).push<FarmModel>(
              MaterialPageRoute(
                builder: (_) => FarmSetupScreen(initialFarm: farm),
              ),
            );
            if (updated != null) {
              onFarmUpdated(updated);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          tooltip: 'Delete Farm',
          onPressed: onDeleteFarm,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.headerGreenGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1AFFFFFF),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x12FFFFFF),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppDesign.statusChip(
                          _typePill,
                          const Color(0x28000000),
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        AppDesign.statusChip(
                          _areaOrFlockPill,
                          const Color(0x33D4A017),
                          textColor: Colors.white,
                        ),
                        const Spacer(),
                        AppDesign.statusChip(
                          farm.isActive ? 'ACTIVE' : 'INACTIVE',
                          farm.isActive
                              ? const Color(0x1A10B981)
                              : const Color(0x1AD4A017),
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDesign.headerStat(
                            'Live Birds',
                            '$liveBirds',
                            Icons.pets_rounded,
                          ),
                        ),
                        Expanded(
                          child: AppDesign.headerStat(
                            'Batches',
                            '$activeBatchesCount',
                            Icons.layers_rounded,
                          ),
                        ),
                        Expanded(
                          child: AppDesign.headerStat(
                            'Sheds',
                            '$shedsCount',
                            Icons.domain_rounded,
                          ),
                        ),
                        Expanded(
                          child: AppDesign.headerStat(
                            'Created',
                            _fmtDate,
                            Icons.calendar_today_rounded,
                          ),
                        ),
                      ],
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

