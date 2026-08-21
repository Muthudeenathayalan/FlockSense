import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/widgets/sync_status_banner.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_records_providers.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

enum LogRecordType {
  feed('Feed Intake', '🌾', Icons.restaurant_outlined, Color(0xFFD97706), Color(0xFFFFFBEB), 'Track feed type, bags & total kg'),
  water('Water Intake', '💧', Icons.water_drop_outlined, Color(0xFF2563EB), Color(0xFFEFF6FF), 'Log daily water usage (Liters)'),
  mortality('Mortality', '☠️', Icons.sick_outlined, Color(0xFFDC2626), Color(0xFFFEF2F2), 'Record dead birds & causes'),
  medicine('Medicine', '💊', Icons.medication_outlined, Color(0xFF7C3AED), Color(0xFFF5F3FF), 'Treatments & supplements'),
  vaccine('Vaccination', '💉', Icons.vaccines_outlined, Color(0xFF0D9488), Color(0xFFF0FDFA), 'Track vaccine doses & batch #'),
  weight('Body Weight', '⚖️', Icons.monitor_weight_outlined, Color(0xFF4F46E5), Color(0xFFEEF2FF), 'Sample weight & growth metrics'),
  notes('Shed Notes', '📝', Icons.notes_outlined, Color(0xFF059669), Color(0xFFECFDF5), 'Observations & remarks'),
  dg('DG Generator', '⚡', Icons.electric_bolt_outlined, Color(0xFFEA580C), Color(0xFFFFF7ED), 'Diesel level & running hours');

  final String title;
  final String emoji;
  final IconData icon;
  final Color accentColor;
  final Color bgTint;
  final String subtitle;

  const LogRecordType(
    this.title,
    this.emoji,
    this.icon,
    this.accentColor,
    this.bgTint,
    this.subtitle,
  );
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
  // 2-Step Wizard: 0 = Select (Farm, Batch & Record Type), 1 = Details & Review
  int _currentStep = 0;
  bool _isLoadingData = true;
  bool _isSaving = false;

  List<FarmModel> _farms = [_defaultFarm];
  List<BatchModel> _batches = [_defaultBatch];
  FarmModel? _selectedFarm = _defaultFarm;
  BatchModel? _selectedBatch = _defaultBatch;

  // Mode Selection: true = Daily Operations Log Bundle (Feed, Water, Mortality, DG)
  // false = Single Optional Category (Medicine, Vaccine, Weight, Notes)
  bool _isDailyOpsSelected = true;
  LogRecordType? _selectedOptionalType;

  // Path A (Daily Operations Bundle Accordion state)
  int _expandedSectionIndex = 0; // 0=Feed, 1=Water, 2=Mortality, 3=DG

  final _formKey = GlobalKey<FormState>();

  // Feed
  final _feedTypeController = TextEditingController(text: 'Broiler Starter');
  final _feedQuantityController = TextEditingController();
  final _feedCostController = TextEditingController();
  final _feedNotesController = TextEditingController();
  String _feedUnit = 'kg';

