import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/widgets/sync_status_banner.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sheds/presentation/providers/shed_providers.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';
import 'package:flock_sense/core/models/sync_status.dart';

class ShedListScreen extends ConsumerWidget {
  const ShedListScreen({super.key, required this.farm});
  final FarmModel farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shedsAsync = ref.watch(shedListProvider(farm.id));
    final syncStatus = ref.watch(shedSyncStatusProvider(farm.id)).maybeWhen(
      data: (s) => s,
      orElse: () => SyncStatus.synced,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Sheds — ${farm.farmName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add shed',
            onPressed: () => _openForm(context, farm.id),
          ),
        ],
      ),
      body: Column(
        children: [
          SyncStatusBanner(syncStatus: syncStatus),
          Expanded(
            child: shedsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sheds) {
                if (sheds.isEmpty) {
                  return _EmptyShedsState(onAdd: () => _openForm(context, farm.id));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sheds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ShedCard(
                    shed: sheds[i],
                    farmId: farm.id,
                    onEdit: () => _openForm(context, farm.id, shed: sheds[i]),
                    onDelete: () => _delete(context, farm.id, sheds[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, farm.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Shed'),
      ),
    );
  }

  void _openForm(BuildContext ctx, String farmId, {ShedModel? shed}) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => ShedFormScreen(farmId: farmId, existing: shed),
    ));
  }

  Future<void> _delete(BuildContext ctx, String farmId, ShedModel shed) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Shed'),
        content: Text('Delete "${shed.shedName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      try {
        await ShedService.deleteShed(farmId, shed.id);
      } catch (e) {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

class _ShedCard extends StatelessWidget {
  const _ShedCard({required this.shed, required this.farmId, required this.onEdit, required this.onDelete});
  final ShedModel shed;
  final String farmId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = shed.status == 'active' ? Colors.green : Colors.orange;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.home_work_outlined, color: statusColor),
        ),
        title: Text(shed.shedName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Capacity: ${shed.physicalCapacity}  •  Area: ${shed.areaSqFt.toStringAsFixed(0)} ft²',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

class _EmptyShedsState extends StatelessWidget {
  const _EmptyShedsState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_outlined, size: 72, color: Colors.black26),
          const SizedBox(height: 16),
          Text('No sheds yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Add a shed to start tracking batches inside this farm.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Shed')),
        ],
      ),
    );
  }
}
