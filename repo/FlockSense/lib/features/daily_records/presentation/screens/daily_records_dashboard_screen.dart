import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_records_providers.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

enum LogRecordType {
  feed('Feed', '🌾', Icons.restaurant_outlined),
  water('Water', '💧', Icons.water_drop_outlined),
  mortality('Mortality', '☠️', Icons.sick_outlined),
  medicine('Medicine', '💊', Icons.medication_outlined),
  vaccine('Vaccine', '💉', Icons.vaccines_outlined),
  weight('Weight', '⚖️', Icons.monitor_weight_outlined),
  notes('Notes', '📝', Icons.notes_outlined),
  dg('DG (Generator)', '⚡', Icons.electric_bolt_outlined);

  final String title;
  final String emoji;
  final IconData icon;
  const LogRecordType(this.title, this.emoji, this.icon);
}

class DailyRecordsDashboardScreen extends ConsumerStatefulWidget {
  final String? initialFarmId;
  final String? initialBatchId;
  final DailyRecordModel? existingRecord;

  const DailyRecordsDashboardScreen({
    super.key,
    this.initialFarmId,
    this.initialBatchId,
    this.existingRecord,
  });

  @override
  ConsumerState<DailyRecordsDashboardScreen> createState() =>
      _DailyRecordsDashboardScreenState();
}