  // Water
  final _waterQuantityController = TextEditingController();
  final _waterSourceController = TextEditingController(text: 'Main Borewell');
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
  final _dgNameController = TextEditingController(text: 'Main Generator');
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
      _isDailyOpsSelected = true;
      _feedTypeController.text = record.feedType ?? 'Broiler Starter';
      _feedQuantityController.text =
          record.feedConsumedKg > 0 ? record.feedConsumedKg.toString() : '';
      _feedCostController.text =
          record.feedCost != null ? record.feedCost.toString() : '';
      _feedNotesController.text = record.notes ?? '';
    }
    if (record.waterConsumedLiters > 0 || record.waterSource != null) {
      _waterQuantityController.text = record.waterConsumedLiters > 0
          ? record.waterConsumedLiters.toString()
          : '';
      _waterSourceController.text = record.waterSource ?? 'Main Borewell';
      _waterNotesController.text = record.notes ?? '';
    }
    if (record.mortalityCount > 0 || record.mortalityCause != null) {
      _mortalityCountController.text =
          record.mortalityCount > 0 ? record.mortalityCount.toString() : '';
      _mortalityReasonController.text = record.mortalityCause ?? '';
      _mortalityNotesController.text = record.notes ?? '';
    }
    if (record.medicineGiven || record.medicineName != null) {
      _isDailyOpsSelected = false;
      _selectedOptionalType = LogRecordType.medicine;
      _medicineNameController.text = record.medicineName ?? '';
      _medicineQuantityController.text = record.medicineQuantity != null
          ? record.medicineQuantity.toString()
          : '';
      _medicinePurposeController.text = record.medicineReason ?? '';
      _medicineCostController.text =
          record.medicineCost != null ? record.medicineCost.toString() : '';
      _medicineNotesController.text = record.notes ?? '';
    } else if (record.vaccineGiven || record.vaccineName != null) {
      _isDailyOpsSelected = false;
      _selectedOptionalType = LogRecordType.vaccine;
      _vaccineNameController.text = record.vaccineName ?? '';
      _vaccineDoseController.text = record.vaccineDose ?? '';
      _vaccineBatchNumController.text = record.symptoms ?? '';
      _vaccineNotesController.text = record.notes ?? '';
    } else if (record.avgWeightGrams > 0) {
      _isDailyOpsSelected = false;
      _selectedOptionalType = LogRecordType.weight;
      _weightAvgGramsController.text = record.avgWeightGrams.toString();
      _weightSampleCountController.text =
          record.sampleBirds != null ? record.sampleBirds.toString() : '';
      _weightNotesController.text = record.notes ?? '';
    } else if (record.dgLevelLiters != null || record.dgName != null) {
      _dgLevelController.text =
          record.dgLevelLiters != null ? record.dgLevelLiters.toString() : '';
      _dgAddedController.text =
          record.dgAddedLiters != null ? record.dgAddedLiters.toString() : '';
      _dgHoursController.text = record.dgRunningHours != null
          ? record.dgRunningHours.toString()
          : '';
      _dgNameController.text = record.dgName ?? 'Main Generator';
      _dgNotesController.text = record.notes ?? '';
    }
    _currentStep = 1;
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

  Future<void> _saveLastSelection(String farmId, String batchId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flocksense_last_farm_$uid', farmId);
      await prefs.setString('flocksense_last_batch_$uid', batchId);
    } catch (_) {}
  }

  Future<void> _loadFarmsAndBatches() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
      final prefs = await SharedPreferences.getInstance();
      final lastFarmId = prefs.getString('flocksense_last_farm_$uid');
      final lastBatchId = prefs.getString('flocksense_last_batch_$uid');

      var farms = await FarmService.getUserFarms().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [_defaultFarm],
      );
      if (farms.isEmpty) {
        farms = [_defaultFarm];
      }
      if (!mounted) return;

      final activeFarmId = widget.initialFarmId ??
          (lastFarmId != null && farms.any((f) => f.id == lastFarmId) ? lastFarmId : null) ??
          ref.read(activeFarmIdProvider).asData?.value ??
          farms.first.id;
      final farm = farms.firstWhere((f) => f.id == activeFarmId, orElse: () => farms.first);

      _farms = farms;
      _selectedFarm = farm;

      ref.read(dailyRecordFarmIdProvider.notifier).selectFarm(farm.id);
      final targetBatchId = widget.initialBatchId ?? lastBatchId;
      await _loadBatchesForFarm(farm.id, targetBatchId: targetBatchId);

      // Auto-skip Step 1 if there's only 1 farm and 1 active batch
      if (mounted) {
        final activeBatches = _batches.where((b) => b.status != 'archived').toList();
        if (_farms.length == 1 && (activeBatches.length == 1 || _batches.length == 1)) {
          _currentStep = 1;
        }
      }
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
      if (_selectedFarm != null && _selectedBatch != null) {
        _saveLastSelection(_selectedFarm!.id, _selectedBatch!.id);
      }
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
    _feedTypeController.text = 'Broiler Starter';
    _feedQuantityController.clear();
    _feedCostController.clear();
    _feedNotesController.clear();
    _waterQuantityController.clear();
    _waterSourceController.text = 'Main Borewell';
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
    _dgNameController.text = 'Main Generator';
    _dgNotesController.clear();
  }

  // Validity checks for Path A (Daily Operations Log Bundle)
  bool get _isFeedValid => _feedQuantityController.text.trim().isNotEmpty;
  bool get _isWaterValid => _waterQuantityController.text.trim().isNotEmpty;
  bool get _isMortalityValid => _mortalityCountController.text.trim().isNotEmpty;
  bool get _isDgValid =>
      _dgLevelController.text.trim().isNotEmpty ||
      _dgAddedController.text.trim().isNotEmpty ||
      _dgHoursController.text.trim().isNotEmpty;

  bool get _isAllBundleValid =>
      _isFeedValid && _isWaterValid && _isMortalityValid && _isDgValid;

  // Validity check for Path B (Single Optional Category)
  bool get _isOptionalValid {
    if (_selectedOptionalType == null) return false;
    switch (_selectedOptionalType!) {
      case LogRecordType.medicine:
        return _medicineNameController.text.trim().isNotEmpty &&
            _medicineQuantityController.text.trim().isNotEmpty;
      case LogRecordType.vaccine:
        return _vaccineNameController.text.trim().isNotEmpty;
      case LogRecordType.weight:
        return _weightAvgGramsController.text.trim().isNotEmpty;
      case LogRecordType.notes:
        return _notesDescController.text.trim().isNotEmpty ||
            _notesTitleController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _copyYesterdayValues() async {
    if (_selectedFarm == null || _selectedBatch == null) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    var yesterdayRecord = await DailyRecordService.getDailyRecordByDate(
      farmId: _selectedFarm!.id,
      batchId: _selectedBatch!.id,
      recordDate: yesterday,
    );

    yesterdayRecord ??= await DailyRecordService.getLatestRecordBeforeDate(
      farmId: _selectedFarm!.id,
      batchId: _selectedBatch!.id,
      beforeDate: DateTime.now(),
    );

    if (yesterdayRecord == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data from yesterday'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (_isDailyOpsSelected) {
        // Pre-fill Feed, Water, and Weight ONLY
        _feedTypeController.text = yesterdayRecord!.feedType ?? 'Broiler Starter';
        _feedQuantityController.text = yesterdayRecord.feedConsumedKg > 0
            ? (yesterdayRecord.feedConsumedKg % 1 == 0
                ? yesterdayRecord.feedConsumedKg.toInt().toString()
                : yesterdayRecord.feedConsumedKg.toString())
            : '';
        _feedCostController.text = yesterdayRecord.feedCost != null
            ? (yesterdayRecord.feedCost! % 1 == 0
                ? yesterdayRecord.feedCost!.toInt().toString()
                : yesterdayRecord.feedCost!.toString())
            : '';
        _feedNotesController.text = yesterdayRecord.notes ?? '';

        _waterQuantityController.text = yesterdayRecord.waterConsumedLiters > 0
            ? (yesterdayRecord.waterConsumedLiters % 1 == 0
                ? yesterdayRecord.waterConsumedLiters.toInt().toString()
                : yesterdayRecord.waterConsumedLiters.toString())
            : '';
        _waterSourceController.text = yesterdayRecord.waterSource ?? 'Main Borewell';

        if (yesterdayRecord.avgWeightGrams > 0) {
          _weightAvgGramsController.text = yesterdayRecord.avgWeightGrams % 1 == 0
              ? yesterdayRecord.avgWeightGrams.toInt().toString()
              : yesterdayRecord.avgWeightGrams.toString();
        }
        if (yesterdayRecord.sampleBirds != null) {
          _weightSampleCountController.text = yesterdayRecord.sampleBirds.toString();
        }

        // Deliberately do NOT copy Mortality or Medicine/Vaccine
      } else if (_selectedOptionalType == LogRecordType.weight) {
        if (yesterdayRecord!.avgWeightGrams > 0) {
          _weightAvgGramsController.text = yesterdayRecord.avgWeightGrams % 1 == 0
              ? yesterdayRecord.avgWeightGrams.toInt().toString()
              : yesterdayRecord.avgWeightGrams.toString();
        }
        if (yesterdayRecord.sampleBirds != null) {
          _weightSampleCountController.text = yesterdayRecord.sampleBirds.toString();
        }
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied yesterday's Feed, Water & Weight values"),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _repeatPreviousDayRecord() async {
    await _copyYesterdayValues();
  }

  Future<void> _saveRecord() async {
    if (_selectedFarm == null || _selectedBatch == null) return;

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
      final prevMortality = existingRecord?.mortalityCount ?? 0;
      final prevClosing = existingRecord?.closingBirds ?? opening;
      int loggedMortality = 0;

      if (_isDailyOpsSelected) {
        // Path A: Write all 4 daily operations in one bundle action
        final rawFeedQty = double.tryParse(_feedQuantityController.text.trim()) ?? 0.0;
        final feedKg = _feedUnit == 'bags' ? rawFeedQty * 50.0 : rawFeedQty;
        final feedCost = double.tryParse(_feedCostController.text.trim());
        final waterL = double.tryParse(_waterQuantityController.text.trim()) ?? 0.0;
        final mortalityCount = int.tryParse(_mortalityCountController.text.trim()) ?? 0;
        loggedMortality = mortalityCount;
        final dgLevel = double.tryParse(_dgLevelController.text.trim());
        final dgAdded = double.tryParse(_dgAddedController.text.trim());
        final dgHours = double.tryParse(_dgHoursController.text.trim());

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
          avgWeightGrams: existingRecord?.avgWeightGrams ?? 0.0,
          medicineGiven: existingRecord?.medicineGiven ?? false,
          medicineName: existingRecord?.medicineName,
          vaccineGiven: existingRecord?.vaccineGiven ?? false,
          vaccineName: existingRecord?.vaccineName,
          symptoms: existingRecord?.symptoms,
          notes: _feedNotesController.text.trim().isNotEmpty
              ? _feedNotesController.text.trim()
              : existingRecord?.notes,
          feedType: _feedTypeController.text.trim(),
          feedCost: feedCost,
          waterSource: _waterSourceController.text.trim(),
          mortalityCause: _mortalityReasonController.text.trim(),
          sampleBirds: existingRecord?.sampleBirds,
          medicineQuantity: existingRecord?.medicineQuantity,
          medicineReason: existingRecord?.medicineReason,
          medicineCost: existingRecord?.medicineCost,
          vaccineDose: existingRecord?.vaccineDose,
          dgLevelLiters: dgLevel,
          dgAddedLiters: dgAdded,
          dgRunningHours: dgHours,
          dgName: _dgNameController.text.trim(),
        );
      } else if (_selectedOptionalType != null) {
        // Path B: Optional Category write
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
        String? notes = existingRecord?.notes;

        switch (_selectedOptionalType!) {
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
          default:
            break;
        }

        await DailyRecordService.createOrUpdateDailyRecord(
          farmId: farmId,
          batchId: batchId,
          recordDate: now,
          batchAgeDay: ageDay,
          openingBirds: opening,
          mortalityCount: existingRecord?.mortalityCount ?? 0,
          cullCount: existingRecord?.cullCount ?? 0,
          adjustmentCount: existingRecord?.adjustmentCount ?? 0,
          feedConsumedKg: existingRecord?.feedConsumedKg ?? 0.0,
          waterConsumedLiters: existingRecord?.waterConsumedLiters ?? 0.0,
          avgWeightGrams: avgWeight,
          medicineGiven: medGiven,
          medicineName: medName,
          vaccineGiven: vacGiven,
          vaccineName: vacName,
          symptoms: vacBatchNum,
          notes: notes,
          feedType: existingRecord?.feedType,
          feedCost: existingRecord?.feedCost,
          waterSource: existingRecord?.waterSource,
          mortalityCause: existingRecord?.mortalityCause,
          sampleBirds: sampleCount,
          medicineQuantity: medQty,
          medicineReason: medReason,
          medicineCost: medCost,
          vaccineDose: vacDose,
          dgLevelLiters: existingRecord?.dgLevelLiters,
          dgAddedLiters: existingRecord?.dgAddedLiters,
          dgRunningHours: existingRecord?.dgRunningHours,
          dgName: existingRecord?.dgName,
        );
      }

      if (!mounted) return;
      ref.invalidate(dailyRecordsStreamProvider);

      if (_isDailyOpsSelected && loggedMortality > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged $loggedMortality mortality'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFFFBBF24),
              onPressed: () async {
                try {
                  await DailyRecordService.undoMortalityLog(
                    farmId: farmId,
                    batchId: batchId,
                    recordDate: now,
                    previousMortality: prevMortality,
                    previousClosing: prevClosing,
                  );
                  if (mounted) {
                    ref.invalidate(dailyRecordsStreamProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mortality log undone'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Undo mortality error: $e');
                }
              },
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
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
      }

      // Reset form / step
      setState(() {
        final activeBatches = _batches.where((b) => b.status != 'archived').toList();
        final shouldAutoSkip = _farms.length == 1 && (activeBatches.length == 1 || _batches.length == 1);
        _currentStep = shouldAutoSkip ? 1 : 0;
        _isDailyOpsSelected = true;
        _selectedOptionalType = null;
        _expandedSectionIndex = 0;
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
      setState(() => _currentStep = 1);
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
    final syncStatus = ref
        .watch(dailyRecordSyncStatusProvider)
        .maybeWhen(data: (s) => s, orElse: () => SyncStatus.synced);

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
          SyncStatusBanner(syncStatus: syncStatus),

          // 1. Stepper Bar (2-Node Stepper)
          _buildStepIndicator(),

          // 2. Step Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentStep == 0) _buildStep1Select(recentRecords),
                  if (_currentStep == 1) _buildStep2Details(),
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

  // 2-Node Stepper: "1 Select" > "2 Details"
  Widget _buildStepIndicator() {
    final steps = ['Select', 'Details'];
    final progressPcts = [0.5, 1.0];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progressPcts[_currentStep],
            backgroundColor: const Color(0xFFEFEFEF),
            color: AppColors.primary,
            minHeight: 3,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isCompleted ? const Color(0xFFEAF5EA) : const Color(0xFFF3F4F6)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : (isCompleted ? AppColors.primary : const Color(0xFFCBD5E1)),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w600,
                          color: isActive ? AppColors.primary : (isCompleted ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                      ),
                      if (index < steps.length - 1) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Divider(
                            height: 1,
                            thickness: 1.5,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: "SELECT" (Farm & Batch + Telemetry Picker)
  // ==========================================
  Widget _buildStep1Select(List<DailyRecordModel> recentRecords) {
    final currentBirds = _selectedBatch?.currentBirds ?? 0;
    int ageDays = 1;
    if (_selectedBatch != null) {
      try {
        final diff = DateTime.now().difference(_selectedBatch!.placementDate).inDays + 1;
        if (diff > 0) ageDays = diff;
      } catch (_) {}
    }
    const avgWeight = 1450;

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

    final optionalCategories = [
      LogRecordType.medicine,
      LogRecordType.vaccine,
      LogRecordType.weight,
      LogRecordType.notes,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1 Header
        const Text(
          'Select Target Farm & Batch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Outlined Material 3 Farm Dropdown
        DropdownButtonFormField<String>(
          key: ValueKey('farm_dropdown_$selectedFarmId'),
          initialValue: selectedFarmId,
          decoration: InputDecoration(
            labelText: 'Farm',
            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            prefixIcon: const Icon(Icons.agriculture_outlined, size: 20, color: Color(0xFF64748B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.normal,
          ),
          dropdownColor: Colors.white,
          items: farmList.map((farm) {
            return DropdownMenuItem<String>(
              value: farm.id,
              child: Text(
                farm.farmName.trim().isNotEmpty ? farm.farmName : 'Farm (${farm.id})',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (farmId) {
            if (farmId == null) return;
            final chosen = farmList.firstWhere((f) => f.id == farmId, orElse: () => farmList.first);
            setState(() => _selectedFarm = chosen);
            try {
              ref.read(dailyRecordFarmIdProvider.notifier).selectFarm(farmId);
            } catch (_) {}
            _loadBatchesForFarm(farmId);
            if (_selectedBatch != null) {
              _saveLastSelection(chosen.id, _selectedBatch!.id);
            }
          },
        ),
        const SizedBox(height: 12),

        // 2. Outlined Material 3 Batch Dropdown (or disabled non-interactive if single batch)
        if (batchList.length <= 1)
          TextFormField(
            initialValue: _selectedBatch?.batchName.trim().isNotEmpty == true
                ? _selectedBatch!.batchName
                : (batchList.isNotEmpty && batchList.first.batchName.trim().isNotEmpty
                    ? batchList.first.batchName
                    : 'default_batch'),
            key: ValueKey('batch_field_single_${_selectedBatch?.id}_${_selectedFarm?.id}'),
            readOnly: true,
            enabled: false,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              labelText: 'Batch',
              labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.layers_outlined, size: 20, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey('batch_dropdown_$selectedBatchId'),
            initialValue: selectedBatchId,
            decoration: InputDecoration(
              labelText: 'Batch',
              labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.layers_outlined, size: 20, color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.normal,
            ),
            dropdownColor: Colors.white,
            items: batchList.map((batch) {
              return DropdownMenuItem<String>(
                value: batch.id,
                child: Text(
                  batch.batchName.trim().isNotEmpty ? batch.batchName : 'Batch (${batch.id})',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (batchId) {
              if (batchId == null) return;
              final chosen = batchList.firstWhere((b) => b.id == batchId, orElse: () => batchList.first);
              setState(() => _selectedBatch = chosen);
              try {
                ref.read(dailyRecordBatchIdProvider.notifier).selectBatch(chosen.id);
              } catch (_) {}
              if (_selectedFarm != null) {
                _saveLastSelection(_selectedFarm!.id, chosen.id);
              }
            },
          ),
        const SizedBox(height: 6),

        // 3. Compact Plain Muted-Gray Stats Text (No dots/icons/badges)
        Text(
          '${NumberFormat('#,###').format(currentBirds)} birds · Day $ageDays · ${NumberFormat('#,###').format(avgWeight)}g avg',
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 18),

        // 3. Telemetry Log Type Picker Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'WHAT DO YOU WANT TO LOG TODAY?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Required Bundle Card: "Daily Operations Log"
        InkWell(
          onTap: () {
            setState(() {
              _isDailyOpsSelected = true;
              _selectedOptionalType = null;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDailyOpsSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isDailyOpsSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                width: _isDailyOpsSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isDailyOpsSelected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0x06000000),
                  blurRadius: _isDailyOpsSelected ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + "Required Today" Amber Pill + Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text(
                            'Daily Operations Log',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Amber Pill (Deliberately amber/orange, not green)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'Required Today',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isDailyOpsSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                      color: _isDailyOpsSelected ? AppColors.primary : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Feed, water, mortality, and power operations in one fast flow.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),

                // Row of 4 bundled category pastel circle icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniBundleChip(LogRecordType.feed),
                    _buildMiniBundleChip(LogRecordType.water),
                    _buildMiniBundleChip(LogRecordType.mortality),
                    _buildMiniBundleChip(LogRecordType.dg),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Optional Categories 2-Column Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: optionalCategories.length,
          itemBuilder: (context, index) {
            final type = optionalCategories[index];
            final isSelected = !_isDailyOpsSelected && _selectedOptionalType == type;

            return InkWell(
              onTap: () {
                setState(() {
                  _isDailyOpsSelected = false;
                  _selectedOptionalType = type;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? type.bgTint : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? type.accentColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? type.accentColor.withValues(alpha: 0.12) : const Color(0x04000000),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: type.bgTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: type.accentColor, size: 18)
                        else
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 16),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? type.accentColor : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 4. Recent Records Section
        _buildRecentRecordsSection(recentRecords),
      ],
    );
  }

  Widget _buildMiniBundleChip(LogRecordType type) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: type.bgTint,
            shape: BoxShape.circle,
            border: Border.all(color: type.accentColor.withValues(alpha: 0.2)),
          ),
          child: Text(type.emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 4),
        Text(
          type.title.split(' ').first,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: "DETAILS" (Path A: Daily Ops Bundle / Path B: Optional Category)
  // ==========================================
  Widget _buildStep2Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context Link / Chip with "Change" (Item 1)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.agriculture_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 7),
                  Text(
                    '${_selectedFarm?.farmName ?? "Farm"} · ${_selectedBatch?.batchName ?? "Batch"}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _currentStep = 0),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_left_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isDailyOpsSelected)
          _buildPathADailyOpsBundle()
        else
          _buildPathBOptionalCategory(),
      ],
    );
  }

  // ----------------------------------------------------
  // Path A: Daily Operations Log (4 Accordion Sections)
  // ----------------------------------------------------
  Widget _buildPathADailyOpsBundle() {
    final bundleChips = [
      _BundleChipItem('Feed', LogRecordType.feed, _isFeedValid, 0),
      _BundleChipItem('Water', LogRecordType.water, _isWaterValid, 1),
      _BundleChipItem('Mortality', LogRecordType.mortality, _isMortalityValid, 2),
      _BundleChipItem('DG Gen', LogRecordType.dg, _isDgValid, 3),
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 2 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Daily Operations Telemetry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Fill in the 4 daily metrics below. Sections auto-advance.',
                      style: TextStyle(fontSize: 13, height: 1.3, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Step 2 of 2',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "Same as Yesterday" Shortcut Button (Item 3)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _copyYesterdayValues,
              icon: const Icon(Icons.history_rounded, size: 17, color: AppColors.primary),
              label: const Text(
                "Copy yesterday's values",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFFF0FDF4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sticky Progress Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bundleChips.map((chip) {
                final isCurrent = _expandedSectionIndex == chip.index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _expandedSectionIndex = chip.index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: chip.isValid
                            ? const Color(0xFFECFDF5)
                            : (isCurrent ? chip.type.bgTint : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: chip.isValid
                              ? AppColors.primary
                              : (isCurrent ? chip.type.accentColor : const Color(0xFFCBD5E1)),
                          width: isCurrent || chip.isValid ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(chip.type.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            chip.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent || chip.isValid ? FontWeight.bold : FontWeight.w500,
                              color: chip.isValid
                                  ? AppColors.primary
                                  : (isCurrent ? chip.type.accentColor : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (chip.isValid)
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary)
                          else
                            const Icon(Icons.circle_outlined, size: 12, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Accordion Sections
          _buildAccordionSection(
            index: 0,
            type: LogRecordType.feed,
            isValid: _isFeedValid,
            content: _buildFeedFields(isBundle: true),
          ),
          const SizedBox(height: 10),

          _buildAccordionSection(
            index: 1,
            type: LogRecordType.water,
            isValid: _isWaterValid,
            content: _buildWaterFields(isBundle: true),
          ),
          const SizedBox(height: 10),

          _buildAccordionSection(
            index: 2,
            type: LogRecordType.mortality,
            isValid: _isMortalityValid,
            content: _buildMortalityFields(isBundle: true),
          ),
          const SizedBox(height: 10),

          _buildAccordionSection(
            index: 3,
            type: LogRecordType.dg,
            isValid: _isDgValid,
            content: _buildDgFields(isBundle: true),
          ),
          const SizedBox(height: 20),

          // Review Section (Neutral grey/white card style with live updating values)
          _buildPathABundleReviewCard(),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required int index,
    required LogRecordType type,
    required bool isValid,
    required Widget content,
  }) {
    final isExpanded = _expandedSectionIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isExpanded ? type.bgTint.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? type.accentColor
              : (isValid ? AppColors.primary : const Color(0xFFE2E8F0)),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? type.accentColor.withValues(alpha: 0.08) : const Color(0x04000000),
            blurRadius: isExpanded ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: isExpanded
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: type.accentColor,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Collapsed Header Row
          InkWell(
            onTap: () {
              setState(() {
                _expandedSectionIndex = isExpanded ? -1 : index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: type.bgTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        type.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? type.accentColor : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isValid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Complete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                    ],
                  ),
                  if (isValid && !isExpanded)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                  else
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? type.accentColor : const Color(0xFF94A3B8),
                    ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: content,
            ),
          ],
        ],
      ),
    ),
  ),
);
}

  // ----------------------------------------------------
  // Path B: Optional Category (Form + Review on one scrollable page)
  // ----------------------------------------------------
  Widget _buildPathBOptionalCategory() {
    final type = _selectedOptionalType ?? LogRecordType.medicine;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 2 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${type.title} Log Entry',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.subtitle,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Step 2 of 2',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Hero Header & "Repeat Last"
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: type.bgTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: type.accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(type.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      type.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: type.accentColor,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _repeatPreviousDayRecord,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: type.accentColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 14, color: type.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Repeat Last',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: type.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Category Specific Form Fields
          if (type == LogRecordType.medicine) _buildMedicineFields(),
          if (type == LogRecordType.vaccine) _buildVaccineFields(),
          if (type == LogRecordType.weight) _buildWeightFields(),
          if (type == LogRecordType.notes) _buildNotesFields(),
          const SizedBox(height: 20),

          // Live Review Card below
          _buildPathBOptionalReviewCard(type),
        ],
      ),
    );
  }

  // ==========================================
  // FIELD BUILDERS & PRESETS
  // ==========================================

  // Feed Fields
  Widget _buildFeedFields({bool isBundle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickPresetsRow(
          ['+10 kg', '+25 kg', '+50 kg', '+1 Bag (50kg)'],
          [10, 25, 50, 50],
          _feedQuantityController,
        ),
        DropdownButtonFormField<String>(
          initialValue: _feedTypeController.text.isNotEmpty ? _feedTypeController.text : 'Broiler Starter',
          decoration: _fieldDecoration('Feed Type', Icons.grass_outlined),
          items: const [
            DropdownMenuItem(value: 'Broiler Starter', child: Text('Broiler Starter')),
            DropdownMenuItem(value: 'Broiler Grower', child: Text('Broiler Grower')),
            DropdownMenuItem(value: 'Broiler Finisher', child: Text('Broiler Finisher')),
            DropdownMenuItem(value: 'Pre-Starter', child: Text('Pre-Starter')),
            DropdownMenuItem(value: 'Other Custom Feed', child: Text('Other Custom Feed')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _feedTypeController.text = val);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _feedQuantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Quantity Consumed *', Icons.scale_outlined),
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _feedUnit,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'bags', child: Text('bags (50kg)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _feedUnit = v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _feedCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration('Total Feed Cost (₹) Optional', Icons.currency_rupee_rounded),
          onChanged: (_) => setState(() {}),
        ),
        if (isBundle) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _expandedSectionIndex = 1);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next: Water Intake'),
            ),
          ),
        ],
      ],
    );
  }

  // Water Fields
  Widget _buildWaterFields({bool isBundle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickPresetsRow(
          ['+50 L', '+100 L', '+250 L', '+500 L'],
          [50, 100, 250, 500],
          _waterQuantityController,
        ),
        TextFormField(
          controller: _waterQuantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration('Water Consumed (Liters) *', Icons.water_drop_outlined),
          onChanged: (_) => setState(() {}),
          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _waterSourceController,
          decoration: _fieldDecoration('Water Source (Borewell / Pipeline)', Icons.source_outlined),
          onChanged: (_) => setState(() {}),
        ),
        if (isBundle) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _expandedSectionIndex = 2);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next: Mortality'),
            ),
          ),
        ],
      ],
    );
  }

  // Mortality Fields
  Widget _buildMortalityFields({bool isBundle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickPresetsRow(
          ['+1', '+2', '+5', '+10'],
          [1, 2, 5, 10],
          _mortalityCountController,
        ),
        _buildStepperField(
          label: 'Mortality Bird Count * (Enter 0 if none)',
          icon: Icons.sick_outlined,
          controller: _mortalityCountController,
          step: 1,
          min: 0,
          isDecimal: false,
          suffix: 'birds',
          hintText: '0',
          isRequired: true,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mortalityReasonController,
          decoration: _fieldDecoration('Cause of Mortality (Heat, Weak, Natural)', Icons.report_problem_outlined),
          onChanged: (_) => setState(() {}),
        ),
        if (isBundle) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _expandedSectionIndex = 3);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next: DG Generator'),
            ),
          ),
        ],
      ],
    );
  }

  // DG Generator Fields
  Widget _buildDgFields({bool isBundle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickPresetsRow(
          ['+5 L', '+10 L', '+20 L', '+50 L'],
          [5, 10, 20, 50],
          _dgAddedController,
        ),
        _buildStepperField(
          label: 'Diesel Level (Liters) *',
          icon: Icons.local_gas_station_outlined,
          controller: _dgLevelController,
          step: 10,
          min: 0,
          isDecimal: true,
          suffix: 'L',
          hintText: 'e.g. 100',
          isRequired: true,
        ),
        const SizedBox(height: 12),
        _buildStepperField(
          label: 'Diesel Added Today (Liters)',
          icon: Icons.add_circle_outline,
          controller: _dgAddedController,
          step: 5,
          min: 0,
          isDecimal: true,
          suffix: 'L',
          hintText: 'e.g. 20',
        ),
        const SizedBox(height: 12),
        _buildStepperField(
          label: 'Running Hours Today',
          icon: Icons.timer_outlined,
          controller: _dgHoursController,
          step: 1,
          min: 0,
          isDecimal: true,
          suffix: 'hrs',
          hintText: 'e.g. 2',
        ),
      ],
    );
  }

  // Medicine Fields
  Widget _buildMedicineFields() {
    return Column(
      children: [
        TextFormField(
          controller: _medicineNameController,
          decoration: _fieldDecoration('Medicine / Supplement Name *', Icons.medication_outlined),
          onChanged: (_) => setState(() {}),
          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _medicineQuantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Quantity (ml/g) *', Icons.numbers_outlined),
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _medicineCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Cost (₹)', Icons.currency_rupee_rounded),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _medicinePurposeController,
          decoration: _fieldDecoration('Purpose / Symptoms (e.g. Coughing, Immunity)', Icons.healing_outlined),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // Vaccine Fields
  Widget _buildVaccineFields() {
    return Column(
      children: [
        TextFormField(
          controller: _vaccineNameController,
          decoration: _fieldDecoration('Vaccine Name * (e.g. Lasota / Gumboro)', Icons.vaccines_outlined),
          onChanged: (_) => setState(() {}),
          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vaccineDoseController,
          decoration: _fieldDecoration('Dose Route (Eye drop, Drinking water)', Icons.local_hospital_outlined),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vaccineBatchNumController,
          decoration: _fieldDecoration('Vaccine Batch # / Expiry Date', Icons.tag_outlined),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // Weight Fields
  Widget _buildWeightFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightAvgGramsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('Avg Weight (Grams) *', Icons.scale_outlined),
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _weightSampleCountController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('Sample Birds Count', Icons.groups_outlined),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _weightNotesController,
          decoration: _fieldDecoration('Weight Notes / FCR Observations', Icons.notes_outlined),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // Notes Fields
  Widget _buildNotesFields() {
    return Column(
      children: [
        TextFormField(
          controller: _notesTitleController,
          decoration: _fieldDecoration('Note Title (e.g. Shed Inspection)', Icons.title_outlined),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesDescController,
          maxLines: 3,
          decoration: _fieldDecoration('Detailed Observations / Issues *', Icons.description_outlined),
          onChanged: (_) => setState(() {}),
          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  // ==========================================
  // REVIEW CARDS
  // ==========================================

  // Path A: Bundle Summary Review
  Widget _buildPathABundleReviewCard() {
    final feedQty = _feedQuantityController.text.trim();
    final waterQty = _waterQuantityController.text.trim();
    final mortQty = _mortalityCountController.text.trim();
    final dgLevel = _dgLevelController.text.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.checklist_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Live Telemetry Review',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReviewRow('🌾 Feed Intake', feedQty.isNotEmpty ? '$feedQty $_feedUnit (${_feedTypeController.text})' : 'Pending...'),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _buildReviewRow('💧 Water Intake', waterQty.isNotEmpty ? '$waterQty Liters (${_waterSourceController.text})' : 'Pending...'),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _buildReviewRow('☠️ Mortality', mortQty.isNotEmpty ? '$mortQty birds' : 'Pending...'),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          _buildReviewRow('⚡ DG Generator', dgLevel.isNotEmpty ? '$dgLevel L level' : 'Pending...'),
        ],
      ),
    );
  }

  // Path B: Single Optional Category Review
  Widget _buildPathBOptionalReviewCard(LogRecordType type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: type.accentColor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '${type.title} Summary Review',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: type.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (type == LogRecordType.medicine) ...[
            _buildReviewRow('Medicine Name', _medicineNameController.text.isNotEmpty ? _medicineNameController.text : 'Pending...'),
            const Divider(height: 12, color: Color(0xFFF1F5F9)),
            _buildReviewRow('Quantity', _medicineQuantityController.text.isNotEmpty ? '${_medicineQuantityController.text} ml/g' : 'Pending...'),
          ],
          if (type == LogRecordType.vaccine) ...[
            _buildReviewRow('Vaccine Name', _vaccineNameController.text.isNotEmpty ? _vaccineNameController.text : 'Pending...'),
            const Divider(height: 12, color: Color(0xFFF1F5F9)),
            _buildReviewRow('Dose', _vaccineDoseController.text.isNotEmpty ? _vaccineDoseController.text : 'Standard'),
          ],
          if (type == LogRecordType.weight) ...[
            _buildReviewRow('Avg Weight', _weightAvgGramsController.text.isNotEmpty ? '${_weightAvgGramsController.text} grams' : 'Pending...'),
            const Divider(height: 12, color: Color(0xFFF1F5F9)),
            _buildReviewRow('Sample Count', _weightSampleCountController.text.isNotEmpty ? '${_weightSampleCountController.text} birds' : 'All birds'),
          ],
          if (type == LogRecordType.notes) ...[
            _buildReviewRow('Observation', _notesDescController.text.isNotEmpty ? _notesDescController.text : 'Pending...'),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // RECENT RECORDS SECTION
  // ==========================================
  Widget _buildRecentRecordsSection(List<DailyRecordModel> records) {
    final recent5 = records.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT TELEMETRY LOGS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.1),
            ),
            Text(
              '${records.length} records',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent5.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: const [
                Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'No recent telemetry records logged yet',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF5EA),
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
                          const SizedBox(height: 2),
                          Text(
                            'Day ${r.batchAgeDay} • ${r.closingBirds} Birds Remaining',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (r.feedConsumedKg > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('🌾 ${r.feedConsumedKg} kg', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      )
                    else if (r.mortalityCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('☠️ ${r.mortalityCount} dead', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      )
                    else if (r.waterConsumedLiters > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('💧 ${r.waterConsumedLiters} L', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      )
                    else if (r.medicineGiven)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('💊 Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                      )
                    else if (r.vaccineGiven)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('💉 Vaccine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationControls() {
    final canSave = _isDailyOpsSelected ? _isAllBundleValid : _isOptionalValid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
              label: const Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep == 0)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x25059669),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextStep,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Continue to Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: canSave && !_isSaving
                    ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)])
                    : const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: canSave
                    ? const [
                        BoxShadow(
                          color: Color(0x25059669),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canSave && !_isSaving ? _saveRecord : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSaving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirm & Save Entry',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildStepperField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    double step = 1.0,
    double min = 0.0,
    bool isDecimal = false,
    String? suffix,
    String? hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // [ – ] Button (Min 48x48dp touch target)
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                    onTap: () {
                      final current = double.tryParse(controller.text.trim()) ?? 0.0;
                      final updated = (current - step).clamp(min, double.infinity);
                      setState(() {
                        controller.text = isDecimal
                            ? (updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(1))
                            : updated.toInt().toString();
                      });
                    },
                    child: const Center(
                      child: Icon(Icons.remove_rounded, size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
                child: VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
              ),
              // Direct Tap-to-type Text Input in Center
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText ?? '0',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                    suffixText: suffix,
                    suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: isRequired
                      ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
                      : null,
                ),
              ),
              const SizedBox(
                height: 24,
                child: VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
              ),
              // [ + ] Button (Min 48x48dp touch target)
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(13)),
                    onTap: () {
                      final current = double.tryParse(controller.text.trim()) ?? 0.0;
                      final updated = current + step;
                      setState(() {
                        controller.text = isDecimal
                            ? (updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(1))
                            : updated.toInt().toString();
                      });
                    },
                    child: const Center(
                      child: Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPresetsRow(
    List<String> labels,
    List<double> values,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final current = double.tryParse(controller.text.trim()) ?? 0.0;
                    final updated = current + values[i];
                    setState(() {
                      controller.text = updated % 1 == 0
                          ? updated.toInt().toString()
                          : updated.toStringAsFixed(1);
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            labels[i],
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BundleChipItem {
  final String label;
  final LogRecordType type;
  final bool isValid;
  final int index;

  _BundleChipItem(this.label, this.type, this.isValid, this.index);
}
