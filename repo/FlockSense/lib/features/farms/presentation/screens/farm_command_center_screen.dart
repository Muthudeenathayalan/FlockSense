import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

class FarmCommandCenterScreen extends StatefulWidget {
  const FarmCommandCenterScreen({super.key, required this.farm});

  final FarmModel farm;

  @override
  State<FarmCommandCenterScreen> createState() =>
      _FarmCommandCenterScreenState();
}

class _FarmCommandCenterScreenState extends State<FarmCommandCenterScreen> {
  late FarmModel _farm;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<FarmModel?>(
      MaterialPageRoute(builder: (_) => FarmSetupScreen(initialFarm: _farm)),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _farm = result);
      return;
    }
    final latest = await FarmService.getFarmById(_farm.id);
    if (!mounted || latest == null) return;
    setState(() => _farm = latest);
  }

  Future<void> _deleteFarm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete farm?'),
        content: const Text(
          'This permanently removes the farm and all linked data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FarmService.deleteFarm(_farm.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete farm: $e')));
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => _updatingStatus = true);
    try {
      await FarmService.setFarmStatus(farmId: _farm.id, isActive: value);
      if (!mounted) return;
      setState(
        () => _farm = _farm.copyWith(status: value ? 'active' : 'inactive'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status update failed: $e')));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _openBatchCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BatchFormScreen(farmId: _farm.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmType = FarmService.getFormattedFarmType(_farm.farmType);
    final location = [
      _farm.areaName,
      _farm.district,
      _farm.state,
      _farm.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_farm.farmName),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit farm',
          ),
          IconButton(
            onPressed: _deleteFarm,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete farm',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBatchCreate,
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _farm.farmName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _farm.isActive
                              ? AppColors.primaryLight
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(
                          _farm.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _farm.isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(label: 'Farm type', value: farmType),
                  _DetailRow(
                    label: 'Size',
                    value:
                        '${_farm.lengthFt.toStringAsFixed(1)} ft x ${_farm.widthFt.toStringAsFixed(1)} ft',
                  ),
                  _DetailRow(
                    label: 'Area',
                    value: '${_farm.totalSqFt.toStringAsFixed(1)} ft\u00b2',
                  ),
                  if (location.isNotEmpty)
                    _DetailRow(label: 'Location', value: location),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _farm.isActive,
                    onChanged: _updatingStatus ? null : _toggleStatus,
                    title: const Text('Farm active'),
                    subtitle: const Text(
                      'Inactive farms are hidden from quick actions.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Batches', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          StreamBuilder<List<BatchModel>>(
            stream: BatchService.watchBatches(_farm.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final batches = snapshot.data ?? const <BatchModel>[];
              if (batches.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No batches yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a batch to start daily records and tracking.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _openBatchCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Batch'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: batches.map((batch) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(batch.batchName),
                      subtitle: Text(
                        '${batch.totalBirds} birds • ${batch.breedOrFlockType} • ${batch.status}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BatchCommandCenterScreen(
                              farmId: _farm.id,
                              batchId: batch.id,
                              batchName: batch.batchName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
