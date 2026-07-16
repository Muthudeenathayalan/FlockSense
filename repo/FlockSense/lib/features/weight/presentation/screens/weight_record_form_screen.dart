import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/weight/data/weight_record_service.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';

class WeightRecordFormScreen extends StatefulWidget {
  const WeightRecordFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.existingRecord,
  });

  final String farmId;
  final String batchId;
  final WeightRecordModel? existingRecord;

  @override
  State<WeightRecordFormScreen> createState() => _WeightRecordFormScreenState();
}

class _WeightRecordFormScreenState extends State<WeightRecordFormScreen> {
  late DateTime _recordDate;
  late TextEditingController _weightController;
  late TextEditingController _sampleCountController;
  late TextEditingController _notesController;
  late String _selectedUnit;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _recordDate = record?.recordDate ?? DateTime.now();
    _selectedUnit = record?.unit ?? 'grams';
    _weightController = TextEditingController(
      text: record?.averageWeight.toString() ?? '',
    );
    _sampleCountController = TextEditingController(
      text: record?.sampleCount?.toString() ?? '',
    );
    _notesController = TextEditingController(text: record?.notes ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sampleCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _recordDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final weight = double.parse(_weightController.text.trim());
      final sampleCount = _sampleCountController.text.trim().isEmpty
          ? null
          : int.parse(_sampleCountController.text.trim());

      await WeightRecordService.createOrUpdateWeightRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordDate: _recordDate,
        averageWeight: weight,
        unit: _selectedUnit,
        sampleCount: sampleCount,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save weight record: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.existingRecord == null ? 'Add Weight' : 'Edit Weight',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Record date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_recordDate.day}/${_recordDate.month}/${_recordDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Average weight',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., 1250.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Weight is required';
                  }
                  final weight = double.tryParse(value.trim());
                  if (weight == null || weight <= 0) {
                    return 'Weight must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(label: Text('Grams'), value: 'grams'),
                  ButtonSegment(label: Text('Kilograms'), value: 'kilograms'),
                ],
                selected: {_selectedUnit},
                onSelectionChanged: (value) {
                  setState(() => _selectedUnit = value.first);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Sample count (optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sampleCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 50',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final count = int.tryParse(value.trim());
                    if (count == null || count < 0) {
                      return 'Sample count must be a non-negative number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Notes (optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any additional notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
