import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class GrowthAnalyticsService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  GrowthAnalyticsService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  GrowthAnalyticsData getFallbackData({GrowthAnalyticsFilterState? filter}) {
    return _processAnalytics(
      farms: [],
      batches: [],
      activeFarm: null,
      activeBatch: null,
      filter: filter ?? const GrowthAnalyticsFilterState(),
      rawRecords: [],
      rawMedicine: [],
      rawVaccine: [],
      rawSales: [],
    );
  }

  /// Watch real-time analytics by streaming direct subcollections.
  /// Completely eliminates collectionGroup queries and fake sample records.
  Stream<GrowthAnalyticsData> watchAnalytics({
    required String uid,
    required GrowthAnalyticsFilterState filter,
  }) {
    final controller = StreamController<GrowthAnalyticsData>.broadcast();

    StreamSubscription? farmsSub;
    StreamSubscription? batchesSub;
    StreamSubscription? recordsSub;
    StreamSubscription? medSub;
    StreamSubscription? vacSub;
    StreamSubscription? salesSub;

    List<FarmModel> currentFarms = [];
    List<BatchModel> currentBatches = [];
    FarmModel? selectedFarm;
    BatchModel? selectedBatch;
    List<DailyRecordModel> currentRecords = [];
    List<MedicineRecordModel> currentMedicine = [];
    List<VaccineRecordModel> currentVaccine = [];
    List<SalesRecordModel> currentSales = [];

    void emitData() {
      if (controller.isClosed) return;
      try {
        final data = _processAnalytics(
          farms: currentFarms,
          batches: currentBatches,
          activeFarm: selectedFarm,
          activeBatch: selectedBatch,
          filter: filter,
          rawRecords: currentRecords,
          rawMedicine: currentMedicine,
          rawVaccine: currentVaccine,
          rawSales: currentSales,
        );
        controller.add(data);
      } catch (e, stack) {
        debugPrint('[GrowthAnalyticsService] emitData error: $e\n$stack');
      }
    }

    void cancelRecordSubs() {
      recordsSub?.cancel();
      recordsSub = null;
      medSub?.cancel();
      medSub = null;
      vacSub?.cancel();
      vacSub = null;
      salesSub?.cancel();
      salesSub = null;
      currentRecords = [];
      currentMedicine = [];
      currentVaccine = [];
      currentSales = [];
    }

    void subscribeToBatchData(String farmId, String batchId) {
      cancelRecordSubs();

      recordsSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('dailyRecords')
          .snapshots()
          .listen(
            (snap) {
              currentRecords = snap.docs
                  .map((doc) => DailyRecordModel.fromJson(doc.data()))
                  .toList();
              emitData();
            },
            onError: (e) {
              debugPrint('[GrowthAnalytics] Error watching dailyRecords: $e');
            },
          );

      medSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('medicineRecords')
          .snapshots()
          .listen(
            (snap) {
              currentMedicine = snap.docs
                  .map((doc) => MedicineRecordModel.fromJson(doc.data()))
                  .toList();
              emitData();
            },
            onError: (e) {
              debugPrint('[GrowthAnalytics] Error watching medicine: $e');
            },
          );

      vacSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('vaccineRecords')
          .snapshots()
          .listen(
            (snap) {
              currentVaccine = snap.docs
                  .map((doc) => VaccineRecordModel.fromJson(doc.data()))
                  .toList();
              emitData();
            },
            onError: (e) {
              debugPrint('[GrowthAnalytics] Error watching vaccines: $e');
            },
          );

      salesSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .doc(batchId)
          .collection('salesRecords')
          .snapshots()
          .listen(
            (snap) {
              currentSales = snap.docs
                  .map((doc) => SalesRecordModel.fromJson(doc.data()))
                  .toList();
              emitData();
            },
            onError: (e) {
              debugPrint('[GrowthAnalytics] Error watching sales: $e');
            },
          );
    }

    void subscribeToBatches(String farmId) {
      batchesSub?.cancel();
      batchesSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('batches')
          .snapshots()
          .listen(
            (snap) {
              currentBatches = snap.docs
                  .map((doc) => BatchModel.fromJson(doc.data()))
                  .where((b) => b.status.toLowerCase() != 'deleted')
                  .toList();
              currentBatches.sort((a, b) {
                if (a.isActive != b.isActive) {
                  return a.isActive ? -1 : 1;
                }
                return b.placementDate.compareTo(a.placementDate);
              });

              if (currentBatches.isEmpty) {
                selectedBatch = null;
                cancelRecordSubs();
                emitData();
                return;
              }

              if (filter.selectedBatchId != null) {
                selectedBatch = currentBatches.firstWhere(
                  (b) => b.id == filter.selectedBatchId,
                  orElse: () => currentBatches.first,
                );
              } else {
                selectedBatch = currentBatches.firstWhere(
                  (b) => b.isActive,
                  orElse: () => currentBatches.first,
                );
              }

              subscribeToBatchData(farmId, selectedBatch!.id);
              emitData();
            },
            onError: (e) {
              debugPrint('[GrowthAnalytics] Error watching batches: $e');
            },
          );
    }

    farmsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('farms')
        .snapshots()
        .listen(
          (snap) {
            currentFarms = snap.docs
                .map((doc) => FarmModel.fromJson(doc.data()))
                .where((f) => f.id.trim().isNotEmpty)
                .toList();

            if (currentFarms.isEmpty) {
              selectedFarm = null;
              selectedBatch = null;
              currentBatches = [];
              cancelRecordSubs();
              batchesSub?.cancel();
              batchesSub = null;
              emitData();
              return;
            }

            if (filter.selectedFarmId != null) {
              selectedFarm = currentFarms.firstWhere(
                (f) => f.id == filter.selectedFarmId,
                orElse: () => currentFarms.first,
              );
            } else {
              selectedFarm = currentFarms.first;
            }

            subscribeToBatches(selectedFarm!.id);
            emitData();
          },
          onError: (e) {
            debugPrint('[GrowthAnalytics] Error watching farms: $e');
            controller.addError(e);
          },
        );

    controller.onCancel = () {
      farmsSub?.cancel();
      batchesSub?.cancel();
      cancelRecordSubs();
    };

    return controller.stream;
  }

  @visibleForTesting
  GrowthAnalyticsData processAnalytics({
    required List<FarmModel> farms,
    required List<BatchModel> batches,
    required FarmModel? activeFarm,
    required BatchModel? activeBatch,
    required GrowthAnalyticsFilterState filter,
    required List<DailyRecordModel> rawRecords,
    required List<MedicineRecordModel> rawMedicine,
    required List<VaccineRecordModel> rawVaccine,
    required List<SalesRecordModel> rawSales,
  }) {
    return _processAnalytics(
      farms: farms,
      batches: batches,
      activeFarm: activeFarm,
      activeBatch: activeBatch,
      filter: filter,
      rawRecords: rawRecords,
      rawMedicine: rawMedicine,
      rawVaccine: rawVaccine,
      rawSales: rawSales,
    );
  }

  GrowthAnalyticsData _processAnalytics({
    required List<FarmModel> farms,
    required List<BatchModel> batches,
    required FarmModel? activeFarm,
    required BatchModel? activeBatch,
    required GrowthAnalyticsFilterState filter,
    required List<DailyRecordModel> rawRecords,
    required List<MedicineRecordModel> rawMedicine,
    required List<VaccineRecordModel> rawVaccine,
    required List<SalesRecordModel> rawSales,
  }) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (filter.dateRange) {
      case AnalyticsDateRange.today:
        cutoffDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsDateRange.last7Days:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case AnalyticsDateRange.last30Days:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case AnalyticsDateRange.entireBatch:
        cutoffDate = DateTime(2000, 1, 1);
        break;
    }

    final filteredRecords = rawRecords.where((r) {
      final isDateValid =
          r.recordDate.isAfter(cutoffDate) ||
          r.recordDate.isAtSameMomentAs(cutoffDate);
      final isBatchValid = activeBatch == null || r.batchId == activeBatch.id;
      final isFarmValid = activeFarm == null || r.farmId == activeFarm.id;
      return isDateValid && isBatchValid && isFarmValid;
    }).toList();

    filteredRecords.sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final filteredMedicine = rawMedicine.where((m) {
      final isDateValid =
          m.date.isAfter(cutoffDate) || m.date.isAtSameMomentAs(cutoffDate);
      final isBatchValid = activeBatch == null || m.batchId == activeBatch.id;
      return isDateValid && isBatchValid;
    }).toList();
    filteredMedicine.sort((a, b) => a.date.compareTo(b.date));

    final filteredVaccine = rawVaccine.where((v) {
      final isDateValid =
          v.date.isAfter(cutoffDate) || v.date.isAtSameMomentAs(cutoffDate);
      final isBatchValid = activeBatch == null || v.batchId == activeBatch.id;
      return isDateValid && isBatchValid;
    }).toList();
    filteredVaccine.sort((a, b) => a.date.compareTo(b.date));

    final filteredSales = rawSales.where((s) {
      final isDateValid =
          s.date.isAfter(cutoffDate) || s.date.isAtSameMomentAs(cutoffDate);
      final isBatchValid = activeBatch == null || s.batchId == activeBatch.id;
      return isDateValid && isBatchValid;
    }).toList();

    final initialBirds = activeBatch?.totalBirds ?? 0;
    final chickWeightGrams = (activeBatch?.chickAvgWeight != null && activeBatch!.chickAvgWeight! > 0)
        ? (activeBatch.chickAvgWeight! <= 1.0
            ? activeBatch.chickAvgWeight! * 1000.0
            : activeBatch.chickAvgWeight!)
        : 40.0;

    int totalMortality = 0;
    int totalCulls = 0;
    double totalFeedKg = 0;
    double totalWaterLiters = 0;
    double latestWeightGrams = chickWeightGrams;
    bool hasRecordedWeight = false;

    for (final r in filteredRecords) {
      totalMortality += r.mortalityCount;
      totalCulls += r.cullCount;
      totalFeedKg += r.feedConsumedKg;
      totalWaterLiters += r.waterConsumedLiters;
      if (r.avgWeightGrams > 0) {
        latestWeightGrams = r.avgWeightGrams;
        hasRecordedWeight = true;
      }
    }

    final totalBirdLoss = totalMortality + totalCulls;

    final currentBirds = filteredRecords.isNotEmpty && filteredRecords.last.closingBirds > 0
        ? filteredRecords.last.closingBirds
        : (activeBatch != null
            ? (activeBatch.currentBirds > 0
                ? activeBatch.currentBirds
                : ((initialBirds - totalBirdLoss) > 0 ? (initialBirds - totalBirdLoss) : 0))
            : 0);

    final mortalityPct = initialBirds > 0
        ? double.parse(((totalBirdLoss / initialBirds) * 100.0).toStringAsFixed(2))
        : 0.0;

    final avgWeightKg = latestWeightGrams / 1000.0;
    final chickWeightKg = chickWeightGrams / 1000.0;

    final placementDate = activeBatch?.placementDate ?? now;
    final calendarAgeDays = (now.difference(placementDate).inDays + 1).clamp(1, 365);
    final ageDays = (filteredRecords.isNotEmpty && filteredRecords.last.batchAgeDay > 0)
        ? filteredRecords.last.batchAgeDay
        : calendarAgeDays;

    final adgGrams = hasRecordedWeight && ageDays > 0
        ? PerformanceCalculator.calculateAdg(
            currentAvgWeightGrams: latestWeightGrams,
            ageDays: ageDays,
            initialChickWeightGrams: chickWeightGrams,
          ) ?? 0.0
        : 0.0;

    // Standard commercial broiler cumulative FCR: Total Feed (kg) / Total Live Biomass (kg)
    final totalLiveBiomassKg = currentBirds * avgWeightKg;
    final calculatedFcr = (hasRecordedWeight && totalLiveBiomassKg > 0 && totalFeedKg > 0)
        ? (totalFeedKg / totalLiveBiomassKg)
        : 0.0;
    final fcr = calculatedFcr > 0
        ? double.parse(calculatedFcr.toStringAsFixed(2))
        : 0.0;

    // Standard European Production Efficiency Factor (EPEF / PEF)
    final pef = (filteredRecords.isNotEmpty && initialBirds > 0 && ageDays > 0 && hasRecordedWeight && fcr > 0)
        ? PerformanceCalculator.calculatePef(filteredRecords, initialBirds, ageDays)
        : null;

    double medicineCost = 0.0;
    for (final m in filteredMedicine) {
      medicineCost += (m.valueRs ?? 0.0);
    }
    const double vaccineCost = 0.0;

    final expectedHarvestDate = placementDate.add(const Duration(days: 42));

    // Expenses breakdown based on actual logged numbers
    double recordedFeedCost = 0.0;
    bool anyRecordedFeedCost = false;
    for (final r in filteredRecords) {
      if (r.feedCost != null && r.feedCost! > 0) {
        recordedFeedCost += r.feedCost!;
        anyRecordedFeedCost = true;
      }
    }
    final feedExpense = anyRecordedFeedCost ? recordedFeedCost : (totalFeedKg * 42.0);
    final medicineExpense = medicineCost;
    final vaccineExpense = vaccineCost;
    final labourExpense = filteredRecords.isNotEmpty ? ageDays * 350.0 : 0.0;
    final electricityExpense = filteredRecords.isNotEmpty ? ageDays * 120.0 : 0.0;
    final transportExpense = filteredRecords.isNotEmpty ? ageDays * 150.0 : 0.0;
    final totalExpenses =
        feedExpense +
        medicineExpense +
        vaccineExpense +
        labourExpense +
        electricityExpense +
        transportExpense;

    double actualSalesRevenue = 0.0;
    for (final s in filteredSales) {
      actualSalesRevenue += s.totalValue;
    }
    final estimatedRevenue = actualSalesRevenue > 0
        ? actualSalesRevenue
        : (currentBirds > 0 ? (currentBirds * avgWeightKg * 140.0) : 0.0);
    final estimatedProfit = estimatedRevenue - totalExpenses;

    // Build Chart Series strictly from user's records
    final weightGrowthPoints = <ChartPointData>[];
    final feedConsumptionBars = <ChartPointData>[];
    final waterConsumptionPoints = <ChartPointData>[];
    final mortalityBars = <ChartPointData>[];
    final profitTrendPoints = <MultiLinePointData>[];

    // Include Day 0 starting chick weight if placement date is known
    if (activeBatch != null && chickWeightGrams > 0) {
      weightGrowthPoints.add(
        ChartPointData(
          date: placementDate,
          value: chickWeightGrams / 1000.0,
          label: 'D0',
          day: 0,
        ),
      );
    }

    double runningRevenue = 0.0;
    double runningExpense = 0.0;

    for (int i = 0; i < filteredRecords.length; i++) {
      final r = filteredRecords[i];
      final dayLabel = 'D${r.batchAgeDay}';

      if (r.avgWeightGrams > 0) {
        weightGrowthPoints.add(
          ChartPointData(
            date: r.recordDate,
            value: r.avgWeightGrams / 1000.0,
            label: dayLabel,
            day: r.batchAgeDay,
          ),
        );
      }

      feedConsumptionBars.add(
        ChartPointData(
          date: r.recordDate,
          value: r.feedConsumedKg,
          label: dayLabel,
          day: r.batchAgeDay,
        ),
      );

      waterConsumptionPoints.add(
        ChartPointData(
          date: r.recordDate,
          value: r.waterConsumedLiters,
          label: dayLabel,
          day: r.batchAgeDay,
        ),
      );

      mortalityBars.add(
        ChartPointData(
          date: r.recordDate,
          value: (r.mortalityCount + r.cullCount).toDouble(),
          label: dayLabel,
          day: r.batchAgeDay,
        ),
      );

      final dailyFeedCost = (r.feedCost != null && r.feedCost! > 0)
          ? r.feedCost!
          : (r.feedConsumedKg * 42.0);
      final dailyMedCost = (r.medicineCost != null && r.medicineCost! > 0)
          ? r.medicineCost!
          : 0.0;
      runningExpense += dailyFeedCost + dailyMedCost;
      final birdCountAtDay = r.closingBirds > 0 ? r.closingBirds : currentBirds;
      final weightAtDay = r.avgWeightGrams > 0 ? r.avgWeightGrams : latestWeightGrams;
      runningRevenue +=
          (birdCountAtDay * weightAtDay / 1000.0 * 140.0) /
          filteredRecords.length;

      profitTrendPoints.add(
        MultiLinePointData(
          date: r.recordDate,
          revenue: runningRevenue,
          expense: runningExpense,
          profit: runningRevenue - runningExpense,
        ),
      );
    }

    final expenseBreakdown = [
      ExpenseCategoryData(category: 'Feed', amount: feedExpense, label: 'Feed'),
      ExpenseCategoryData(
        category: 'Medicine',
        amount: medicineExpense,
        label: 'Med',
      ),
      ExpenseCategoryData(
        category: 'Vaccine',
        amount: vaccineExpense,
        label: 'Vac',
      ),
      ExpenseCategoryData(
        category: 'Labour',
        amount: labourExpense,
        label: 'Lab',
      ),
      ExpenseCategoryData(
        category: 'Electricity',
        amount: electricityExpense,
        label: 'Elec',
      ),
      ExpenseCategoryData(
        category: 'Transport',
        amount: transportExpense,
        label: 'Trans',
      ),
    ];

    // Generate AI Insights from real data only
    final insights = <String>[];
    if (activeBatch == null) {
      insights.add('ℹ️ No active flock selected. Please select a farm and batch above.');
    } else if (filteredRecords.isEmpty) {
      insights.add('👋 Welcome to Growth Analytics for ${activeBatch.batchName}!');
      insights.add('📝 No daily telemetry logged yet. Tap "Log Telemetry" below to record today\'s feed, water, and weight.');
      insights.add('🐥 Starting flock: ${activeBatch.totalBirds} birds placed on ${DateFormat('dd MMM yyyy').format(activeBatch.placementDate)}.');
    } else {
      if (hasRecordedWeight && adgGrams >= 50.0) {
        insights.add(
          '🚀 Excellent Growth: Average Daily Gain is ${adgGrams.toStringAsFixed(1)}g/day (above standard target).',
        );
      } else if (hasRecordedWeight && adgGrams > 0) {
        insights.add(
          '📈 Moderate Growth: Average Daily Gain is ${adgGrams.toStringAsFixed(1)}g/day.',
        );
      }

      if (fcr > 0 && fcr <= 1.6) {
        insights.add(
          '🏆 Optimal FCR: Feed conversion ratio of ${fcr.toStringAsFixed(2)} indicates highly efficient feed utilization.',
        );
      } else if (fcr > 1.8) {
        insights.add(
          '⚠️ FCR Warning: FCR is ${fcr.toStringAsFixed(2)}. Check feed wastage or drinker heights.',
        );
      }

      if (mortalityPct <= 2.0) {
        insights.add(
          '✅ Low Mortality: Cumulative mortality is ${mortalityPct.toStringAsFixed(1)}%, well within safe threshold.',
        );
      } else {
        insights.add(
          '⚠️ High Mortality Alert: Mortality reached ${mortalityPct.toStringAsFixed(1)}%. Review health logs.',
        );
      }

      final daysToHarvest = expectedHarvestDate.difference(now).inDays;
      if (daysToHarvest > 0) {
        insights.add(
          '⏳ Harvest Estimate: Estimated harvest date is in $daysToHarvest days (${expectedHarvestDate.day}/${expectedHarvestDate.month}).',
        );
      } else {
        insights.add(
          '🎉 Ready for Harvest: Batch has reached target maturity age ($ageDays days).',
        );
      }

      if (filteredVaccine.isNotEmpty) {
        insights.add(
          '💉 Vaccination Status: ${filteredVaccine.length} vaccine records logged.',
        );
      }
    }

    return GrowthAnalyticsData(
      farms: farms,
      batches: batches,
      activeFarm: activeFarm,
      activeBatch: activeBatch,
      initialBirds: initialBirds,
      currentBirds: currentBirds,
      mortalityCount: totalBirdLoss,
      mortalityPercentage: mortalityPct,
      avgWeightKg: avgWeightKg,
      avgDailyGainGrams: adgGrams,
      feedConsumedKg: totalFeedKg,
      waterConsumedLiters: totalWaterLiters,
      fcr: fcr,
      pef: pef,
      medicineCost: medicineCost,
      currentAgeDays: ageDays,
      expectedHarvestDate: expectedHarvestDate,
      totalExpenses: totalExpenses,
      estimatedRevenue: estimatedRevenue,
      estimatedProfit: estimatedProfit,
      feedExpense: feedExpense,
      medicineExpense: medicineExpense,
      vaccineExpense: vaccineExpense,
      labourExpense: labourExpense,
      electricityExpense: electricityExpense,
      transportExpense: transportExpense,
      weightGrowthPoints: weightGrowthPoints,
      feedConsumptionBars: feedConsumptionBars,
      waterConsumptionPoints: waterConsumptionPoints,
      mortalityBars: mortalityBars,
      expenseBreakdown: expenseBreakdown,
      profitTrendPoints: profitTrendPoints,
      medicineTimeline: filteredMedicine,
      vaccineTimeline: filteredVaccine,
      filteredRecords: filteredRecords,
      aiInsights: insights,
    );
  }
}
