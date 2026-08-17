import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/presentation/widgets/daily_record_type_form_dialog.dart';

class DailyRecordDetailDialog extends StatefulWidget {
  const DailyRecordDetailDialog({
    super.key,
    required this.record,
    required this.farmId,
    required this.batchId,
  });

  final DailyRecordModel record;
  final String farmId;
  final String batchId;

  @override
  State<DailyRecordDetailDialog> createState() => _DailyRecordDetailDialogState();
}

class _DailyRecordDetailDialogState extends State<DailyRecordDetailDialog> {
  bool _isDeleting = false;

  Future<void> _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete the daily record for ${_formatDate(widget.record.recordDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      await DailyRecordService.deleteDailyRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordId: widget.record.id,
        recordDate: widget.record.recordDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily record deleted successfully.'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _editRecord() async {
    Navigator.pop(context);
    await showDialog(
      context: context,
      builder: (_) => DailyRecordTypeFormDialog(
        farmId: widget.farmId,
        batchId: widget.batchId,
        initialType: RecordFormType.feed,
        existingRecord: widget.record,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final dateStr = _formatDate(r.recordDate);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Details ($dateStr)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Day ${r.batchAgeDay} • ${r.closingBirds} Birds Remaining',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Flock Summary', Icons.groups_rounded),
                    _buildInfoGrid([
                      _InfoItem('Opening Birds', '${r.openingBirds}'),
                      _InfoItem('Mortality Count', '${r.mortalityCount}'),
                      _InfoItem('Cull Count', '${r.cullCount}'),
                      _InfoItem('Closing Birds', '${r.closingBirds}'),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Feed & Water', Icons.restaurant_rounded),
                    _buildInfoGrid([
                      _InfoItem('Feed Quantity', '${r.feedConsumedKg.toStringAsFixed(1)} kg'),
                      _InfoItem('Feed Type', r.feedType ?? 'Standard'),
                      _InfoItem('Feed Cost', r.feedCost != null ? '₹${r.feedCost}' : 'N/A'),
                      _InfoItem('Water Consumed', '${r.waterConsumedLiters.toStringAsFixed(1)} L'),
                      _InfoItem('Water Source', r.waterSource ?? 'N/A'),
                      _InfoItem('Water Quality', r.waterQuality ?? 'N/A'),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Weight & Growth', Icons.monitor_weight_rounded),
                    _buildInfoGrid([
                      _InfoItem('Average Weight', '${r.avgWeightGrams.toStringAsFixed(0)} g'),
                      _InfoItem('Sample Size', r.sampleBirds != null ? '${r.sampleBirds} birds' : 'N/A'),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Health & Vaccination', Icons.medical_services_rounded),
                    _buildInfoGrid([
                      _InfoItem('Medicine Given', r.medicineGiven ? (r.medicineName ?? 'Yes') : 'No'),
                      _InfoItem('Medicine Dose', r.medicineDose ?? 'N/A'),
                      _InfoItem('Vaccine Administered', r.vaccineGiven ? (r.vaccineName ?? 'Yes') : 'None'),
                      _InfoItem('Vaccine Administered By', r.vaccineCompletedBy ?? 'N/A'),
                      _InfoItem(
                        'Next Vaccine Due',
                        r.vaccineNextDueDate != null ? _formatDate(r.vaccineNextDueDate!) : 'N/A',
                      ),
                    ]),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Environment', Icons.thermostat_rounded),
                    _buildInfoGrid([
                      _InfoItem('Temperature', r.temperature != null ? '${r.temperature} °C' : 'N/A'),
                      _InfoItem('Humidity', r.humidity != null ? '${r.humidity} %' : 'N/A'),
                      _InfoItem('Weather', r.weather ?? 'N/A'),
                    ]),
                    if (r.notes != null && r.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionHeader('Notes & Observations', Icons.notes_rounded),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          r.notes!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton.outlined(
                    style: IconButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: _isDeleting ? null : _deleteRecord,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _editRecord,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Record'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
