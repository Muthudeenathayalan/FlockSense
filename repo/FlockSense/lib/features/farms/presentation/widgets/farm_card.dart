import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({
    super.key,
    required this.farm,
    this.onTap,
    this.trailing,
  });

  final FarmModel farm;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _FarmCardContent(farm: farm)),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmCardContent extends StatelessWidget {
  const _FarmCardContent({
    required this.farm,
  });

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                farm.farmName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            const StatusBadge(label: 'Active'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          FarmService.getFormattedFarmType(farm.flockType),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          farm.address,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.pets, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${farm.birdCapacity} birds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(width: 16),
            Icon(Icons.local_hospital, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Health 92%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
