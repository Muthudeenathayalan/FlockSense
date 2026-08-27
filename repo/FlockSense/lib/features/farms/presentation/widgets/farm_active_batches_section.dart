import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

const Color _kPrimary = Color(0xFF16A34A);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

/// Displays the active batches list within a farm.
class FarmActiveBatchesSection extends StatelessWidget {
  const FarmActiveBatchesSection({super.key, required this.farm});

  final FarmModel farm;

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
                const Text(
                  'ACTIVE BATCHES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BatchListScreen(
                      farmId: farm.id,
                      farmName: farm.farmName,
                    ),
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
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<BatchModel>>(
          stream: BatchService.watchBatches(farm.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: _kPrimary,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            final batches = snapshot.data ?? [];
            final activeBatches = batches
                .where((b) => b.status.toLowerCase() == 'active')
                .toList();

            if (activeBatches.isEmpty) {
              return Container(
                width: double.infinity,
                decoration: AppDesign.cardDecoration,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.layers_outlined,
                        color: _kTextSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Batches',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start a new flock cycle on this farm',
                      style: TextStyle(fontSize: 13, color: _kTextSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BatchFormScreen(farmId: farm.id),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: _kPrimary,
                      ),
                      label: const Text(
                        'Add First Batch',
                        style: TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeBatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final batch = activeBatches[index];
                return _ActiveBatchCard(batch: batch, farm: farm);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ActiveBatchCard extends StatelessWidget {
  const _ActiveBatchCard({required this.batch, required this.farm});

  final BatchModel batch;
  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    final birdsCount = batch.currentBirds > 0
        ? batch.currentBirds
        : batch.totalBirds;
    final ageDays = DateTime.now().difference(batch.placementDate).inDays;
    final breedText = batch.breedOrFlockType.isNotEmpty
        ? batch.breedOrFlockType
        : 'Broiler';

    return Container(
      decoration: AppDesign.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BatchCommandCenterScreen(
                  farmId: farm.id,
                  batchId: batch.id,
                  batchName: batch.batchName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status badge and chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Batch Name
                Text(
                  batch.batchName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle: Birds & Breed
                Text(
                  '${NumberFormat('#,###').format(birdsCount)} birds • $breedText',
                  style: const TextStyle(fontSize: 13, color: _kTextSecondary),
                ),
                const SizedBox(height: 12),

                // Bottom Divider & Action
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: _kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Day ${ageDays >= 0 ? ageDays : 0}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'View Batch →',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
