import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

enum RecordFormType {
  feed('Feed Record', Icons.restaurant_rounded),
  water('Water Record', Icons.water_drop_rounded),
  mortality('Mortality Record', Icons.sick_rounded),
  weight('Weight Record', Icons.monitor_weight_rounded),
  medicine('Medicine Record', Icons.medication_rounded),
  vaccination('Vaccination Record', Icons.vaccines_rounded),
  environment('Environment Record', Icons.thermostat_rounded);

  const RecordFormType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class DailyRecordTypeFormDialog extends StatefulWidget {
  const DailyRecordTypeFormDialog({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.initialType,
    this.existingRecord,
    this.currentBirds = 1000,
  });

  final String farmId;
  final String batchId;
  final RecordFormType initialType;
  final DailyRecordModel? existingRecord;
  final int currentBirds;

  @override
  State<DailyRecordTypeFormDialog> createState() => _DailyRecordTypeFormDialogState();
}

class _DailyRecordTypeFormDialogState extends State<DailyRecordTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late RecordFormType _selectedType;
  late DateTime _selectedDate;
  bool _isSaving = false;

  // Controllers
  final _notesController = TextEditingController();

  // Feed
  final _feedTypeController = TextEditingController();
  final _feedQtyController = TextEditingController();
  final _feedCostController = TextEditingController();
  final _feedSupplierController = TextEditingController();

  // Water
  final _waterQtyController = TextEditingController();
  final _waterSourceController = TextEditingController();
  final _waterQualityController = TextEditingController();

  // Mortality
  final _deadBirdsController = TextEditingController();
  final _mortalityCauseController = TextEditingController();
  final _mortalityDiseaseController = TextEditingController();
  final _mortalityRemarksController = TextEditingController();

  // Weight
  final _avgWeightController = TextEditingController();
  final _sampleBirdsController = TextEditingController();

  // Medicine
  final _medicineNameController = TextEditingController();
  final _medicineDoseController = TextEditingController();
  final _medicineQtyController = TextEditingController();
  final _medicineCostController = TextEditingController();
  final _medicineReasonController = TextEditingController();

  // Vaccine
  final _vaccineNameController = TextEditingController();
  final _vaccineDoseController = TextEditingController();
  final _vaccineCompletedByController = TextEditingController();
  DateTime? _vaccineNextDueDate;

  // Environment
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _weatherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    final r = widget.existingRecord;
    _selectedDate = r?.recordDate ?? DateTime.now();

