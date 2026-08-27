import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/sync_status_banner.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sheds/presentation/providers/shed_providers.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';

class ShedListScreen extends ConsumerWidget {
  const ShedListScreen({super.key, required this.farm});
  final FarmModel farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shedsAsync = ref.watch(shedListProvider(farm.id));
    final syncStatus = ref
        .watch(shedSyncStatusProvider(farm.id))
        .maybeWhen(data: (s) => s, orElse: () => SyncStatus.synced);

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
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load sheds',
                message: '$e',
                buttonLabel: 'Retry',
                onButtonPressed: () =>
                    ref.invalidate(shedListProvider(farm.id)),
              ),
              data: (sheds) {
                if (sheds.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.home_work_outlined,
                    title: 'No sheds yet',
                    message:
                        'Add a shed to start tracking batches inside this farm.',
                    buttonLabel: 'Add Shed',
                    onButtonPressed: () => _openForm(context, farm.id),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sheds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => ShedFormScreen(farmId: farmId, existing: shed),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, String farmId, ShedModel shed) async {
    final ok = await AppDialog.confirm(
      context: ctx,
      title: 'Delete Shed',
      message: 'Delete "${shed.shedName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (ok && ctx.mounted) {
      try {
        await ShedService.deleteShed(farmId, shed.id);
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _ShedCard extends StatelessWidget {
  const _ShedCard({
    required this.shed,
    required this.farmId,
    required this.onEdit,
    required this.onDelete,
  });
  final ShedModel shed;
  final String farmId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = shed.status == 'active'
        ? AppColors.emerald
        : AppColors.warning;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.home_work_outlined, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shed.shedName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacity: ${shed.physicalCapacity}  •  Area: ${shed.areaSqFt.toStringAsFixed(0)} ft²',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
