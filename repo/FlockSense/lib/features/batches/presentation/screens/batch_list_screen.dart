import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({
    super.key,
    required this.farmId,
    this.farmName,
    this.shedId,
  });
  final String farmId;
  final String? farmName;
  final String? shedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchListProvider(farmId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          farmName != null ? '$farmName — Batches' : 'Batches',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: batchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (batches) {
          if (batches.isEmpty)
            return _EmptyState(onAdd: () => _openForm(context));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BatchCard(
              batch: batches[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchCommandCenterScreen(
                    farmId: farmId,
                    batchId: batches[i].id,
                    batchName: batches[i].batchName,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Batch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openForm(BuildContext ctx) => Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => BatchFormScreen(farmId: farmId, shedId: shedId),
    ),
  );
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch, required this.onTap});
  final BatchModel batch;
  final VoidCallback onTap;

  int get _age => DateTime.now().difference(batch.placementDate).inDays;
  bool get _isActive => batch.status == 'active';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                gradient: _isActive
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFF607D8B), Color(0xFF78909C)],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.egg_alt_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.batchName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Placed ${batch.placementDate.day}/${batch.placementDate.month}/${batch.placementDate.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Pill(
                    'Day $_age',
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _Stat(
                    '${batch.currentBirds}',
                    'Live Birds',
                    Icons.pets,
                    AppColors.primary,
                  ),
                  _vDivider(),
                  _Stat(
                    batch.breedOrFlockType,
                    'Breed',
                    Icons.egg_outlined,
                    AppColors.gold,
                  ),
                  _vDivider(),
                  _Stat(
                    '${batch.maleCount}M / ${batch.femaleCount}F',
                    'Split',
                    Icons.people_outline,
                    AppColors.ocean,
                  ),
                  _vDivider(),
                  _Pill(
                    _isActive ? 'Active' : 'Closed',
                    _isActive ? AppColors.emeraldLight : AppColors.surfaceSoft,
                    _isActive ? AppColors.emerald : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 0.5,
    height: 36,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon, this.color);
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);
  final String text;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No batches yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Place your first batch to begin tracking.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Place Batch'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    ),
  );
}
