import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_section_header.dart';
import 'package:flock_sense/features/home/presentation/widgets/common/home_tokens.dart';

const List<List<Color>> _kBatchGradients = [
  [Color(0xFF16A34A), Color(0xFF059669)],
  [Color(0xFF2563EB), Color(0xFF4F46E5)],
  [Color(0xFFD97706), Color(0xFFEA580C)],
  [Color(0xFF7C3AED), Color(0xFF6366F1)],
  [Color(0xFF0284C7), Color(0xFF0D9488)],
];

/// Active flock batches section with aligned metric cards and carousel layout.
class HomeActiveBatchesSection extends StatelessWidget {
  const HomeActiveBatchesSection({
    super.key,
    required this.activeBatches,
    this.recentRecords = const <DailyRecordModel>[],
    required this.onAddBatch,
  });

  final List<BatchModel> activeBatches;
  final List<DailyRecordModel> recentRecords;
  final VoidCallback onAddBatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Active Batches',
          subtitle: activeBatches.isEmpty
              ? 'No live flocks in shed'
              : '${activeBatches.length} batch${activeBatches.length == 1 ? '' : 'es'} in growth cycle',
          trailing: activeBatches.isNotEmpty
              ? GestureDetector(
                  onTap: onAddBatch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: HomeTokens.greenTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: HomeTokens.primary),
                        SizedBox(width: 4),
                        Text(
                          'New Batch',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: HomeTokens.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: HomeTokens.gapHeaderToBody),
        if (activeBatches.isEmpty)
          _EmptyBatchCard(onAddBatch: onAddBatch)
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: activeBatches.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _BatchAvatarCard(
                batch: activeBatches[i],
                index: i,
                recentRecords: recentRecords,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BatchCommandCenterScreen(
                      farmId: activeBatches[i].farmId,
                      batchId: activeBatches[i].id,
                      batchName: activeBatches[i].batchName,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BatchAvatarCard extends StatelessWidget {
  const _BatchAvatarCard({
    required this.batch,
    required this.index,
    this.recentRecords = const <DailyRecordModel>[],
    required this.onTap,
  });

  final BatchModel batch;
  final int index;
  final List<DailyRecordModel> recentRecords;
  final VoidCallback onTap;

  List<Color> get _gradient => _kBatchGradients[index % _kBatchGradients.length];

  int get _ageDays =>
      DateTime.now().difference(batch.placementDate).inDays.clamp(0, 60);

  double get _ageProgress => (_ageDays / batch.cycleTargetDays.toDouble()).clamp(0.0, 1.0);

  int get _healthScore {
    final total = batch.totalBirds < 1 ? 1 : batch.totalBirds;
    return ((batch.currentBirds / total) * 100).round().clamp(0, 100);
  }

  String get _batchLetter {
    final name = batch.batchName.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return String.fromCharCode(65 + (index % 26));
  }

  ({String label, Color color, Color bg}) get _statusInfo {
    final s = _healthScore;
    if (s >= 95) return (label: 'Optimal', color: HomeTokens.primary, bg: HomeTokens.greenTint);
    if (s >= 85) return (label: 'Healthy', color: HomeTokens.primary, bg: HomeTokens.greenTint);
    if (s >= 70) return (label: 'Attention', color: HomeTokens.amber, bg: HomeTokens.amberTint);
    return (label: 'Critical', color: HomeTokens.red, bg: HomeTokens.redTint);
  }

  String get _fcrValue {
    final batchRecords = recentRecords.where((r) => r.batchId == batch.id).toList();
    if (batchRecords.isEmpty || batch.currentBirds <= 0) {
      return '--';
    }
    double totalFeed = 0;
    double latestWeightKg = 0;
    for (final r in batchRecords) {
      totalFeed += r.feedConsumedKg;
      if (r.avgWeightGrams > 0) {
        final w = r.avgWeightGrams / 1000.0;
        if (w > latestWeightKg) latestWeightKg = w;
      }
    }
    final totalGain = latestWeightKg * batch.currentBirds;
    if (totalGain <= 0 || totalFeed <= 0) return '--';
    return (totalFeed / totalGain).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient;
    final ageDays = _ageDays;
    final health = _healthScore;
    final status = _statusInfo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        child: Container(
          width: 184,
          padding: const EdgeInsets.all(HomeTokens.cardPadding),
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
            border: Border.all(color: HomeTokens.border, width: 1),
            boxShadow: HomeTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.batchName.isEmpty
                          ? 'Batch ${index + 1}'
                          : batch.batchName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HomeTokens.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(78, 78),
                        painter: _AgeRingPainter(
                          progress: _ageProgress,
                          trackColor: gradient[0].withValues(alpha: 0.12),
                          progressGradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withValues(alpha: 0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _batchLetter,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$health% Livability • Day $ageDays/${batch.cycleTargetDays}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: gradient[0],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _AlignedBatchMetricRow(
                icon: Icons.groups_outlined,
                label: 'Birds:',
                value: '${batch.currentBirds} live',
              ),
              const SizedBox(height: 4),
              _AlignedBatchMetricRow(
                icon: Icons.grass_outlined,
                label: 'FCR:',
                value: _fcrValue == '--' ? '--' : '$_fcrValue ratio',
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: gradient[0],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: gradient[0],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlignedBatchMetricRow extends StatelessWidget {
  const _AlignedBatchMetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: HomeTokens.textMuted),
        const SizedBox(width: 5),
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: HomeTokens.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HomeTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBatchCard extends StatelessWidget {
  const _EmptyBatchCard({required this.onAddBatch});
  final VoidCallback onAddBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            child: const Icon(Icons.layers_rounded, color: HomeTokens.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Active Batches',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: HomeTokens.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Add a new chick flock placement to track health.',
                  style: TextStyle(fontSize: 11.5, color: HomeTokens.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAddBatch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: HomeTokens.primary,
                borderRadius: BorderRadius.circular(HomeTokens.smallRadius),
              ),
              child: const Text(
                'Add Batch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeRingPainter extends CustomPainter {
  const _AgeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressGradient,
  });

  final double progress;
  final Color trackColor;
  final LinearGradient progressGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..shader = progressGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AgeRingPainter old) => old.progress != progress;
}
