import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key, required this.farmId, this.shedId, this.farmName});
  final String farmId;
  final String? shedId;
  final String? farmName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchListProvider(farmId));

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (batches) {
          if (batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.black26),
                  const SizedBox(height: 16),
                  const Text('No batches yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create a placement batch to track your flock.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Batch'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(batch.batchName),
                  subtitle: Text('${batch.totalBirds} birds • ${batch.status}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BatchFormScreen(farmId: farmId),
    ));
  }
}
