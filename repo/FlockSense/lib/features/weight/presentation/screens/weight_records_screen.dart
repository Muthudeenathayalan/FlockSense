import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/weight/data/weight_record_service.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';
import 'package:flock_sense/features/weight/presentation/screens/weight_record_form_screen.dart';

class WeightRecordsScreen extends StatefulWidget {
  const WeightRecordsScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });

  final String farmId;
  final String batchId;
  final String batchName;

  @override
  State<WeightRecordsScreen> createState() => _WeightRecordsScreenState();
}

class _WeightRecordsScreenState extends State<WeightRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Weight Records',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WeightRecordFormScreen(
                      farmId: widget.farmId,
                      batchId: widget.batchId,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<WeightRecordModel>>(
        stream: WeightRecordService.watchWeightRecords(
          farmId: widget.farmId,
          batchId: widget.batchId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.scale_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No weight records yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add the first weight record to track batch growth.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _WeightCard(
                record: record,
                onEdit: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeightRecordFormScreen(
                        farmId: widget.farmId,
                        batchId: widget.batchId,
                        existingRecord: record,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete record?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await WeightRecordService.deleteWeightRecord(
                        farmId: widget.farmId,
                        batchId: widget.batchId,
                        recordDate: record.recordDate,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Weight record deleted'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final WeightRecordModel record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _formattedDate {
    return '${record.recordDate.day}/${record.recordDate.month}/${record.recordDate.year}';
  }

  String get _weightDisplay {
    final weight = record.averageWeight.toStringAsFixed(1);
    final unit = record.unit == 'kilograms' ? 'kg' : 'g';
    return '$weight $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weightDisplay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (record.sampleCount != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sample count: ${record.sampleCount}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(record.notes!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
