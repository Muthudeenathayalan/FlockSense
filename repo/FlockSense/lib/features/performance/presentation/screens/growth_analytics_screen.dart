import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/cached_async.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';

enum GrowthAnalyticsDateRange { last7Days, last30Days, batchLifetime }

/// Stream provider for daily records filtered by farm and batch.
final _growthRecordsProvider = StreamProvider.autoDispose
    .family<List<DailyRecordModel>, String>((ref, key) {
  final parts = key.split('|');
  final farmId = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
  final batchId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  return DailyRecordService.watchUserDailyRecords(farmId: farmId, batchId: batchId);
});

final _growthKpisProvider = Provider.family<GrowthKpis, GrowthKpiInput>((ref, input) => GrowthKpis.compute(input));

class GrowthAnalyticsScreen extends ConsumerStatefulWidget {
  const GrowthAnalyticsScreen({super.key});

  @override
  ConsumerState<GrowthAnalyticsScreen> createState() =>
      _GrowthAnalyticsScreenState();
}

// KPI input wrapper for provider family
class GrowthKpiInput {
  final List<DailyRecordModel> records;
  final int? initialBirds;
  GrowthKpiInput(this.records, this.initialBirds);
}

class GrowthKpis {
  GrowthKpis({
    required this.currentBirds,
    required this.avgWeightGrams,
    required this.weightGainGrams,
    required this.dailyWeightGainGrams,
    required this.mortalityRatePct,
    required this.feedConsumedKg,
    required this.fcr,
    required this.valid,
  });

  final int? currentBirds;
  final double? avgWeightGrams;
  final double? weightGainGrams;
  final double? dailyWeightGainGrams;
  final double? mortalityRatePct;
  final double? feedConsumedKg;
  final double? fcr;
  final bool valid;

  String displayInt(int? v) => v == null ? 'Unavailable' : '$v';
  String displayGram(double? g) => g == null ? 'Unavailable' : '${g.toStringAsFixed(0)} g';
  String displayKg(double? k) => k == null ? 'Unavailable' : '${k.toStringAsFixed(1)} kg';
  String displayPct(double? p) => p == null ? 'Unavailable' : '${p.toStringAsFixed(1)}%';
  String displayNumber(double? v) => v == null ? 'Unavailable' : v.isFinite ? v.toStringAsFixed(2) : 'Unavailable';

  static GrowthKpis compute(GrowthKpiInput input) {
    final raw = input.records;
    if (raw.isEmpty) return GrowthKpis(currentBirds: null, avgWeightGrams: null, weightGainGrams: null, dailyWeightGainGrams: null, mortalityRatePct: null, feedConsumedKg: null, fcr: null, valid: false);

    // Deduplicate by recordDate ISO string
    final map = <String, DailyRecordModel>{};
    for (final r in raw) {
      final key = r.recordDate.toIso8601String();
      final existing = map[key];
      if (existing == null || r.updatedAt.isAfter(existing.updatedAt)) {
        map[key] = r;
      }
    }
    final records = map.values.toList()..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final initialBirds = input.initialBirds;
    int totalMortality = 0;
    double feedSum = 0.0;
    final weightList = <DailyRecordModel>[];
    for (final r in records) {
      totalMortality += (r.mortalityCount < 0 ? 0 : r.mortalityCount) + (r.cullCount < 0 ? 0 : r.cullCount);
      feedSum += (r.feedConsumedKg.isFinite ? r.feedConsumedKg : 0.0);
      if (r.avgWeightGrams > 0) weightList.add(r);
    }

    final currentBirds = initialBirds != null ? (initialBirds - totalMortality).clamp(0, 1 << 30) : null;

    double? avgWeight;
    if (weightList.isNotEmpty) {
      final vals = weightList.map((r) => r.avgWeightGrams).where((v) => v > 0).toList();
      if (vals.isNotEmpty) {
        avgWeight = vals.reduce((a, b) => a + b) / vals.length;
      }
    }

    double? weightGain;
    double? dailyGain;
    if (weightList.length >= 2) {
      final first = weightList.first.avgWeightGrams;
      final last = weightList.last.avgWeightGrams;
      if (first.isFinite && last.isFinite) {
        weightGain = last - first;
        final days = weightList.last.batchAgeDay - weightList.first.batchAgeDay;
        if (days > 0) {
          dailyGain = weightGain / days;
        }
      }
    }

    double? mortalityRate;
    if (initialBirds != null && initialBirds > 0) {
      mortalityRate = totalMortality / initialBirds * 100;
    }

    double? fcr;
    if (weightGain != null && weightGain > 0 && currentBirds != null && currentBirds > 0) {
      final liveWeightGainKg = (weightGain / 1000.0) * currentBirds;
      if (liveWeightGainKg > 0) {
        fcr = feedSum / liveWeightGainKg;
      }
    }

    return GrowthKpis(
      currentBirds: currentBirds,
      avgWeightGrams: avgWeight,
      weightGainGrams: (weightGain != null && weightGain.isFinite) ? weightGain : null,
      dailyWeightGainGrams: (dailyGain != null && dailyGain.isFinite) ? dailyGain : null,
      mortalityRatePct: (mortalityRate != null && mortalityRate.isFinite) ? mortalityRate : null,
      feedConsumedKg: feedSum.isFinite && feedSum > 0 ? feedSum : null,
      fcr: (fcr != null && fcr.isFinite) ? fcr : null,
      valid: true,
    );
  }
}

