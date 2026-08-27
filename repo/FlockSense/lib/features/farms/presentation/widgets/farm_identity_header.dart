import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

/// Sliver AppBar header for Farm Command Center with identity, type, area, and actions.
class FarmIdentityHeader extends StatelessWidget {
  const FarmIdentityHeader({
    super.key,
    required this.farm,
    required this.onFarmUpdated,
    required this.onDeleteFarm,
  });

  final FarmModel farm;
  final ValueChanged<FarmModel> onFarmUpdated;
  final VoidCallback onDeleteFarm;

  @override
  Widget build(BuildContext context) {
    final locationText = (farm.areaName != null && farm.areaName!.isNotEmpty)
        ? farm.areaName!
        : (farm.address.isNotEmpty ? farm.address : 'No location specified');
    final formattedType = _formatFarmType(farm.farmType);
    final areaText = farm.totalSqFt > 0
        ? '${NumberFormat('#,###').format(farm.totalSqFt.toInt())} ft²'
        : (farm.lengthFt > 0 && farm.widthFt > 0
              ? '${NumberFormat('#,###').format((farm.lengthFt * farm.widthFt).toInt())} ft²'
              : '');

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1B5E20),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
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
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
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
              // Ambient circular glow decorations
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm Name and Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              farm.farmName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Active status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: farm.isActive
                                  ? const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: farm.isActive
                                    ? const Color(
                                        0xFF86EFAC,
                                      ).withValues(alpha: 0.5)
                                    : Colors.white30,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: farm.isActive
                                        ? const Color(0xFF4ADE80)
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  farm.isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location & specs chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildHeaderMetaChip(
                            Icons.location_on_outlined,
                            locationText,
                          ),
                          _buildHeaderMetaChip(
                            Icons.domain_rounded,
                            formattedType,
                          ),
                          if (areaText.isNotEmpty)
                            _buildHeaderMetaChip(
                              Icons.square_foot_rounded,
                              areaText,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatFarmType(String type) {
    if (type.isEmpty) return 'Standard';
    final lower = type.toLowerCase();
    if (lower.contains('ec') || lower.contains('environment')) return 'EC Farm';
    if (lower.contains('open')) return 'Open Farm';
    if (lower.contains('semi')) return 'Semi-Closed';
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }
}
