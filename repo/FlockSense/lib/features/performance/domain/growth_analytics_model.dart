import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

enum AnalyticsDateRange { today, last7Days, last30Days, entireBatch }

class GrowthAnalyticsFilterState {
  final String? selectedFarmId;
  final String? selectedBatchId;
  final AnalyticsDateRange dateRange;

  const GrowthAnalyticsFilterState({
    this.selectedFarmId,
    this.selectedBatchId,
    this.dateRange = AnalyticsDateRange.entireBatch,
  });

  GrowthAnalyticsFilterState copyWith({
    String? selectedFarmId,
    String? selectedBatchId,
    AnalyticsDateRange? dateRange,
    bool clearFarm = false,
    bool clearBatch = false,
  }) {
    return GrowthAnalyticsFilterState(
      selectedFarmId: clearFarm
          ? null
          : (selectedFarmId ?? this.selectedFarmId),
      selectedBatchId: clearBatch
          ? null
          : (selectedBatchId ?? this.selectedBatchId),
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

class ChartPointData {
  final DateTime date;
  final double value;
  final String label;

  const ChartPointData({
    required this.date,
    required this.value,
    required this.label,
  });
}

class MultiLinePointData {
  final DateTime date;
  final double revenue;
  final double expense;
  final double profit;

  const MultiLinePointData({
    required this.date,
    required this.revenue,
    required this.expense,
    required this.profit,
  });
}

class ExpenseCategoryData {
  final String category;
  final double amount;
  final String label;

  const ExpenseCategoryData({
    required this.category,
    required this.amount,
    required this.label,
  });
}

class GrowthAnalyticsData {
  final List<FarmModel> farms;
  final List<BatchModel> batches;
  final FarmModel? activeFarm;
  final BatchModel? activeBatch;

  final int initialBirds;
  final int currentBirds;
  final int mortalityCount;
  final double mortalityPercentage;
  final double avgWeightKg;
  final double avgDailyGainGrams;
  final double feedConsumedKg;
  final double waterConsumedLiters;
  final double fcr;
  final double medicineCost;
  final int currentAgeDays;
  final DateTime? expectedHarvestDate;
  final double totalExpenses;
  final double estimatedRevenue;
  final double estimatedProfit;

  // Expense components
  final double feedExpense;
  final double medicineExpense;
  final double vaccineExpense;
  final double labourExpense;
  final double electricityExpense;
  final double transportExpense;

  // Chart data series
  final List<ChartPointData> weightGrowthPoints;
  final List<ChartPointData> feedConsumptionBars;
  final List<ChartPointData> waterConsumptionPoints;
  final List<ChartPointData> mortalityBars;
  final List<ExpenseCategoryData> expenseBreakdown;
  final List<MultiLinePointData> profitTrendPoints;

  // Timelines & Raw Records
  final List<MedicineRecordModel> medicineTimeline;
  final List<VaccineRecordModel> vaccineTimeline;
  final List<DailyRecordModel> filteredRecords;
  final List<String> aiInsights;

  const GrowthAnalyticsData({
    required this.farms,
    required this.batches,
    this.activeFarm,
    this.activeBatch,
    required this.initialBirds,
    required this.currentBirds,
    required this.mortalityCount,
    required this.mortalityPercentage,
    required this.avgWeightKg,
    required this.avgDailyGainGrams,
    required this.feedConsumedKg,
    required this.waterConsumedLiters,
    required this.fcr,
    required this.medicineCost,
    required this.currentAgeDays,
    this.expectedHarvestDate,
    required this.totalExpenses,
    required this.estimatedRevenue,
    required this.estimatedProfit,
    required this.feedExpense,
    required this.medicineExpense,
    required this.vaccineExpense,
    required this.labourExpense,
    required this.electricityExpense,
    required this.transportExpense,
    required this.weightGrowthPoints,
    required this.feedConsumptionBars,
    required this.waterConsumptionPoints,
    required this.mortalityBars,
    required this.expenseBreakdown,
    required this.profitTrendPoints,
    required this.medicineTimeline,
    required this.vaccineTimeline,
    required this.filteredRecords,
    required this.aiInsights,
  });

  bool get isEmpty => filteredRecords.isEmpty && (activeBatch == null);

  static const empty = GrowthAnalyticsData(
    farms: [],
    batches: [],
    activeFarm: null,
    activeBatch: null,
    initialBirds: 0,
    currentBirds: 0,
    mortalityCount: 0,
    mortalityPercentage: 0,
    avgWeightKg: 0,
    avgDailyGainGrams: 0,
    feedConsumedKg: 0,
    waterConsumedLiters: 0,
    fcr: 0,
    medicineCost: 0,
    currentAgeDays: 0,
    expectedHarvestDate: null,
    totalExpenses: 0,
    estimatedRevenue: 0,
    estimatedProfit: 0,
    feedExpense: 0,
    medicineExpense: 0,
    vaccineExpense: 0,
    labourExpense: 0,
    electricityExpense: 0,
    transportExpense: 0,
    weightGrowthPoints: [],
    feedConsumptionBars: [],
    waterConsumptionPoints: [],
    mortalityBars: [],
    expenseBreakdown: [],
    profitTrendPoints: [],
    medicineTimeline: [],
    vaccineTimeline: [],
    filteredRecords: [],
    aiInsights: [],
  );

  // Convenience getters for telemetry calculations
  List<FarmModel> get availableFarms => farms;
  List<BatchModel> get availableBatches => batches;
  int get totalBirdsRemaining => currentBirds;
  int get totalInitialBirds => initialBirds;
  int get totalMortality => mortalityCount;
  double get averageWeightGrams => avgWeightKg * 1000.0;
  int get batchAgeDays => currentAgeDays;
  double get totalFeedConsumedKg => feedConsumedKg;
  double get totalWaterConsumedLiters => waterConsumedLiters;
  double get netProfit => estimatedProfit;
  double get profitMarginPercentage =>
      estimatedRevenue > 0 ? (estimatedProfit / estimatedRevenue * 100.0) : 0.0;
  List<DailyRecordModel> get dailyRecords => filteredRecords;
}