    if (r != null) {
      _notesController.text = r.notes ?? '';

      // Feed
      _feedTypeController.text = r.feedType ?? '';
      _feedQtyController.text = r.feedConsumedKg > 0 ? r.feedConsumedKg.toString() : '';
      _feedCostController.text = r.feedCost != null ? r.feedCost.toString() : '';
      _feedSupplierController.text = r.feedSupplier ?? '';

      // Water
      _waterQtyController.text =
          r.waterConsumedLiters > 0 ? r.waterConsumedLiters.toString() : '';
      _waterSourceController.text = r.waterSource ?? '';
      _waterQualityController.text = r.waterQuality ?? '';

      // Mortality
      _deadBirdsController.text =
          r.mortalityCount > 0 ? r.mortalityCount.toString() : '';
      _mortalityCauseController.text = r.mortalityCause ?? '';
      _mortalityDiseaseController.text = r.mortalityDisease ?? '';
      _mortalityRemarksController.text = r.mortalityRemarks ?? '';

      // Weight
      _avgWeightController.text =
          r.avgWeightGrams > 0 ? r.avgWeightGrams.toString() : '';
      _sampleBirdsController.text =
          r.sampleBirds != null ? r.sampleBirds.toString() : '';

      // Medicine
      _medicineNameController.text = r.medicineName ?? '';
      _medicineDoseController.text = r.medicineDose ?? '';
      _medicineQtyController.text =
          r.medicineQuantity != null ? r.medicineQuantity.toString() : '';
      _medicineCostController.text =
          r.medicineCost != null ? r.medicineCost.toString() : '';
      _medicineReasonController.text = r.medicineReason ?? '';

      // Vaccine
      _vaccineNameController.text = r.vaccineName ?? '';
      _vaccineDoseController.text = r.vaccineDose ?? '';
      _vaccineCompletedByController.text = r.vaccineCompletedBy ?? '';
      _vaccineNextDueDate = r.vaccineNextDueDate;

      // Environment
      _temperatureController.text =
          r.temperature != null ? r.temperature.toString() : '';
      _humidityController.text =
          r.humidity != null ? r.humidity.toString() : '';
      _weatherController.text = r.weather ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _feedTypeController.dispose();
    _feedQtyController.dispose();
    _feedCostController.dispose();
    _feedSupplierController.dispose();
    _waterQtyController.dispose();
    _waterSourceController.dispose();
    _waterQualityController.dispose();
    _deadBirdsController.dispose();
    _mortalityCauseController.dispose();
    _mortalityDiseaseController.dispose();
    _mortalityRemarksController.dispose();
    _avgWeightController.dispose();
    _sampleBirdsController.dispose();
    _medicineNameController.dispose();
    _medicineDoseController.dispose();
    _medicineQtyController.dispose();
    _medicineCostController.dispose();
    _medicineReasonController.dispose();
    _vaccineNameController.dispose();
    _vaccineDoseController.dispose();
    _vaccineCompletedByController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isNextDueDate) async {
    final initial = isNextDueDate
        ? (_vaccineNextDueDate ?? DateTime.now().add(const Duration(days: 7)))
        : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isNextDueDate) {
          _vaccineNextDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final existing = widget.existingRecord;
      final opening = existing?.openingBirds ?? widget.currentBirds;
      final currentMortality =
          int.tryParse(_deadBirdsController.text.trim()) ?? existing?.mortalityCount ?? 0;
      final currentFeed =
          double.tryParse(_feedQtyController.text.trim()) ?? existing?.feedConsumedKg ?? 0.0;
      final currentWater =
          double.tryParse(_waterQtyController.text.trim()) ?? existing?.waterConsumedLiters ?? 0.0;
      final currentWeight =
          double.tryParse(_avgWeightController.text.trim()) ?? existing?.avgWeightGrams ?? 0.0;

      final medName = _medicineNameController.text.trim();
      final hasMed = medName.isNotEmpty || (existing?.medicineGiven ?? false);

      final vacName = _vaccineNameController.text.trim();
      final hasVac = vacName.isNotEmpty || (existing?.vaccineGiven ?? false);

      await DailyRecordService.createOrUpdateDailyRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordDate: _selectedDate,
        batchAgeDay: existing?.batchAgeDay ?? 1,
        openingBirds: opening,
        mortalityCount: currentMortality,
        cullCount: existing?.cullCount ?? 0,
        adjustmentCount: existing?.adjustmentCount ?? 0,
        feedConsumedKg: currentFeed,
        waterConsumedLiters: currentWater,
        avgWeightGrams: currentWeight,
        medicineGiven: hasMed,
        medicineName: medName.isNotEmpty ? medName : existing?.medicineName,
        vaccineGiven: hasVac,
        vaccineName: vacName.isNotEmpty ? vacName : existing?.vaccineName,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : existing?.notes,
        // Sub-fields
        feedType: _feedTypeController.text.trim().isNotEmpty
            ? _feedTypeController.text.trim()
            : existing?.feedType,
        feedCost: double.tryParse(_feedCostController.text.trim()) ?? existing?.feedCost,
        feedSupplier: _feedSupplierController.text.trim().isNotEmpty
            ? _feedSupplierController.text.trim()
            : existing?.feedSupplier,
        waterSource: _waterSourceController.text.trim().isNotEmpty
            ? _waterSourceController.text.trim()
            : existing?.waterSource,
        waterQuality: _waterQualityController.text.trim().isNotEmpty
            ? _waterQualityController.text.trim()
            : existing?.waterQuality,
        mortalityCause: _mortalityCauseController.text.trim().isNotEmpty
            ? _mortalityCauseController.text.trim()
            : existing?.mortalityCause,
        mortalityDisease: _mortalityDiseaseController.text.trim().isNotEmpty
            ? _mortalityDiseaseController.text.trim()
            : existing?.mortalityDisease,
        mortalityRemarks: _mortalityRemarksController.text.trim().isNotEmpty
            ? _mortalityRemarksController.text.trim()
            : existing?.mortalityRemarks,
        sampleBirds: int.tryParse(_sampleBirdsController.text.trim()) ?? existing?.sampleBirds,
        medicineDose: _medicineDoseController.text.trim().isNotEmpty
            ? _medicineDoseController.text.trim()
            : existing?.medicineDose,
        medicineQuantity:
            double.tryParse(_medicineQtyController.text.trim()) ?? existing?.medicineQuantity,
        medicineCost:
            double.tryParse(_medicineCostController.text.trim()) ?? existing?.medicineCost,
        medicineReason: _medicineReasonController.text.trim().isNotEmpty
            ? _medicineReasonController.text.trim()
            : existing?.medicineReason,
        vaccineDose: _vaccineDoseController.text.trim().isNotEmpty
            ? _vaccineDoseController.text.trim()
            : existing?.vaccineDose,
        vaccineCompletedBy: _vaccineCompletedByController.text.trim().isNotEmpty
            ? _vaccineCompletedByController.text.trim()
            : existing?.vaccineCompletedBy,
        vaccineNextDueDate: _vaccineNextDueDate ?? existing?.vaccineNextDueDate,
        temperature:
            double.tryParse(_temperatureController.text.trim()) ?? existing?.temperature,
        humidity: double.tryParse(_humidityController.text.trim()) ?? existing?.humidity,
        weather: _weatherController.text.trim().isNotEmpty
            ? _weatherController.text.trim()
            : existing?.weather,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.label} saved successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: ${e.toString().replaceAll('Exception:', '')}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existingRecord == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record from Firestore?'),
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
    setState(() => _isSaving = true);
    try {
      await DailyRecordService.deleteDailyRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordId: widget.existingRecord!.id,
        recordDate: widget.existingRecord!.recordDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record deleted successfully.'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(_selectedType.icon, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingRecord != null
                          ? 'Edit ${_selectedType.label}'
                          : 'New ${_selectedType.label}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Record Type Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: RecordFormType.values.map((type) {
                            final isSelected = type == _selectedType;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type.icon,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(type.label.replaceAll(' Record', '')),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedType = type);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Field
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Record Date',
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Specialized Type Form Fields
                      ..._buildTypeFields(),

