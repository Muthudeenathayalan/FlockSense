import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_list_screen.dart';

const Color _kPrimary = Color(0xFF16A34A);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

/// Displays the Sheds & Poultry Houses section in the Farm Command Center.
/// Enforces the core poultry hierarchy: Farm -> Shed -> Batch.
class FarmShedsSection extends StatelessWidget {
  const FarmShedsSection({
    super.key,
    required this.farm,
    required this.sheds,
    required this.batches,
  });

  final FarmModel farm;
  final List<ShedModel> sheds;
  final List<BatchModel> batches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SHEDS & HOUSES (${sheds.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (sheds.length > 2)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShedListScreen(farm: farm),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShedFormScreen(
                          farmId: farm.id,
                          farm: farm,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Shed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary.withValues(alpha: 0.12),
                    foregroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sheds.isEmpty)
          _buildEmptyShedsCard(context)
        else
          Column(
            children: sheds.map((shed) => _buildShedCard(context, shed)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyShedsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.domain_add_rounded,
              color: _kPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Step 2: Add your first Shed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Every flock must be housed in a shed. Set up your poultry house dimensions and capacity to start placing batches.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _kTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShedFormScreen(
                    farmId: farm.id,
                    farm: farm,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Shed Now'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShedCard(BuildContext context, ShedModel shed) {
    // Find active batch for this shed
    final activeBatch = batches.where((b) {
      final matchesShed = b.shedId == shed.id;
      final isActive = b.status.toLowerCase() == 'active';
      return matchesShed && isActive;
    }).firstOrNull;

    final hasActiveBatch = activeBatch != null;

    final resolvedCapacity = shed.capacity ??
        (shed.totalSqFt > 0
            ? (farm.farmType.toUpperCase() == 'EC'
                ? (shed.totalSqFt / 0.75).round()
                : (shed.totalSqFt / 1.2).round())
            : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveBatch
              ? _kPrimary.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shed Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasActiveBatch
                      ? _kPrimary.withValues(alpha: 0.12)
                      : Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.domain_rounded,
                  color: hasActiveBatch ? _kPrimary : Colors.blueGrey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shed.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shed.lengthFt.toInt()} × ${shed.widthFt.toInt()} ft • ${shed.totalSqFt.toInt()} sq ft',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Capacity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets_rounded, size: 12, color: _kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$resolvedCapacity birds',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Step 3: Batch Status & Action
          if (hasActiveBatch)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activeBatch.batchName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          '${activeBatch.currentBirds} birds placed • Day ${DateTime.now().difference(activeBatch.placementDate).inDays + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BatchCommandCenterScreen(
                          farmId: farm.id,
                          batchId: activeBatch.id,
                          batchName: activeBatch.batchName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined, size: 14),
                  label: const Text('View Batch', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: BorderSide(color: _kPrimary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Shed is empty & sanitized',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BatchFormScreen(
                          farmId: farm.id,
                          shedId: shed.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Create Batch in ${shed.name}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
