import 'package:flutter/material.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

class DailyRecordFormScreen extends StatefulWidget {
  const DailyRecordFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
    this.existingRecord,
  });

  final String farmId;
  final String batchId;
  final String? batchName;
  final DailyRecordModel? existingRecord;

  @override
  State<DailyRecordFormScreen> createState() => _DailyRecordFormScreenState();
}

class _DailyRecordFormScreenState extends State<DailyRecordFormScreen> {
  final _pageController = PageController();
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();

  late DateTime _recordDate;
  late TextEditingController _ageController;
  late TextEditingController _openingController;
  late TextEditingController _mortalityController;
  late TextEditingController _cullController;
  late TextEditingController _adjustmentController;
  late TextEditingController _closingController;
  late TextEditingController _feedController;
  late TextEditingController _waterController;
  late TextEditingController _weightController;
  late TextEditingController _medicineNameController;
  late TextEditingController _vaccineNameController;
  late TextEditingController _symptomsController;
  late TextEditingController _notesController;

  bool _medicineGiven = false;
  bool _vaccineGiven = false;
  bool _saving = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _recordDate = record?.recordDate ?? DateTime.now();
    _ageController = TextEditingController(
      text: (record?.batchAgeDay ?? 0).toString(),
    );
    _openingController = TextEditingController(
      text: (record?.openingBirds ?? 0).toString(),
    );
    _mortalityController = TextEditingController(
      text: (record?.mortalityCount ?? 0).toString(),
    );
    _cullController = TextEditingController(
      text: (record?.cullCount ?? 0).toString(),
    );
    _adjustmentController = TextEditingController(
      text: (record?.adjustmentCount ?? 0).toString(),
    );
    _closingController = TextEditingController(
      text: (record?.closingBirds ?? 0).toString(),
    );
    _feedController = TextEditingController(
      text: _formatOptionalNumber(record?.feedConsumedKg),
    );
    _waterController = TextEditingController(
      text: _formatOptionalNumber(record?.waterConsumedLiters),
    );
    _weightController = TextEditingController(
      text: _formatOptionalNumber(record?.avgWeightGrams),
    );
    _medicineGiven = record?.medicineGiven ?? false;
    _vaccineGiven = record?.vaccineGiven ?? false;
    _medicineNameController = TextEditingController(
      text: record?.medicineName ?? '',
    );
    _vaccineNameController = TextEditingController(
      text: record?.vaccineName ?? '',
    );
    _symptomsController = TextEditingController(text: record?.symptoms ?? '');
    _notesController = TextEditingController(text: record?.notes ?? '');

    _syncClosing();
    if (record == null) {
      _loadDefaults();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _openingController.dispose();
    _mortalityController.dispose();
    _cullController.dispose();
    _adjustmentController.dispose();
    _closingController.dispose();
    _feedController.dispose();
    _waterController.dispose();
    _weightController.dispose();
    _medicineNameController.dispose();
    _vaccineNameController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final batch = await BatchService.getBatchById(
      widget.farmId,
      widget.batchId,
    );
    if (!mounted || batch == null) return;

    final age = _recordDate.difference(batch.placementDate).inDays + 1;
    final priorRecord = await DailyRecordService.getLatestRecordBeforeDate(
      farmId: widget.farmId,
      batchId: widget.batchId,
      beforeDate: _recordDate,
    );
    final opening =
        priorRecord?.closingBirds ??
        (batch.currentBirds > 0 ? batch.currentBirds : batch.totalBirds);

    setState(() {
      _ageController.text = age < 0 ? '0' : age.toString();
      _openingController.text = opening.toString();
      _mortalityController.text = '';
      _cullController.text = '';
      _feedController.text = '';
      _waterController.text = '';
      _weightController.text = '';
      _syncClosing();
    });
  }

  void _syncClosing() {
    final opening = int.tryParse(_openingController.text.trim()) ?? 0;
    final mortality = int.tryParse(_mortalityController.text.trim()) ?? 0;
    final cull = int.tryParse(_cullController.text.trim()) ?? 0;
    final adjustment = int.tryParse(_adjustmentController.text.trim()) ?? 0;
    final closing = opening - mortality - cull + adjustment;
    _closingController.text = closing < 0 ? '0' : closing.toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _recordDate = picked);
    if (widget.existingRecord == null) {
      await _loadDefaults();
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    final opening = int.tryParse(_openingController.text.trim()) ?? 0;
    final mortality = int.tryParse(_mortalityController.text.trim()) ?? 0;
    final cull = int.tryParse(_cullController.text.trim()) ?? 0;
    final adjustment = int.tryParse(_adjustmentController.text.trim()) ?? 0;
    if ((opening - mortality - cull + adjustment) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Closing birds cannot be negative.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DailyRecordService.createOrUpdateDailyRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordDate: _recordDate,
        batchAgeDay: int.tryParse(_ageController.text.trim()) ?? 0,
        openingBirds: opening,
        mortalityCount: mortality,
        cullCount: cull,
        adjustmentCount: adjustment,
        feedConsumedKg: double.tryParse(_feedController.text.trim()) ?? 0,
        waterConsumedLiters: double.tryParse(_waterController.text.trim()) ?? 0,
        avgWeightGrams: double.tryParse(_weightController.text.trim()) ?? 0,
        medicineGiven: _medicineGiven,
        medicineName: _medicineNameController.text.trim(),
        vaccineGiven: _vaccineGiven,
        vaccineName: _vaccineNameController.text.trim(),
        symptoms: _symptomsController.text.trim(),
        notes: _notesController.text.trim(),
      );

      final isEditingOlderRecord =
          widget.existingRecord != null && _recordDate.isBefore(DateTime.now());
      if (isEditingOlderRecord) {
        await DailyRecordService.recalculateRecordsAfterDate(
          farmId: widget.farmId,
          batchId: widget.batchId,
          editedDate: _recordDate,
        );
      }

      await NotificationService.checkMortalityAlert(
        batchName: widget.batchName ?? 'Batch',
        mortalityCount: mortality,
        totalBirds: opening,
        batchAgeDay: int.tryParse(_ageController.text.trim()) ?? 0,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save record: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == 0) {
      final valid = _stepOneKey.currentState?.validate() ?? false;
      if (!valid) return;
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    final twoValid = _stepTwoKey.currentState?.validate() ?? false;
    if (!twoValid) return;

    _save();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _formatOptionalNumber(double? v) {
    if (v == null) return '';
    if (v == 0) return '';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Record')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Daily record form placeholder'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _next,
                child: const Text('Next / Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
