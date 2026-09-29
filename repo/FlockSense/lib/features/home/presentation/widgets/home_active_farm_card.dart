import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/widgets/hen_icon.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

/// Active facility card displaying shed details or prompt to register a farm.
class HomeActiveFarmCard extends StatelessWidget {
  const HomeActiveFarmCard({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    if (data.farms.isEmpty) {
      return _EmptyFarmCard(
        onCreateFarm: () => Navigator.pushNamed(context, AppRoutes.farmSetup),
      );
    }

    final farm = data.activeFarm ?? (data.farms.isNotEmpty ? data.farms.first : null);
    final farmName = farm?.farmName ?? 'Main Facility';
    final farmType = farm?.farmType ?? 'EC (Environment Controlled)';
    final location = farm?.address ?? 'Active Poultry Shed';

    return Container(
      padding: const EdgeInsets.all(HomeTokens.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        boxShadow: HomeTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HomeTokens.primary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const HenIcon(
              size: 20,
              color: Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  farmName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$farmType • $location',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0x99FFFFFF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.farms),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'All Farms',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFarmCard extends StatelessWidget {
  const _EmptyFarmCard({required this.onCreateFarm});
  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        border: Border.all(color: HomeTokens.border, width: 1),
        boxShadow: HomeTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: HomeTokens.greenTint,
              shape: BoxShape.circle,
            ),
            child: const HenIcon(size: 24, color: HomeTokens.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Farms Configured',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Register your poultry facility to track flock batches.',
                  style: TextStyle(fontSize: 12, color: HomeTokens.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCreateFarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeTokens.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
              ),
            ),
            child: const Text(
              'Add Farm',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
