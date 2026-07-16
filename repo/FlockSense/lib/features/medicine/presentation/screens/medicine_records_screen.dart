import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_form_screen.dart';

class MedicineRecordsScreen extends StatefulWidget {
  const MedicineRecordsScreen({
    super.key,
    this.farmId,
    this.batchId,
    this.batchName,
  });

  final String? farmId;
  final String? batchId;
  final String? batchName;

  @override
  State<MedicineRecordsScreen> createState() => _MedicineRecordsScreenState();
}

class _MedicineRecordsScreenState extends State<MedicineRecordsScreen> {
  bool get _hasContext =>
      (widget.farmId?.isNotEmpty ?? false) &&
      (widget.batchId?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (!_hasContext) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.batchName == null
                ? 'Medicine'
                : 'Medicine • ${widget.batchName}',
          ),
        ),
        body: const Center(
          child: Text('Open medicine from a batch to log treatments.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.batchName == null
              ? 'Medicine'
              : 'Medicine • ${widget.batchName}',
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<MedicineRecordModel>>(
        stream: MedicineService.watchMedicineRecords(
          widget.farmId!,
          widget.batchId!,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          final records = snapshot.data ?? <MedicineRecordModel>[];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.dangerLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        size: 36,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No medicine records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record the first treatment for this batch',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final record = records[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.dangerGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.medicineName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(record.date)} · Day ${record.batchAgeDay} · ${record.quantity.toStringAsFixed(1)} ${record.unit}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      record.route ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineFormScreen(
              farmId: widget.farmId!,
              batchId: widget.batchId!,
              currentBatchAge: 0,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