                      const SizedBox(height: 16),
                      // General Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes & Observations',
                          prefixIcon: const Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.existingRecord != null)
                    IconButton.outlined(
                      style: IconButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: _isSaving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(widget.existingRecord != null ? 'Update Record' : 'Save Record'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeFields() {
    switch (_selectedType) {
      case RecordFormType.feed:
        return [
          TextFormField(
            controller: _feedTypeController,
            decoration: InputDecoration(
              labelText: 'Feed Type (e.g., Starter, Finisher, Layer Mash)',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter feed type' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _feedQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity (kg)',
                    prefixIcon: const Icon(Icons.scale_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val < 0) return 'Invalid kg';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _feedCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cost',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid cost';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _feedSupplierController,
            decoration: InputDecoration(
              labelText: 'Feed Supplier / Brand',
              prefixIcon: const Icon(Icons.local_shipping_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ];

      case RecordFormType.water:
        return [
          TextFormField(
            controller: _waterQtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Water Quantity (Liters)',
              prefixIcon: const Icon(Icons.water_drop_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final val = double.tryParse(v);
              if (val == null || val < 0) return 'Invalid quantity';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _waterSourceController,
                  decoration: InputDecoration(
                    labelText: 'Water Source (e.g., Borewell, Tank)',
                    prefixIcon: const Icon(Icons.source_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _waterQualityController,
                  decoration: InputDecoration(
                    labelText: 'Quality (e.g., Chlorinated, Good)',
                    prefixIcon: const Icon(Icons.verified_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ];

      case RecordFormType.mortality:
        return [
          TextFormField(
            controller: _deadBirdsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Dead Birds Count',
              prefixIcon: const Icon(Icons.sick_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final val = int.tryParse(v);
              if (val == null || val < 0) return 'Invalid count';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mortalityCauseController,
                  decoration: InputDecoration(
                    labelText: 'Suspected Cause',
                    prefixIcon: const Icon(Icons.help_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mortalityDiseaseController,
                  decoration: InputDecoration(
                    labelText: 'Disease (if any)',
                    prefixIcon: const Icon(Icons.coronavirus_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _mortalityRemarksController,
            decoration: InputDecoration(
              labelText: 'Remarks & Autopsy Observations',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ];

      case RecordFormType.weight:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _avgWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Average Weight (grams)',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sampleBirdsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sample Birds Weighed',
                    prefixIcon: const Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ];

      case RecordFormType.medicine:
        return [
          TextFormField(
            controller: _medicineNameController,
            decoration: InputDecoration(
              labelText: 'Medicine Name',
              prefixIcon: const Icon(Icons.medication_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter medicine name' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _medicineDoseController,
                  decoration: InputDecoration(
                    labelText: 'Dose (e.g., 2 ml/L)',
                    prefixIcon: const Icon(Icons.science_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicineQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity Used',
                    prefixIcon: const Icon(Icons.numbers_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _medicineCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cost',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _medicineReasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Meds',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ];

      case RecordFormType.vaccination:
        return [
          TextFormField(
            controller: _vaccineNameController,
            decoration: InputDecoration(
              labelText: 'Vaccine Name',
              prefixIcon: const Icon(Icons.vaccines_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter vaccine name' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vaccineDoseController,
                  decoration: InputDecoration(
                    labelText: 'Dose (e.g., 1 drop/bird)',
                    prefixIcon: const Icon(Icons.opacity_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _vaccineCompletedByController,
                  decoration: InputDecoration(
                    labelText: 'Administered By',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _selectDate(context, true),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Next Vaccination Due Date',
                prefixIcon: const Icon(Icons.event_available_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _vaccineNextDueDate != null
                    ? '${_vaccineNextDueDate!.year}-${_vaccineNextDueDate!.month.toString().padLeft(2, '0')}-${_vaccineNextDueDate!.day.toString().padLeft(2, '0')}'
                    : 'Select Next Due Date (Optional)',
                style: TextStyle(
                  fontWeight:
                      _vaccineNextDueDate != null ? FontWeight.bold : FontWeight.normal,
                  color: _vaccineNextDueDate != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ];

      case RecordFormType.environment:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _temperatureController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Temperature (°C)',
                    prefixIcon: const Icon(Icons.thermostat_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final val = double.tryParse(v);
                      if (val == null) return 'Invalid °C';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _humidityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Humidity (%)',
                    prefixIcon: const Icon(Icons.water_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) return '0 - 100%';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _weatherController,
            decoration: InputDecoration(
              labelText: 'Weather (e.g., Sunny, Rainy, Humid)',
              prefixIcon: const Icon(Icons.wb_sunny_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ];
    }
  }
}