class _GrowthAnalyticsScreenState extends ConsumerState<GrowthAnalyticsScreen> {
  String? _selectedFarmId;
  String? _selectedBatchId;
  GrowthAnalyticsDateRange _dateRange = GrowthAnalyticsDateRange.last30Days;
  bool _isExporting = false;
  List<DailyRecordModel>? _cachedRecords;

  void _selectFarm(String? farmId) {
    setState(() {
      _selectedFarmId = farmId;
      _selectedBatchId = null;
      _cachedRecords = null;
    });
  }

  void _selectBatch(String? batchId) {
    setState(() {
      _selectedBatchId = batchId;
      _cachedRecords = null;
    });
  }

  void _selectDateRange(GrowthAnalyticsDateRange option) {
    setState(() {
      _dateRange = option;
    });
  }

  int? get _dateRangeDays {
    switch (_dateRange) {
      case GrowthAnalyticsDateRange.last7Days:
        return 7;
      case GrowthAnalyticsDateRange.last30Days:
        return 30;
      case GrowthAnalyticsDateRange.batchLifetime:
        return null;
    }
  }

  String _dateRangeLabel(GrowthAnalyticsDateRange option) {
    switch (option) {
      case GrowthAnalyticsDateRange.last7Days:
        return '7 days';
      case GrowthAnalyticsDateRange.last30Days:
        return '30 days';
      case GrowthAnalyticsDateRange.batchLifetime:
        return 'Batch lifetime';
    }
  }

  List<DailyRecordModel> _applyDateFilter(List<DailyRecordModel> records) {
    final days = _dateRangeDays;
    if (days == null || records.isEmpty) return records;

    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records
        .where((record) => record.recordDate.isAfter(cutoff))
          .toList();
        }