class _DailyRecordsDashboardScreenState
    extends ConsumerState<DailyRecordsDashboardScreen> {
  int _currentStep = 0;
  bool _isLoadingData = true;
  bool _isSaving = false;

  List<FarmModel> _farms = [_defaultFarm];
  List<BatchModel> _batches = [_defaultBatch];
  FarmModel? _selectedFarm = _defaultFarm;
  BatchModel? _selectedBatch = _defaultBatch;

  LogRecordType? _selectedRecordType;
  final _formKey = GlobalKey<FormState>();

  // Feed
  final _feedTypeController = TextEditingController();
  final _feedQuantityController = TextEditingController();
  final _feedCostController = TextEditingController();
  final _feedNotesController = TextEditingController();
  String _feedUnit = 'kg';

  // Water
  final _waterQuantityController = TextEditingController();
  final _waterSourceController = TextEditingController();
  final _waterNotesController = TextEditingController();

  // Mortality
  final _mortalityCountController = TextEditingController();
  final _mortalityReasonController = TextEditingController();
  final _mortalityNotesController = TextEditingController();

  // Medicine
  final _medicineNameController = TextEditingController();
  final _medicineQuantityController = TextEditingController();
  final _medicinePurposeController = TextEditingController();
  final _medicineCostController = TextEditingController();
  final _medicineNotesController = TextEditingController();

  // Vaccine
  final _vaccineNameController = TextEditingController();
  final _vaccineDoseController = TextEditingController();
  final _vaccineBatchNumController = TextEditingController();
  final _vaccineNotesController = TextEditingController();

  // Weight
  final _weightSampleCountController = TextEditingController();
  final _weightAvgGramsController = TextEditingController();
  final _weightNotesController = TextEditingController();

  // Notes
  final _notesTitleController = TextEditingController();
  final _notesDescController = TextEditingController();

  // DG (Generator)
  final _dgLevelController = TextEditingController();
  final _dgAddedController = TextEditingController();
  final _dgHoursController = TextEditingController();
  final _dgNameController = TextEditingController();
  final _dgNotesController = TextEditingController();

  static final _defaultFarm = FarmModel(
    id: 'default_farm',
    userId: 'default_user',
    farmName: 'Main FlockSense Farm',
    farmType: 'EC',
    flockType: 'Broiler',
    address: 'Namakkal, Tamil Nadu',
    lengthFt: 100,
    widthFt: 40,
    totalSqFt: 4000,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final _defaultBatch = BatchModel(
    id: 'default_batch',
    farmId: 'default_farm',
    ownerId: 'default_user',
    batchName: 'Batch B-2026-01',
    hatchDate: DateTime.now().subtract(const Duration(days: 25)),
    placementDate: DateTime.now().subtract(const Duration(days: 24)),
    maleCount: 2500,
    femaleCount: 2500,
    totalBirds: 5000,
    currentBirds: 4920,
    breedOrFlockType: 'Cobb 500',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _prefillFromExistingRecord(widget.existingRecord!);
    }
    _loadFarmsAndBatches();
  }

  void _prefillFromExistingRecord(DailyRecordModel record) {
    if (record.feedConsumedKg > 0 || record.feedType != null) {
      _selectedRecordType = LogRecordType.feed;
      _feedTypeController.text = record.feedType ?? 'Broiler Starter';
      _feedQuantityController.text =
          record.feedConsumedKg > 0 ? record.feedConsumedKg.toString() : '';
      _feedCostController.text =
          record.feedCost != null ? record.feedCost.toString() : '';
      _feedNotesController.text = record.notes ?? '';
    } else if (record.waterConsumedLiters > 0 || record.waterSource != null) {
      _selectedRecordType = LogRecordType.water;
      _waterQuantityController.text = record.waterConsumedLiters > 0
          ? record.waterConsumedLiters.toString()
          : '';
      _waterSourceController.text = record.waterSource ?? '';
      _waterNotesController.text = record.notes ?? '';
    } else if (record.mortalityCount > 0 || record.mortalityCause != null) {
      _selectedRecordType = LogRecordType.mortality;
      _mortalityCountController.text =
          record.mortalityCount > 0 ? record.mortalityCount.toString() : '';
      _mortalityReasonController.text = record.mortalityCause ?? '';
      _mortalityNotesController.text = record.notes ?? '';
    } else if (record.medicineGiven || record.medicineName != null) {
      _selectedRecordType = LogRecordType.medicine;
      _medicineNameController.text = record.medicineName ?? '';
      _medicineQuantityController.text = record.medicineQuantity != null
          ? record.medicineQuantity.toString()
          : '';
      _medicinePurposeController.text = record.medicineReason ?? '';
      _medicineCostController.text =
          record.medicineCost != null ? record.medicineCost.toString() : '';
      _medicineNotesController.text = record.notes ?? '';
    } else if (record.vaccineGiven || record.vaccineName != null) {
      _selectedRecordType = LogRecordType.vaccine;
      _vaccineNameController.text = record.vaccineName ?? '';
      _vaccineDoseController.text = record.vaccineDose ?? '';
      _vaccineBatchNumController.text = record.symptoms ?? '';
      _vaccineNotesController.text = record.notes ?? '';
    } else if (record.avgWeightGrams > 0) {
      _selectedRecordType = LogRecordType.weight;
      _weightAvgGramsController.text = record.avgWeightGrams.toString();
      _weightSampleCountController.text =
          record.sampleBirds != null ? record.sampleBirds.toString() : '';
      _weightNotesController.text = record.notes ?? '';
    } else if (record.dgLevelLiters != null || record.dgName != null) {
      _selectedRecordType = LogRecordType.dg;
      _dgLevelController.text =
          record.dgLevelLiters != null ? record.dgLevelLiters.toString() : '';
      _dgAddedController.text =
          record.dgAddedLiters != null ? record.dgAddedLiters.toString() : '';
      _dgHoursController.text = record.dgRunningHours != null
          ? record.dgRunningHours.toString()
          : '';
      _dgNameController.text = record.dgName ?? '';
      _dgNotesController.text = record.notes ?? '';
    }
    _selectedRecordType ??= LogRecordType.feed;
    _currentStep = 2;
  }

  @override
  void dispose() {
    _feedTypeController.dispose();
    _feedQuantityController.dispose();
    _feedCostController.dispose();
    _feedNotesController.dispose();
    _waterQuantityController.dispose();
    _waterSourceController.dispose();
    _waterNotesController.dispose();
    _mortalityCountController.dispose();
    _mortalityReasonController.dispose();
    _mortalityNotesController.dispose();
    _medicineNameController.dispose();
    _medicineQuantityController.dispose();
    _medicinePurposeController.dispose();
    _medicineCostController.dispose();
    _medicineNotesController.dispose();
    _vaccineNameController.dispose();
    _vaccineDoseController.dispose();
    _vaccineBatchNumController.dispose();
    _vaccineNotesController.dispose();
    _weightSampleCountController.dispose();
    _weightAvgGramsController.dispose();
    _weightNotesController.dispose();
    _notesTitleController.dispose();
    _notesDescController.dispose();
    _dgLevelController.dispose();
    _dgAddedController.dispose();
    _dgHoursController.dispose();
    _dgNameController.dispose();
    _dgNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmsAndBatches() async {
    try {
      var farms = await FarmService.getUserFarms().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [_defaultFarm],
      );
      if (farms.isEmpty) {
        farms = [_defaultFarm];
      }
      if (!mounted) return;

      final activeFarmId = widget.initialFarmId ?? ref.read(activeFarmIdProvider).asData?.value ?? farms.first.id;
      final farm = farms.firstWhere((f) => f.id == activeFarmId, orElse: () => farms.first);

      _farms = farms;
      _selectedFarm = farm;

      ref.read(dailyRecordFarmIdProvider.notifier).selectFarm(farm.id);
      await _loadBatchesForFarm(farm.id, targetBatchId: widget.initialBatchId);
    } catch (e) {
      debugPrint('[LogDataWizard] _loadFarmsAndBatches error: $e');
      if (mounted) {
        _farms = [_defaultFarm];
        _selectedFarm = _defaultFarm;
        _batches = [_defaultBatch];
        _selectedBatch = _defaultBatch;
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadBatchesForFarm(String farmId, {String? targetBatchId}) async {
    try {
      var batches = await BatchService.getBatchesByFarmId(farmId).timeout(
        const Duration(seconds: 3),
        onTimeout: () => [_defaultBatch],
      );
      if (batches.isEmpty) {
        batches = [_defaultBatch];
      }
      if (!mounted) return;
      setState(() {
        _batches = batches;
        final selected = targetBatchId != null
            ? batches.firstWhere((b) => b.id == targetBatchId, orElse: () => batches.first)
            : batches.first;
        _selectedBatch = selected;
        ref.read(dailyRecordBatchIdProvider.notifier).selectBatch(selected.id);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _batches = [_defaultBatch];
          _selectedBatch = _defaultBatch;
        });
      }
    }
  }

  void _clearFormFields() {
    _feedTypeController.clear();
    _feedQuantityController.clear();
    _feedCostController.clear();
    _feedNotesController.clear();
    _waterQuantityController.clear();
    _waterSourceController.clear();
    _waterNotesController.clear();
    _mortalityCountController.clear();
    _mortalityReasonController.clear();
    _mortalityNotesController.clear();
    _medicineNameController.clear();
    _medicineQuantityController.clear();
    _medicinePurposeController.clear();
    _medicineCostController.clear();
    _medicineNotesController.clear();
    _vaccineNameController.clear();
    _vaccineDoseController.clear();
    _vaccineBatchNumController.clear();
    _vaccineNotesController.clear();
    _weightSampleCountController.clear();
    _weightAvgGramsController.clear();
    _weightNotesController.clear();
    _notesTitleController.clear();
    _notesDescController.clear();
    _dgLevelController.clear();
    _dgAddedController.clear();
    _dgHoursController.clear();
    _dgNameController.clear();
    _dgNotesController.clear();
  }

  // Quick Add: Prefill with previous record
  Future<void> _repeatPreviousDayRecord() async {
    if (_selectedFarm == null || _selectedBatch == null || _selectedRecordType == null) return;

    final latest = await DailyRecordService.getBatchLatestRecord(
      farmId: _selectedFarm!.id,
      batchId: _selectedBatch!.id,
    );

    if (latest == null) {
      setState(() {
        switch (_selectedRecordType!) {
          case LogRecordType.feed:
            _feedTypeController.text = 'Broiler Starter';
            _feedQuantityController.text = '50';
            break;
          case LogRecordType.water:
            _waterQuantityController.text = '120';
            _waterSourceController.text = 'Main Borewell';
            break;
          case LogRecordType.mortality:
            _mortalityCountController.text = '0';
            _mortalityReasonController.text = 'None';
            break;
          case LogRecordType.medicine:
            _medicineNameController.text = 'Multivitamin';
            _medicineQuantityController.text = '1';
            _medicinePurposeController.text = 'Preventive Supplement';
            break;
          case LogRecordType.vaccine:
            _vaccineNameController.text = 'Lasota (ND)';
            _vaccineDoseController.text = '1 dose / bird';
            break;
          case LogRecordType.weight:
            _weightAvgGramsController.text = '1450';
            _weightSampleCountController.text = '50';
            break;
          case LogRecordType.notes:
            _notesTitleController.text = 'Daily Flock Inspection';
            _notesDescController.text = 'All birds active and healthy.';
            break;
          case LogRecordType.dg:
            _dgNameController.text = 'Main Generator';
            _dgLevelController.text = '120';
            _dgAddedController.text = '20';
            _dgHoursController.text = '2';
            break;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filled with standard telemetry defaults.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      switch (_selectedRecordType!) {
        case LogRecordType.feed:
          _feedTypeController.text = latest.feedType ?? 'Broiler Starter';
          _feedQuantityController.text =
              latest.feedConsumedKg > 0 ? latest.feedConsumedKg.toString() : '50';
          _feedCostController.text = latest.feedCost != null ? latest.feedCost.toString() : '';
          _feedNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.water:
          _waterQuantityController.text =
              latest.waterConsumedLiters > 0 ? latest.waterConsumedLiters.toString() : '120';
          _waterSourceController.text = latest.waterSource ?? 'Borewell';
          _waterNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.mortality:
          _mortalityCountController.text = latest.mortalityCount.toString();
          _mortalityReasonController.text = latest.mortalityCause ?? 'Natural';
          _mortalityNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.medicine:
          _medicineNameController.text = latest.medicineName ?? 'Multivitamin';
          _medicineQuantityController.text =
              latest.medicineQuantity != null ? latest.medicineQuantity.toString() : '1';
          _medicinePurposeController.text = latest.medicineReason ?? 'Preventive';
          _medicineCostController.text =
              latest.medicineCost != null ? latest.medicineCost.toString() : '';
          _medicineNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.vaccine:
          _vaccineNameController.text = latest.vaccineName ?? 'Lasota';
          _vaccineDoseController.text = latest.vaccineDose ?? '1 drop / bird';
          _vaccineBatchNumController.text = latest.symptoms ?? '';
          _vaccineNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.weight:
          _weightAvgGramsController.text =
              latest.avgWeightGrams > 0 ? latest.avgWeightGrams.toString() : '1450';
          _weightSampleCountController.text =
              latest.sampleBirds != null ? latest.sampleBirds.toString() : '50';
          _weightNotesController.text = latest.notes ?? '';
          break;
        case LogRecordType.notes:
          _notesTitleController.text = 'Daily Check';
          _notesDescController.text = latest.notes ?? '';
          break;
        case LogRecordType.dg:
          _dgLevelController.text = latest.dgLevelLiters != null ? latest.dgLevelLiters.toString() : '100';
          _dgAddedController.text = latest.dgAddedLiters != null ? latest.dgAddedLiters.toString() : '0';
          _dgHoursController.text = latest.dgRunningHours != null ? latest.dgRunningHours.toString() : '2';
          _dgNameController.text = latest.dgName ?? 'Main Generator';
          _dgNotesController.text = latest.notes ?? '';
          break;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form pre-filled with previous record values!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_selectedFarm == null || _selectedBatch == null || _selectedRecordType == null) return;

    setState(() => _isSaving = true);
    try {
      final farmId = _selectedFarm!.id;
      final batchId = _selectedBatch!.id;
      final now = DateTime.now();

      final existingRecord = await DailyRecordService.getDailyRecordByDate(
        farmId: farmId,
        batchId: batchId,
        recordDate: now,
      );

      final currentBirds = _selectedBatch!.currentBirds;
      final opening = existingRecord?.openingBirds ?? currentBirds;
      final ageDay = DateTime.now().difference(_selectedBatch!.placementDate).inDays + 1;

      // Extract form values based on Record Type
      double feedKg = existingRecord?.feedConsumedKg ?? 0.0;
      String? feedType = existingRecord?.feedType;
      double? feedCost = existingRecord?.feedCost;

      double waterL = existingRecord?.waterConsumedLiters ?? 0.0;
      String? waterSource = existingRecord?.waterSource;

      int mortalityCount = existingRecord?.mortalityCount ?? 0;
      String? mortalityCause = existingRecord?.mortalityCause;

      bool medGiven = existingRecord?.medicineGiven ?? false;
      String? medName = existingRecord?.medicineName;
      double? medQty = existingRecord?.medicineQuantity;
      String? medReason = existingRecord?.medicineReason;
      double? medCost = existingRecord?.medicineCost;

      bool vacGiven = existingRecord?.vaccineGiven ?? false;
      String? vacName = existingRecord?.vaccineName;
      String? vacDose = existingRecord?.vaccineDose;
      String? vacBatchNum = existingRecord?.symptoms;

      double avgWeight = existingRecord?.avgWeightGrams ?? 0.0;
      int? sampleCount = existingRecord?.sampleBirds;

      double? dgLevel = existingRecord?.dgLevelLiters;
      double? dgAdded = existingRecord?.dgAddedLiters;
      double? dgHours = existingRecord?.dgRunningHours;
      String? dgName = existingRecord?.dgName;

      String? notes = existingRecord?.notes;

      switch (_selectedRecordType!) {
        case LogRecordType.feed:
          feedType = _feedTypeController.text.trim();
          final rawQty = double.tryParse(_feedQuantityController.text.trim()) ?? 0.0;
          feedKg = _feedUnit == 'bags' ? rawQty * 50.0 : rawQty;
          feedCost = double.tryParse(_feedCostController.text.trim());
          notes = _feedNotesController.text.trim();
          break;

        case LogRecordType.water:
          waterL = double.tryParse(_waterQuantityController.text.trim()) ?? 0.0;
          waterSource = _waterSourceController.text.trim();
          notes = _waterNotesController.text.trim();
          break;

        case LogRecordType.mortality:
          mortalityCount = int.tryParse(_mortalityCountController.text.trim()) ?? 0;
          mortalityCause = _mortalityReasonController.text.trim();
          notes = _mortalityNotesController.text.trim();
          break;

        case LogRecordType.medicine:
          medGiven = true;
          medName = _medicineNameController.text.trim();
          medQty = double.tryParse(_medicineQuantityController.text.trim());
          medReason = _medicinePurposeController.text.trim();
          medCost = double.tryParse(_medicineCostController.text.trim());
          notes = _medicineNotesController.text.trim();
          break;

        case LogRecordType.vaccine:
          vacGiven = true;
          vacName = _vaccineNameController.text.trim();
          vacDose = _vaccineDoseController.text.trim();
          vacBatchNum = _vaccineBatchNumController.text.trim();
          notes = _vaccineNotesController.text.trim();
          break;

        case LogRecordType.weight:
          avgWeight = double.tryParse(_weightAvgGramsController.text.trim()) ?? 0.0;
          sampleCount = int.tryParse(_weightSampleCountController.text.trim());
          notes = _weightNotesController.text.trim();
          break;

        case LogRecordType.notes:
          final title = _notesTitleController.text.trim();
          final desc = _notesDescController.text.trim();
          notes = title.isNotEmpty ? '$title: $desc' : desc;
          break;

        case LogRecordType.dg:
          dgLevel = double.tryParse(_dgLevelController.text.trim());
          dgAdded = double.tryParse(_dgAddedController.text.trim());
          dgHours = double.tryParse(_dgHoursController.text.trim());
          dgName = _dgNameController.text.trim();
          notes = _dgNotesController.text.trim();
          break;
      }

      await DailyRecordService.createOrUpdateDailyRecord(
        farmId: farmId,
        batchId: batchId,
        recordDate: now,
        batchAgeDay: ageDay,
        openingBirds: opening,
        mortalityCount: mortalityCount,
        cullCount: existingRecord?.cullCount ?? 0,
        adjustmentCount: existingRecord?.adjustmentCount ?? 0,
        feedConsumedKg: feedKg,
        waterConsumedLiters: waterL,
        avgWeightGrams: avgWeight,
        medicineGiven: medGiven,
        medicineName: medName,
        vaccineGiven: vacGiven,
        vaccineName: vacName,
        symptoms: vacBatchNum,
        notes: notes,
        feedType: feedType,
        feedCost: feedCost,
        waterSource: waterSource,
        mortalityCause: mortalityCause,
        sampleBirds: sampleCount,
        medicineQuantity: medQty,
        medicineReason: medReason,
        medicineCost: medCost,
        vaccineDose: vacDose,
        dgLevelLiters: dgLevel,
        dgAddedLiters: dgAdded,
        dgRunningHours: dgHours,
        dgName: dgName,
      );

      if (!mounted) return;
      ref.invalidate(dailyRecordsStreamProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Record Saved Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset wizard to Step 0
      setState(() {
        _currentStep = 0;
        _selectedRecordType = null;
        _clearFormFields();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save record: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedFarm == null || _selectedBatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid Farm and Batch.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedRecordType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Record Type.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DailyRecordModel> recentRecords =
        ref.watch(dailyRecordsStreamProvider).asData?.value ?? [];

    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Data Wizard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Record farm metrics in under 30 seconds',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 14),
              Text(
                'Loading farm details...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Data Wizard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Record farm metrics in under 30 seconds',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Step Indicator Bar
          _buildStepIndicator(),

          // 2. Step Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentStep == 0) _buildStep1FarmBatch(),
                  if (_currentStep == 1) _buildStep2RecordTypeSelection(),
                  if (_currentStep == 2) _buildStep3DynamicForm(),
                  if (_currentStep == 3) _buildStep4Review(),

                  const SizedBox(height: 28),
                  // Recent Records List (Last 5 records)
                  if (_currentStep == 0 || _currentStep == 1) _buildRecentRecordsSection(recentRecords),
                ],
              ),
            ),
          ),

          // 3. Navigation Controls Bar
          _buildBottomNavigationControls(),
        ],
      ),
    );
  }

  // Step Indicator Widget
  Widget _buildStepIndicator() {
    final steps = ['Farm', 'Type', 'Details', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : (isCompleted ? const Color(0xFFEAF5EA) : const Color(0xFFF0F0F0)),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: AppColors.primary)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive || isCompleted ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 14,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: const Color(0xFFDDDDDD),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // STEP 1: FARM & BATCH
  Widget _buildStep1FarmBatch() {
    final currentBirds = _selectedBatch?.currentBirds ?? 0;
    int ageDays = 1;
    if (_selectedBatch != null) {
      try {
        final diff = DateTime.now().difference(_selectedBatch!.placementDate).inDays + 1;
        if (diff > 0) ageDays = diff;
      } catch (_) {}
    }
    final avgWeight = 1450; // Standard batch average weight fallback

    final List<FarmModel> farmList = [];
    final Set<String> seenFarmIds = {};
    for (final f in _farms) {
      final safeId = f.id.trim().isNotEmpty ? f.id.trim() : 'farm_${farmList.length}';
      if (!seenFarmIds.contains(safeId)) {
        seenFarmIds.add(safeId);
        farmList.add(f.id == safeId ? f : f.copyWith(id: safeId));
      }
    }
    if (farmList.isEmpty) farmList.add(_defaultFarm);

    final String selectedFarmId = farmList.any((f) => f.id == _selectedFarm?.id)
        ? _selectedFarm!.id
        : farmList.first.id;

    final List<BatchModel> batchList = [];
    final Set<String> seenBatchIds = {};
    for (final b in _batches) {
      final safeId = b.id.trim().isNotEmpty ? b.id.trim() : 'batch_${batchList.length}';
      if (!seenBatchIds.contains(safeId)) {
        seenBatchIds.add(safeId);
        batchList.add(b.id == safeId ? b : b.copyWith(id: safeId));
      }
    }
    if (batchList.isEmpty) batchList.add(_defaultBatch);

    final String selectedBatchId = batchList.any((b) => b.id == _selectedBatch?.id)
        ? _selectedBatch!.id
        : batchList.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Target Farm & Batch',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the active farm location and batch to log telemetry.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),

        // Farm Dropdown
        DropdownButtonFormField<String>(
          value: selectedFarmId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Farm Location',
            prefixIcon: const Icon(Icons.agriculture_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: farmList.map((f) {
            return DropdownMenuItem<String>(
              value: f.id,
              child: Text(
                f.farmName.trim().isNotEmpty ? f.farmName : 'Farm (${f.id})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final farm = farmList.firstWhere((f) => f.id == val, orElse: () => farmList.first);
              setState(() => _selectedFarm = farm);
              try {
                ref.read(dailyRecordFarmIdProvider.notifier).selectFarm(val);
              } catch (_) {}
              _loadBatchesForFarm(val);
            }
          },
        ),
        const SizedBox(height: 14),

        // Batch Dropdown
        DropdownButtonFormField<String>(
          value: selectedBatchId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Active Batch',
            prefixIcon: const Icon(Icons.layers_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: batchList.map((b) {
            return DropdownMenuItem<String>(
              value: b.id,
              child: Text(
                b.batchName.trim().isNotEmpty ? b.batchName : 'Batch (${b.id})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final batch = batchList.firstWhere((b) => b.id == val, orElse: () => batchList.first);
              setState(() => _selectedBatch = batch);
              try {
                ref.read(dailyRecordBatchIdProvider.notifier).selectBatch(val);
              } catch (_) {}
            }
          },
        ),
        const SizedBox(height: 20),

        // Compact Batch Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EFE2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedBatch?.batchName ?? 'Batch Telemetry',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Current Birds',
                      value: '$currentBirds',
                      unit: 'birds',
                      icon: Icons.groups_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Flock Age',
                      value: '$ageDays',
                      unit: 'days',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Avg Weight',
                      value: '$avgWeight',
                      unit: 'grams',
                      icon: Icons.scale_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: RECORD TYPE SELECTION
  Widget _buildStep2RecordTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you want to record today?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a tile to configure metric details.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: LogRecordType.values.length,
          itemBuilder: (context, index) {
            final type = LogRecordType.values[index];
            final isSelected = _selectedRecordType == type;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedRecordType = type);
                _nextStep();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF5EA) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        type.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 3: DYNAMIC FORM
  Widget _buildStep3DynamicForm() {
    final type = _selectedRecordType!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    '${type.title} Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),

              // Quick Add Button: Repeat previous day's record
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _repeatPreviousDayRecord,
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Quick Add (Repeat Last)'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dynamic fields per selected type
          if (type == LogRecordType.feed) ...[
            TextFormField(
              controller: _feedTypeController,
              decoration: InputDecoration(
                labelText: 'Feed Type',
                hintText: 'e.g., Broiler Starter, Finisher',
                prefixIcon: const Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter feed type' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _feedQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(Icons.scale_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter quantity';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid quantity';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _feedUnit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'bags', child: Text('bags (50kg)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _feedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _feedCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cost (Optional)',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _feedNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.water) ...[
            TextFormField(
              controller: _waterQuantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Water Quantity (Liters)',
                prefixIcon: const Icon(Icons.water_drop_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter water quantity in Liters';
                final val = double.tryParse(v);
                if (val == null || val < 0) return 'Invalid quantity';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _waterSourceController,
              decoration: InputDecoration(
                labelText: 'Source / Tank Name (Optional)',
                hintText: 'e.g., Tank A, Borewell',
                prefixIcon: const Icon(Icons.water_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _waterNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.mortality) ...[
            TextFormField(
              controller: _mortalityCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Dead Birds',
                prefixIcon: const Icon(Icons.sick_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter mortality count';
                final val = int.tryParse(v);
                if (val == null || val < 0) return 'Invalid mortality count';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mortalityReasonController,
              decoration: InputDecoration(
                labelText: 'Cause / Suspected Reason',
                hintText: 'e.g., Heat stress, Natural',
                prefixIcon: const Icon(Icons.help_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mortalityNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.medicine) ...[
            TextFormField(
              controller: _medicineNameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'e.g., Multivitamin, Antibiotic',
                prefixIcon: const Icon(Icons.medication_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter medicine name' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medicineQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _medicineCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cost (Optional)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _medicinePurposeController,
              decoration: InputDecoration(
                labelText: 'Purpose / Reason',
                hintText: 'e.g., Growth booster, Preventive',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _medicineNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.vaccine) ...[
            TextFormField(
              controller: _vaccineNameController,
              decoration: InputDecoration(
                labelText: 'Vaccine Name',
                hintText: 'e.g., Lasota, Ranikhet, Gumboro',
                prefixIcon: const Icon(Icons.vaccines_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                      labelText: 'Dose',
                      hintText: 'e.g., 1 drop / bird',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _vaccineBatchNumController,
                    decoration: InputDecoration(
                      labelText: 'Batch Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _vaccineNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.weight) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightAvgGramsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Avg Weight (Grams)',
                      suffixText: 'g',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter average weight';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid weight';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _weightSampleCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Sample Count',
                      suffixText: 'birds',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weightNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ] else if (type == LogRecordType.notes) ...[
            TextFormField(
              controller: _notesTitleController,
              decoration: InputDecoration(
                labelText: 'Note Title',
                hintText: 'e.g., Shed temperature check, Litter condition',
                prefixIcon: const Icon(Icons.title_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter note title' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesDescController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter note description' : null,
            ),
          ] else if (type == LogRecordType.dg) ...[
            TextFormField(
              controller: _dgNameController,
              decoration: InputDecoration(
                labelText: 'Generator Name (Optional)',
                hintText: 'e.g., Main 50kVA Generator',
                prefixIcon: const Icon(Icons.electric_bolt_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _dgLevelController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Current Diesel Level',
                      suffixText: 'L',
                      prefixIcon: const Icon(Icons.local_gas_station_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter current diesel level';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid fuel level';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dgAddedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Added Today',
                      suffixText: 'L',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final val = double.tryParse(v);
                        if (val == null || val < 0) return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dgHoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Running Hours (Optional)',
                suffixText: 'hrs',
                prefixIcon: const Icon(Icons.timer_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Invalid running hours';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dgNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Remarks / Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 4: REVIEW SCREEN
  Widget _buildStep4Review() {
    final type = _selectedRecordType!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Review & Confirm Entry',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verify all entered parameters before committing to Firebase.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${type.emoji} ${type.title} Record',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedFarm?.farmName} • ${_selectedBatch?.batchName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep = 2),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Entered Values Summary
              ..._buildReviewEnteredValuesList(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReviewEnteredValuesList() {
    final values = <MapEntry<String, String>>[];
    switch (_selectedRecordType!) {
      case LogRecordType.feed:
        values.add(MapEntry('Feed Type', _feedTypeController.text.trim()));
        values.add(MapEntry('Quantity', '${_feedQuantityController.text.trim()} $_feedUnit'));
        if (_feedCostController.text.isNotEmpty) {
          values.add(MapEntry('Cost', '₹${_feedCostController.text.trim()}'));
        }
        if (_feedNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _feedNotesController.text.trim()));
        }
        break;
      case LogRecordType.water:
        values.add(MapEntry('Water Quantity', '${_waterQuantityController.text.trim()} L'));
        if (_waterSourceController.text.isNotEmpty) {
          values.add(MapEntry('Tank / Source', _waterSourceController.text.trim()));
        }
        if (_waterNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _waterNotesController.text.trim()));
        }
        break;
      case LogRecordType.mortality:
        values.add(MapEntry('Dead Birds', _mortalityCountController.text.trim()));
        if (_mortalityReasonController.text.isNotEmpty) {
          values.add(MapEntry('Reason', _mortalityReasonController.text.trim()));
        }
        if (_mortalityNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _mortalityNotesController.text.trim()));
        }
        break;
      case LogRecordType.medicine:
        values.add(MapEntry('Medicine Name', _medicineNameController.text.trim()));
        if (_medicineQuantityController.text.isNotEmpty) {
          values.add(MapEntry('Quantity', _medicineQuantityController.text.trim()));
        }
        if (_medicinePurposeController.text.isNotEmpty) {
          values.add(MapEntry('Purpose', _medicinePurposeController.text.trim()));
        }
        if (_medicineCostController.text.isNotEmpty) {
          values.add(MapEntry('Cost', '₹${_medicineCostController.text.trim()}'));
        }
        if (_medicineNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _medicineNotesController.text.trim()));
        }
        break;
      case LogRecordType.vaccine:
        values.add(MapEntry('Vaccine Name', _vaccineNameController.text.trim()));
        if (_vaccineDoseController.text.isNotEmpty) {
          values.add(MapEntry('Dose', _vaccineDoseController.text.trim()));
        }
        if (_vaccineBatchNumController.text.isNotEmpty) {
          values.add(MapEntry('Vaccine Batch #', _vaccineBatchNumController.text.trim()));
        }
        if (_vaccineNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _vaccineNotesController.text.trim()));
        }
        break;
      case LogRecordType.weight:
        values.add(MapEntry('Average Weight', '${_weightAvgGramsController.text.trim()} g'));
        values.add(MapEntry('Sample Count', '${_weightSampleCountController.text.trim()} birds'));
        if (_weightNotesController.text.isNotEmpty) {
          values.add(MapEntry('Notes', _weightNotesController.text.trim()));
        }
        break;
      case LogRecordType.notes:
        values.add(MapEntry('Title', _notesTitleController.text.trim()));
        values.add(MapEntry('Description', _notesDescController.text.trim()));
        break;
      case LogRecordType.dg:
        if (_dgNameController.text.isNotEmpty) {
          values.add(MapEntry('Generator Name', _dgNameController.text.trim()));
        }
        values.add(MapEntry('Current Diesel Level', '${_dgLevelController.text.trim()} L'));
        if (_dgAddedController.text.isNotEmpty) {
          values.add(MapEntry('Diesel Added Today', '${_dgAddedController.text.trim()} L'));
        }
        if (_dgHoursController.text.isNotEmpty) {
          values.add(MapEntry('Running Hours', '${_dgHoursController.text.trim()} hrs'));
        }
        if (_dgNotesController.text.isNotEmpty) {
          values.add(MapEntry('Remarks', _dgNotesController.text.trim()));
        }
        break;
    }

    return values.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Recent Records Section (Last 5 records)
  Widget _buildRecentRecordsSection(List<DailyRecordModel> records) {
    final recent5 = records.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT LOGGED RECORDS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        if (recent5.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No recent telemetry records found.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Column(
            children: recent5.map((r) {
              final dateStr =
                  '${r.recordDate.year}-${r.recordDate.month.toString().padLeft(2, '0')}-${r.recordDate.day.toString().padLeft(2, '0')}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0x1A1B5E20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Day ${r.batchAgeDay} • ${r.closingBirds} Birds Remaining',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (r.feedConsumedKg > 0)
                      Text('${r.feedConsumedKg} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))
                    else if (r.mortalityCount > 0)
                      Text('${r.mortalityCount} dead', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger))
                    else if (r.waterConsumedLiters > 0)
                      Text('${r.waterConsumedLiters} L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)))
                    else if (r.avgWeightGrams > 0)
                      Text('${r.avgWeightGrams} g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)))
                    else if (r.medicineGiven)
                      Text('Med', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100)))
                    else if (r.vaccineGiven)
                      Text('Vaccine', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Bottom Navigation Controls Bar
  Widget _buildBottomNavigationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < 3)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveRecord,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Confirm & Save'),
            ),
        ],
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
