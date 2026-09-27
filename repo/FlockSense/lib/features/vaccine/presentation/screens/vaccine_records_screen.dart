import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_form_screen.dart';

class VaccineRecordsScreen extends ConsumerStatefulWidget {
  const VaccineRecordsScreen({
    super.key,
    this.farmId,
    this.batchId,
    this.batchName,
  });

  final String? farmId;
  final String? batchId;
  final String? batchName;

  @override
  ConsumerState<VaccineRecordsScreen> createState() =>
      _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends ConsumerState<VaccineRecordsScreen> {
  String? _selectedFarmId;
  String? _selectedBatchId;
  String? _selectedBatchName;

  @override
  void initState() {
    super.initState();
    _selectedFarmId = widget.farmId;
    _selectedBatchId = widget.batchId;
    _selectedBatchName = widget.batchName;
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmListProvider);
    final batchesAsync = ref.watch(allUserBatchesProvider);

    final farms = farmsAsync.value ?? <FarmModel>[];
    final batches = batchesAsync.value ?? <BatchModel>[];

    // If context was not pre-set via widget params, auto-select first available active batch
    if ((_selectedFarmId == null || _selectedBatchId == null) &&
        batches.isNotEmpty) {
      final activeBatches = batches.where((b) => b.isActive).toList();
      final defaultBatch = activeBatches.isNotEmpty
          ? activeBatches.first
          : batches.first;

      _selectedFarmId = defaultBatch.farmId;
      _selectedBatchId = defaultBatch.id;
      _selectedBatchName = defaultBatch.batchName;
    }

    final hasContext = (_selectedFarmId?.isNotEmpty ?? false) &&
        (_selectedBatchId?.isNotEmpty ?? false);

    // If user has no farms at all
    if (farmsAsync.hasValue && farms.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Vaccination'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Farms Registered',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a farm and batch to start logging vaccination doses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FarmSetupScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Farm'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If user has farms but no batches
    if (batchesAsync.hasValue && batches.isEmpty && farms.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Vaccination'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pets,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Batches Placed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Place your first batch of birds to schedule and record vaccinations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchFormScreen(farmId: farms.first.id),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Place Batch'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeBatch = batches.where((b) => b.id == _selectedBatchId).firstOrNull;
    final int currentAgeDays = activeBatch != null
        ? DateTime.now().difference(activeBatch.placementDate).inDays + 1
        : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedBatchName == null
              ? 'Vaccination'
              : 'Vaccination • $_selectedBatchName',
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selector header when multiple batches exist
          if (batches.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Active Batch:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBatchId,
                        isExpanded: true,
                        items: batches.map((b) {
                          final farmName = farms
                              .where((f) => f.id == b.farmId)
                              .firstOrNull
                              ?.farmName;
                          final prefix = farmName != null ? '$farmName • ' : '';
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(
                              '$prefix${b.batchName}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newBatchId) {
                          if (newBatchId == null) return;
                          final b = batches.where((x) => x.id == newBatchId).firstOrNull;
                          if (b != null) {
                            setState(() {
                              _selectedBatchId = b.id;
                              _selectedFarmId = b.farmId;
                              _selectedBatchName = b.batchName;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: !hasContext
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : StreamBuilder<List<VaccineRecordModel>>(
                    stream: VaccineService.watchVaccineRecords(
                      _selectedFarmId!,
                      _selectedBatchId!,
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

                      final records = snapshot.data ?? <VaccineRecordModel>[];
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
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.vaccines_outlined,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No vaccine records',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Log the first vaccine dose for this batch to ensure flock immunization.',
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
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.vaccines_outlined,
                                    color: AppColors.surface,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.vaccineName,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    record.route,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: hasContext
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VaccineFormScreen(
                    farmId: _selectedFarmId!,
                    batchId: _selectedBatchId!,
                    currentBatchAge: currentAgeDays,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Vaccine'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