        String _batchDisplayName(BatchModel batch, Map<String, String> farmNames) {
    final farmName = farmNames[batch.farmId];
    if (farmName == null || farmName.isEmpty) return batch.batchName;
    return '${batch.batchName} • $farmName';
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmListProvider);
    final batchesAsync = ref.watch(batchListProvider(_selectedFarmId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Growth Analytics'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: farmsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => _buildErrorState('Unable to load farms'),
          data: (farms) {
            final farmNames = {
              for (final farm in farms) farm.id: farm.farmName,
            };
            return batchesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => _buildErrorState('Unable to load batches'),
              data: (batches) {
                BatchModel? selectedBatch;
                for (final batch in batches) {
                  if (batch.id == _selectedBatchId) {
                    selectedBatch = batch;
                    break;
                  }
                }
                final batchOptions = [...batches]
                  ..sort(
                    (a, b) => _batchDisplayName(
                      a,
                      farmNames,
                    ).compareTo(_batchDisplayName(b, farmNames)),
                  );

                final streamFarmId = selectedBatch?.farmId ?? _selectedFarmId;
                final recordsKey = '${streamFarmId ?? ''}|${_selectedBatchId ?? ''}';
                final recordsAsync = ref.watch(_growthRecordsProvider(recordsKey));

                final previousRecords = _cachedRecords;
                return CachedAsync<List<DailyRecordModel>>(
                  value: recordsAsync,
                  cached: previousRecords,
                  loading: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFilterCard(
                          farms,
                          batchOptions,
                          farmNames,
                          selectedBatch,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: _buildExportRow(selectedBatch),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 12),
                              Text('Loading growth analytics...'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  error: (err, __) => CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFilterCard(
                          farms,
                          batchOptions,
                          farmNames,
                          selectedBatch,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: _buildExportRow(selectedBatch),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState('Unable to load analytics data'),
                      ),
                    ],
                  ),
                  data: (rawRecords) {
                    final records = _applyDateFilter(rawRecords)
                      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
                    _cachedRecords = records;

                    if (records.isEmpty) {
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildFilterCard(
                              farms,
                              batchOptions,
                              farmNames,
                              selectedBatch,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                          SliverToBoxAdapter(
                            child: _buildExportRow(selectedBatch),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  selectedBatch == null
                                      ? 'No records were found. Select a farm and batch to view growth analytics.'
                                      : 'No records were found for ${selectedBatch.batchName}.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildFilterCard(
                            farms,
                            batchOptions,
                            farmNames,
                            selectedBatch,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        SliverToBoxAdapter(
                          child: _buildExportRow(selectedBatch),
                        ),
                        SliverToBoxAdapter(child: const SizedBox(height: 14)),
                        SliverToBoxAdapter(
                          child: _buildAnalyticsContent(
                            records,
                            selectedBatch,
                            batchOptions,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    List<FarmModel> farms,
    List<BatchModel> batchOptions,
    Map<String, String> farmNames,
    BatchModel? selectedBatch,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedFarmId,
                    decoration: const InputDecoration(
                      labelText: 'Farm',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All farms'),
                      ),
                      ...farms.map((farm) {
                        return DropdownMenuItem(
                          value: farm.id,
                          child: Text(farm.farmName),
                        );
                      }),
                    ],
                    onChanged: (value) => _selectFarm(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              value: _selectedBatchId,
              decoration: const InputDecoration(
                labelText: 'Batch',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All batches')),
                ...batchOptions.map((batch) {
                  return DropdownMenuItem(
                    value: batch.id,
                    child: Text(_batchDisplayName(batch, farmNames)),
                  );
                }),
              ],
              onChanged: batchOptions.isEmpty
                  ? null
                  : (value) => _selectBatch(value),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: GrowthAnalyticsDateRange.values.map((option) {
                final selected = option == _dateRange;
                return ChoiceChip(
                  label: Text(_dateRangeLabel(option)),
                  selected: selected,
                  onSelected: (_) => _selectDateRange(option),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceSoft,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            if (selectedBatch != null) ...[
              const SizedBox(height: 12),
              Text(
                'Showing analytics for ${selectedBatch.batchName}.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    List<DailyRecordModel> records,
    BatchModel? selectedBatch,
    List<BatchModel> batchOptions,
  ) {
    final totalBirds =
        selectedBatch?.totalBirds ??
        batchOptions.fold<int>(0, (sum, batch) => sum + batch.totalBirds);
    final kpiInput = GrowthKpiInput(records, totalBirds > 0 ? totalBirds : null);
    final kpis = ref.watch(_growthKpisProvider(kpiInput));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _kpiCard(
            label: 'Current Birds',
            value: kpis.currentBirds == null ? 'Unavailable' : '${kpis.currentBirds}',
            icon: Icons.pets,
            gradient: AppColors.primaryGradient,
          ),
          _kpiCard(
            label: 'Average Weight',
            value: kpis.avgWeightGrams == null ? 'Unavailable' : '${kpis.avgWeightGrams!.toStringAsFixed(0)} g',
            icon: Icons.monitor_weight_outlined,
            gradient: AppColors.goldGradient,
          ),
          _kpiCard(
            label: 'Weight Gain',
            value: kpis.weightGainGrams == null ? 'Insufficient data' : '${kpis.weightGainGrams!.toStringAsFixed(0)} g',
            icon: Icons.trending_up,
            gradient: AppColors.primaryGradient,
          ),
          _kpiCard(
            label: 'Daily Weight Gain',
            value: kpis.dailyWeightGainGrams == null ? 'Insufficient data' : '${kpis.dailyWeightGainGrams!.toStringAsFixed(2)} g/day',
            icon: Icons.calendar_view_day,
            gradient: AppColors.cardGradient,
          ),
          _kpiCard(
            label: 'Mortality Rate',
            value: kpis.mortalityRatePct == null ? 'Unavailable' : '${kpis.mortalityRatePct!.toStringAsFixed(1)}%',
            icon: Icons.warning_amber_outlined,
            gradient: (kpis.mortalityRatePct ?? 0) > 3 ? AppColors.dangerGradient : AppColors.emeraldGradient,
          ),
          _kpiCard(
            label: 'Feed Consumed',
            value: kpis.feedConsumedKg == null ? 'Unavailable' : '${kpis.feedConsumedKg!.toStringAsFixed(1)} kg',
            icon: Icons.grass,
            gradient: AppColors.primaryGradient,
          ),
          _kpiCard(
            label: 'FCR',
            value: kpis.fcr == null ? 'Unavailable' : kpis.fcr!.isFinite ? kpis.fcr!.toStringAsFixed(2) : 'Unavailable',
            icon: Icons.show_chart,
            gradient: (kpis.fcr ?? 0) > 1.7 ? AppColors.dangerGradient : AppColors.primaryGradient,
          ),
        ],
      ),
    );
  }

  Future<double?> _loadProfit(BatchModel batch) async {
    final feedSummary = await FeedService.calculateFeedSummary(
      farmId: batch.farmId,
      batchId: batch.id,
    );
    final sales = await SalesService.getBirdSales(
      farmId: batch.farmId,
      batchId: batch.id,
    );
    if (sales.isEmpty) return null;
    final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.totalValue);
    return revenue - feedSummary.totalFeedCost;
  }

  Widget _buildProfitCard(BatchModel? selectedBatch) {
    if (selectedBatch == null) {
      return _kpiCard(
        label: 'Profit',
        value: 'Select batch',
        icon: Icons.money,
        gradient: AppColors.cardGradient,
      );
    }

    return FutureBuilder<double?>(
      future: _loadProfit(selectedBatch),
      builder: (context, snapshot) {
        final value = snapshot.connectionState == ConnectionState.waiting
            ? 'Loading…'
            : snapshot.hasError
            ? 'Error'
            : snapshot.data == null
            ? 'No sales'
            : '₹${snapshot.data!.toStringAsFixed(0)}';
        return _kpiCard(
          label: 'Profit',
          value: value,
          icon: Icons.attach_money,
          gradient: AppColors.primaryGradient,
        );
      },
    );
  }

  Widget _buildExportRow(BatchModel? selectedBatch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBatch != null
                        ? () => _exportPdf(selectedBatch)
                        : null,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBatch != null
                        ? () => _exportCsv(selectedBatch)
                        : null,
                    icon: const Icon(Icons.file_download),
                    label: const Text('CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBatch != null
                        ? () => _exportExcel(selectedBatch)
                        : null,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
            if (_isExporting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    List<DailyRecordModel> records,
    BatchModel? selectedBatch,
    List<BatchModel> batchOptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCards(records, selectedBatch, batchOptions),
        const SizedBox(height: 12),
        _buildProfitCard(selectedBatch),
        const SizedBox(height: 12),
        _buildWeightChart(records, selectedBatch),
        const SizedBox(height: 12),
        _buildDailyWeightGainChart(records),
        const SizedBox(height: 12),
        _buildFeedChart(records),
        const SizedBox(height: 12),
        _buildMortalityChart(records, selectedBatch, batchOptions),
        const SizedBox(height: 12),
        _buildBatchComparisonChart(records, batchOptions),
        const SizedBox(height: 12),
        _buildPerformanceAnalysis(records, selectedBatch, batchOptions),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _exportPdf(BatchModel batch) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final data = await ReportService.loadReportData(
        farmId: batch.farmId,
        batchId: batch.id,
      );
      final bytes = await PdfGenerator.generateFarmRecord(data);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'growth_analytics_${batch.batchName}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export PDF: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv(BatchModel batch) async {
    try {
      final records = await DailyRecordService.getAllDailyRecords(
        farmId: batch.farmId,
        batchId: batch.id,
      );
      final csv = _buildCsv(records, batch);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final file = XFile.fromData(
        bytes,
        mimeType: 'text/csv',
        name: 'growth_analytics_${batch.batchName}.csv',
      );
      await Share.shareXFiles([
        file,
      ], text: 'Growth Analytics data for ${batch.batchName}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export CSV: ${e.toString()}')),
      );
    }
  }

  Future<void> _exportExcel(BatchModel batch) async {
    try {
      final records = await DailyRecordService.getAllDailyRecords(
        farmId: batch.farmId,
        batchId: batch.id,
      );
      final csv = _buildCsv(records, batch);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/vnd.ms-excel',
        name: 'growth_analytics_${batch.batchName}.xlsx',
      );
      await Share.shareXFiles([
        file,
      ], text: 'Growth Analytics data for ${batch.batchName}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export Excel: ${e.toString()}')),
      );
    }
  }

  String _buildCsv(List<DailyRecordModel> records, BatchModel batch) {
    final header = [
      'Batch',
      'Date',
      'Age Day',
      'Opening Birds',
      'Mortality',
      'Cull Count',
      'Closing Birds',
      'Feed Kg',
      'Water L',
      'Avg Weight g',
    ];
    final rows = records
        .map((record) {
          return [
                batch.batchName,
                record.recordDate.toIso8601String(),
                record.batchAgeDay,
                record.openingBirds,
                record.mortalityCount,
                record.cullCount,
                record.closingBirds,
                record.feedConsumedKg.toStringAsFixed(2),
                record.waterConsumedLiters.toStringAsFixed(2),
                record.avgWeightGrams.toStringAsFixed(0),
              ]
              .map((value) => '"${value.toString().replaceAll('"', '""')}"')
              .join(',');
        })
        .join('\n');
    return '${header.join(',')}\n$rows';
  }

  Widget _buildFeedChart(List<DailyRecordModel> records) {
    // Use recordDate (ms since epoch) as x axis so charts show actual dates.
    final feedSpots = records
        .where((record) => record.feedConsumedKg > 0)
        .map((record) => FlSpot(record.recordDate.millisecondsSinceEpoch.toDouble(), record.feedConsumedKg))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    final maxFeed = math.max(1.0, feedSpots.isEmpty ? 0.0 : feedSpots.map((s) => s.y).reduce(math.max) + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Feed Consumption',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daily feed consumed per batch age day',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: feedSpots.length < 2
                  ? const Center(
                      child: Text(
                        'Not enough data to display this chart.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: feedSpots.first.x,
                        maxX: feedSpots.last.x,
                        minY: 0,
                        maxY: maxFeed,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxFeed / 4,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.border,
                            strokeWidth: 0.8,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.border),
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: maxFeed / 4,
                              getTitlesWidget: (value, _) => Text(
                                '${value.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: (feedSpots.last.x - feedSpots.first.x) / 4,
                              getTitlesWidget: (value, _) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Text(
                                  '${dt.month}/${dt.day}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: feedSpots,
                            isCurved: true,
                            color: AppColors.warning,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                radius: 3,
                                color: AppColors.warning,
                                strokeColor: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.warning.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((spot) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                              return LineTooltipItem(
                                '${dt.month}/${dt.day}/${dt.year}\nFeed: ${spot.y.toStringAsFixed(2)} kg',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart(
    List<DailyRecordModel> records,
    BatchModel? selectedBatch,
  ) {
    final weightSpots = records
        .where((record) => record.avgWeightGrams > 0)
        .map((record) => FlSpot(record.recordDate.millisecondsSinceEpoch.toDouble(), record.avgWeightGrams))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    final maxWeight = math.max(500.0, weightSpots.isEmpty ? 0.0 : weightSpots.map((s) => s.y).reduce(math.max) + 200);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Growth Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedBatch != null
                  ? 'Average weight by batch age day'
                  : 'Weight trend across selected records',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: weightSpots.length < 2
                  ? const Center(
                      child: Text(
                        'Not enough data to display this chart.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: weightSpots.first.x,
                        maxX: weightSpots.last.x,
                        minY: 0,
                        maxY: maxWeight,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxWeight / 4).ceilToDouble(),
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.border,
                            strokeWidth: 0.8,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.border),
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: (maxWeight / 4).ceilToDouble(),
                              getTitlesWidget: (value, _) => Text(
                                value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}kg' : '${value.toInt()}g',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: (weightSpots.last.x - weightSpots.first.x) / 4,
                              getTitlesWidget: (value, _) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Text(
                                  '${dt.month}/${dt.day}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weightSpots,
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: AppColors.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 3, color: AppColors.primary, strokeColor: Colors.white, strokeWidth: 1.5),
                            ),
                            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((spot) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                              return LineTooltipItem('${dt.month}/${dt.day}/${dt.year}\nWeight: ${spot.y.toStringAsFixed(0)} g', const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyWeightGainChart(List<DailyRecordModel> records) {
    // compute per-record gain vs previous record for same batch
    final items = [...records]..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final gains = <FlSpot>[];
    for (var i = 1; i < items.length; i++) {
      final prev = items[i - 1];
      final curr = items[i];
      if (prev.avgWeightGrams > 0 && curr.avgWeightGrams > 0) {
        final gain = curr.avgWeightGrams - prev.avgWeightGrams;
        gains.add(FlSpot(curr.recordDate.millisecondsSinceEpoch.toDouble(), gain));
      }
    }

    if (gains.length < 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: SizedBox(
            height: 160,
            child: const Center(
              child: Text('Not enough data to display this chart.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ),
      );
    }

    final maxGain = math.max(1.0, gains.map((s) => s.y).reduce(math.max).abs() + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Daily Weight Gain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Change in average weight since previous record', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minX: gains.first.x,
                  maxX: gains.last.x,
                  minY: -maxGain,
                  maxY: maxGain,
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxGain / 2, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.8)),
                  borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: AppColors.border), left: BorderSide(color: AppColors.border))),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: maxGain / 2, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}g', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (gains.last.x - gains.first.x) / 4, getTitlesWidget: (value, _) { final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt()); return Text('${dt.month}/${dt.day}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)); })),
                  ),
                  lineBarsData: [LineChartBarData(spots: gains, isCurved: false, color: AppColors.cardGradient.colors.first, barWidth: 2.2, dotData: FlDotData(show: true))],
                  lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => spots.map((spot) { final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()); return LineTooltipItem('${dt.month}/${dt.day}/${dt.year}\nGain: ${spot.y.toStringAsFixed(1)} g', const TextStyle(color: Colors.white, fontSize: 11)); }).toList())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchComparisonChart(List<DailyRecordModel> records, List<BatchModel> batchOptions) {
    // For all batches: compute latest avg weight per batch
    final latestByBatch = <String, DailyRecordModel>{};
    for (final r in records) {
      final existing = latestByBatch[r.batchId];
      if (existing == null || r.recordDate.isAfter(existing.recordDate)) {
        latestByBatch[r.batchId] = r;
      }
    }
    final entries = batchOptions.where((b) => latestByBatch.containsKey(b.id)).map((b) => MapEntry(b.batchName, latestByBatch[b.id]!.avgWeightGrams)).toList();
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: SizedBox(
            height: 160,
            child: const Center(
              child: Text('Not enough data to display this chart.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ),
      );
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      final val = entries[i].value;
      barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: val, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(6))]));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Batch Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Current average weight by batch', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(BarChartData(barGroups: barGroups, borderData: FlBorderData(show: false), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) { final idx = value.toInt(); if (idx < 0 || idx >= entries.length) return const Text(''); final label = entries[idx].key; return Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)); }, reservedSize: 40)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v >= 1000 ? '${(v/1000).toStringAsFixed(1)}kg' : '${v.toInt()}g', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))))))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalysis(List<DailyRecordModel> records, BatchModel? selectedBatch, List<BatchModel> batchOptions) {
    final totalBirds = selectedBatch?.totalBirds ?? batchOptions.fold<int>(0, (sum, b) => sum + b.totalBirds);
    // Weight records
    final weightRecords = records.where((r) => r.avgWeightGrams > 0).toList()..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    final feedRecords = records.where((r) => r.feedConsumedKg > 0).toList();
    final mortalityRecords = records.where((r) => (r.mortalityCount > 0) || (r.cullCount > 0)).toList();

    // Data quality
    String dataQualityNote = '';
    if (records.isEmpty) dataQualityNote = 'No records available for the selected context.';

    int missingDays = 0;
    if (records.isNotEmpty) {
      final dates = records.map((r) => DateTime(r.recordDate.year, r.recordDate.month, r.recordDate.day)).toSet();
      final minD = records.map((r) => r.recordDate).reduce((a, b) => a.isBefore(b) ? a : b);
      final maxD = records.map((r) => r.recordDate).reduce((a, b) => a.isAfter(b) ? a : b);
      final totalDays = maxD.difference(minD).inDays + 1;
      missingDays = totalDays - dates.length;
    }

    // Performance determinations
    String status = '⚪ Insufficient Data';
    final performing = <String>[];
    final attention = <String>[];

    if (weightRecords.length >= 2) {
      final first = weightRecords.first;
      final last = weightRecords.last;
      final days = last.recordDate.difference(first.recordDate).inDays;
      final slope = days > 0 ? (last.avgWeightGrams - first.avgWeightGrams) / days : 0.0;

      // compute average daily gain early vs late
      final gains = <double>[];
      for (var i = 1; i < weightRecords.length; i++) {
        final prev = weightRecords[i - 1];
        final cur = weightRecords[i];
        final dt = cur.recordDate.difference(prev.recordDate).inDays;
        if (dt > 0) gains.add((cur.avgWeightGrams - prev.avgWeightGrams) / dt);
      }
      double firstHalfAvg = 0, secondHalfAvg = 0;
      if (gains.isNotEmpty) {
        final mid = gains.length ~/ 2;
        firstHalfAvg = gains.sublist(0, mid == 0 ? 1 : mid).fold(0.0, (a, b) => a + b) / (mid == 0 ? 1 : mid);
        secondHalfAvg = gains.sublist(mid).fold(0.0, (a, b) => a + b) / (gains.length - mid);
      }

      if (slope > 0) {
        status = '🟢 On Track';
        performing.add('Average weight is increasing (positive trend).');
      } else if (slope < 0) {
        status = '🟠 Needs Attention';
        attention.add('Average weight trend is declining.');
      }

      if (gains.length >= 2) {
        if (secondHalfAvg < firstHalfAvg * 0.9) {
          if (status == '🟢 On Track') status = '🟠 Needs Attention';
          attention.add('Daily weight gain decreased during the selected period.');
        } else if (secondHalfAvg > firstHalfAvg) {
          performing.add('Weight gain is improving.');
        }
      }
    }

    // Mortality check
    if (mortalityRecords.isNotEmpty && records.isNotEmpty) {
      // cumulative mortality in first vs second half
      final sorted = [...records]..sort((a, b) => a.recordDate.compareTo(b.recordDate));
      final midIndex = sorted.length ~/ 2;
      final firstHalf = sorted.sublist(0, midIndex);
      final secondHalf = sorted.sublist(midIndex);
      final firstMort = firstHalf.fold<int>(0, (s, r) => s + r.mortalityCount + r.cullCount);
      final secondMort = secondHalf.fold<int>(0, (s, r) => s + r.mortalityCount + r.cullCount);
      final firstRate = (totalBirds > 0) ? firstMort / totalBirds : firstMort.toDouble();
      final secondRate = (totalBirds > 0) ? secondMort / totalBirds : secondMort.toDouble();
      if (secondMort > firstMort && secondRate > firstRate) {
        if (status == '🟢 On Track') status = '🟠 Needs Attention';
        attention.add('Mortality increased during the selected period.');
      } else {
        performing.add('Mortality has remained stable.');
      }
    } else {
      if (mortalityRecords.isEmpty) {
        dataQualityNote = dataQualityNote.isEmpty ? 'Mortality records missing.' : dataQualityNote;
      }
    }

    // Feed check
    if (feedRecords.isNotEmpty && weightRecords.length >= 2) {
      final sorted = [...records]..sort((a, b) => a.recordDate.compareTo(b.recordDate));
      final mid = sorted.length ~/ 2;
      final f1 = sorted.sublist(0, mid).fold<double>(0, (s, r) => s + (r.feedConsumedKg.isFinite ? r.feedConsumedKg : 0.0));
      final f2 = sorted.sublist(mid).fold<double>(0, (s, r) => s + (r.feedConsumedKg.isFinite ? r.feedConsumedKg : 0.0));
      final n1 = sorted.sublist(0, mid).length;
      final n2 = sorted.sublist(mid).length;
      final avg1 = n1 > 0 ? f1 / n1 : 0.0;
      final avg2 = n2 > 0 ? f2 / n2 : 0.0;
      if (avg2 > avg1 * 1.2) {
        if (secondHalfAvgIsDecreasing(weightRecords: weightRecords)) {
          if (status == '🟢 On Track') status = '🟠 Needs Attention';
          attention.add('Feed consumption increased while weight gain remained stable or decreased.');
        } else {
          performing.add('Feed consumption increased and supported weight gain.');
        }
      } else {
        performing.add('Feed consumption is consistent.');
      }
    } else {
      if (feedRecords.isEmpty) dataQualityNote = dataQualityNote.isEmpty ? 'Feed records missing.' : dataQualityNote;
    }

    if (weightRecords.length < 2) {
      status = '⚪ Insufficient Data';
      if (dataQualityNote.isEmpty) dataQualityNote = 'Weight records are insufficient to determine trend.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(children: [Text('Growth status: ', style: const TextStyle(fontWeight: FontWeight.w700)), Text(status)]),
            const SizedBox(height: 10),
            if (performing.isNotEmpty) ...[
              const Text('✅ Performing Well', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...performing.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $s', style: const TextStyle(color: AppColors.textSecondary)))),
              const SizedBox(height: 8),
            ],
            if (attention.isNotEmpty) ...[
              const Text('⚠️ Areas Needing Attention', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...attention.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $s', style: const TextStyle(color: AppColors.textSecondary)))),
              const SizedBox(height: 8),
            ],
            const Text('Data Quality', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: Text('Weight Records', style: const TextStyle(color: AppColors.textSecondary))), Text('${weightRecords.length}')]),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: Text('Feed Records', style: const TextStyle(color: AppColors.textSecondary))), Text('${feedRecords.length}')]),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: Text('Mortality Records', style: const TextStyle(color: AppColors.textSecondary))), Text('${mortalityRecords.length}')]),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: Text('Missing Data Days', style: const TextStyle(color: AppColors.textSecondary))), Text('$missingDays')]),
            if (dataQualityNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(dataQualityNote, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  bool secondHalfAvgIsDecreasing({required List<DailyRecordModel> weightRecords}) {
    if (weightRecords.length < 4) return false;
    final gains = <double>[];
    for (var i = 1; i < weightRecords.length; i++) {
      final prev = weightRecords[i - 1];
      final cur = weightRecords[i];
      final dt = cur.recordDate.difference(prev.recordDate).inDays;
      if (dt > 0) gains.add((cur.avgWeightGrams - prev.avgWeightGrams) / dt);
    }
    if (gains.length < 2) return false;
    final mid = gains.length ~/ 2;
    final firstAvg = gains.sublist(0, mid).fold(0.0, (a, b) => a + b) / mid;
    final secondAvg = gains.sublist(mid).fold(0.0, (a, b) => a + b) / (gains.length - mid);
    return secondAvg < firstAvg * 0.9;
  }

  Widget _buildMortalityChart(
    List<DailyRecordModel> records,
    BatchModel? selectedBatch,
    List<BatchModel> batchOptions,
  ) {
    final sorted = [...records]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
    final mortalitySpots = <FlSpot>[];
    var cumulativeDeaths = 0;
    final totalBirds =
        selectedBatch?.totalBirds ??
        batchOptions.fold<int>(0, (sum, batch) => sum + batch.totalBirds);

    for (final record in sorted) {
      cumulativeDeaths += record.mortalityCount + record.cullCount;
      final pct = totalBirds > 0
          ? (cumulativeDeaths / totalBirds * 100).toDouble()
          : 0.0;
      mortalitySpots.add(FlSpot(record.batchAgeDay.toDouble(), pct));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mortality Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cumulative mortality percentage over time',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: mortalitySpots.isEmpty
                  ? const Center(
                      child: Text(
                        'No mortality records yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: mortalitySpots.isEmpty
                            ? 42
                            : math.max(42, mortalitySpots.last.x),
                        minY: 0,
                        maxY: math.max(
                          6,
                          mortalitySpots
                                  .map((spot) => spot.y)
                                  .reduce(math.max) +
                              1,
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.border,
                            strokeWidth: 0.8,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: AppColors.border),
                            left: BorderSide(color: AppColors.border),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 1,
                              getTitlesWidget: (value, _) => Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 7,
                              getTitlesWidget: (value, _) => Text(
                                'D${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: mortalitySpots,
                            isCurved: true,
                            color: AppColors.danger,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.danger.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots
                                .map(
                                  (spot) => LineTooltipItem(
                                    'Day ${spot.x.toInt()} · ${spot.y.toStringAsFixed(1)}%',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try again later or check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
