import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';

class PerformanceCalculator {
  static const Map<int, double> skmBodyWeightStd = {
    1: 56,
    2: 70,
    3: 87,
    4: 106,
    5: 128,
    6: 152,
    7: 185,
    8: 220,
    9: 255,
    10: 290,
    11: 335,
    12: 387,
    13: 443,
    14: 500,
    15: 559,
    16: 618,
    17: 677,
    18: 736,
    19: 795,
    20: 854,
    21: 913,
    22: 993,
    23: 1073,
    24: 1153,
    25: 1233,
    26: 1313,
    27: 1394,
    28: 1475,
    29: 1566,
    30: 1658,
    31: 1749,
    32: 1840,
    33: 1931,
    34: 2023,
    35: 2115,
    36: 2206,
    37: 2296,
    38: 2387,
    39: 2477,
    40: 2568,
    41: 2659,
    42: 2750,
  };

  static const Map<int, double> skmFcrStd = {
    7: 0.88,
    14: 1.06,
    21: 1.27,
    28: 1.41,
    35: 1.54,
    42: 1.69,
  };

  /// Calculates daily FCR for a single record if per-bird feed is available,
  /// or returns ratio of feed consumed to total live biomass gain.
  static double? calculateDayFcr(DailyRecordModel record) {
    if (record.avgWeightGrams <= 0 || record.feedConsumedKg <= 0) return null;
    final liveBirds = record.closingBirds > 0
        ? record.closingBirds
        : record.openingBirds;
    if (liveBirds <= 0) return null;
    final liveBiomassKg = liveBirds * (record.avgWeightGrams / 1000.0);
    if (liveBiomassKg <= 0) return null;
    // Cumulative or day ratio
    final feedPerBirdKg = record.feedConsumedKg / liveBirds;
    final weightKg = record.avgWeightGrams / 1000.0;
    return weightKg > 0 ? (feedPerBirdKg / weightKg) : null;
  }

  /// Calculates cumulative FCR (Total Feed in kg / Total Live Biomass in kg).
  static double? calculateCumulativeFcr(
    List<DailyRecordModel> records,
    int upToDay,
  ) {
    final relevant = records.where((r) => r.batchAgeDay <= upToDay).toList();
    if (relevant.isEmpty) return null;
    final totalFeedKg = relevant.fold(0.0, (sum, r) => sum + r.feedConsumedKg);
    final lastRecord = relevant.reduce(
      (a, b) => a.batchAgeDay > b.batchAgeDay ? a : b,
    );
    if (lastRecord.avgWeightGrams <= 0 || totalFeedKg <= 0) return null;
    final liveBirds = lastRecord.closingBirds > 0
        ? lastRecord.closingBirds
        : lastRecord.openingBirds;
    if (liveBirds <= 0) return null;

    final totalBiomassKg = liveBirds * (lastRecord.avgWeightGrams / 1000.0);
    if (totalBiomassKg <= 0) return null;

    final fcr = totalFeedKg / totalBiomassKg;
    return double.parse(fcr.toStringAsFixed(3));
  }

  /// Calculates Average Daily Gain (ADG) in grams per bird per day.
  /// ADG = (Current Weight (g) - Initial Chick Weight (g)) / Age in Days.
  static double? calculateAdg({
    required double currentAvgWeightGrams,
    required int ageDays,
    double initialChickWeightGrams = 42.0,
  }) {
    if (ageDays <= 0 || currentAvgWeightGrams <= 0) return null;
    final netGain = currentAvgWeightGrams - initialChickWeightGrams;
    final adg = netGain / ageDays;
    return double.parse(adg.toStringAsFixed(2));
  }

  static double calculateCumulativeMortalityPct(
    List<DailyRecordModel> records,
    int totalBirds,
    int upToDay,
  ) {
    if (totalBirds <= 0) return 0;
    final totalMort = records
        .where((r) => r.batchAgeDay <= upToDay)
        .fold(0, (sum, r) => sum + r.mortalityCount + r.cullCount);
    final pct = (totalMort / totalBirds) * 100;
    return double.parse(pct.toStringAsFixed(2));
  }

  /// Calculates European Production Efficiency Factor (EPEF / PEF).
  /// EPEF = (Liveability % * Avg Body Weight in kg) / (Age in Days * FCR) * 100.
  static double? calculatePef(
    List<DailyRecordModel> records,
    int totalBirds,
    int ageDays,
  ) {
    if (records.isEmpty || totalBirds <= 0 || ageDays <= 0) return null;
    final lastRecord = records.reduce(
      (a, b) => a.batchAgeDay > b.batchAgeDay ? a : b,
    );
    final totalMort = records.fold(
      0,
      (sum, r) => sum + r.mortalityCount + r.cullCount,
    );
    final liveabilityPct = ((totalBirds - totalMort) / totalBirds) * 100;
    final avgWeightKg = lastRecord.avgWeightGrams / 1000.0;
    final fcr = calculateCumulativeFcr(records, ageDays);
    if (fcr == null || fcr <= 0 || avgWeightKg <= 0) return null;
    final pef = (liveabilityPct * avgWeightKg) / (ageDays * fcr) * 100;
    return double.parse(pef.toStringAsFixed(1));
  }

  static List<WeeklyMortality> calculateWeeklyMortality(
    List<DailyRecordModel> records,
    int totalBirds,
  ) {
    final result = <WeeklyMortality>[];
    for (int week = 1; week <= 6; week++) {
      final start = (week - 1) * 7 + 1;
      final end = week * 7;
      final weekRecords = records
          .where((r) => r.batchAgeDay >= start && r.batchAgeDay <= end)
          .toList();
      if (weekRecords.isEmpty) continue;
      final deaths = weekRecords.fold(
        0,
        (sum, r) => sum + r.mortalityCount + r.cullCount,
      );
      final openingBirds = weekRecords.first.openingBirds;
      final pct = openingBirds > 0 ? (deaths / openingBirds) * 100 : 0.0;
      result.add(WeeklyMortality(week: week, deaths: deaths, pct: pct));
    }
    return result;
  }

  static PerformanceSummary calculateSummary(
    List<DailyRecordModel> records,
    BatchModel batch,
  ) {
    if (records.isEmpty) {
      return const PerformanceSummary(
        currentDay: 0,
        currentMortalityPct: 0,
        currentAvgWeightGrams: 0,
        currentFcr: null,
        totalFeedKg: 0,
        pef: null,
      );
    }
    final sorted = [...records]
      ..sort((a, b) => a.batchAgeDay.compareTo(b.batchAgeDay));
    final lastRec = sorted.last;
    final currentDay = lastRec.batchAgeDay;
    final totalFeed = sorted.fold(0.0, (s, r) => s + r.feedConsumedKg);
    final mortalityPct = calculateCumulativeMortalityPct(
      records,
      batch.totalBirds,
      currentDay,
    );
    final fcr = calculateCumulativeFcr(records, currentDay);
    final pef = calculatePef(records, batch.totalBirds, currentDay);
    return PerformanceSummary(
      currentDay: currentDay,
      currentMortalityPct: mortalityPct,
      currentAvgWeightGrams: lastRec.avgWeightGrams,
      currentFcr: fcr,
      totalFeedKg: totalFeed,
      pef: pef,
    );
  }
}

class WeeklyMortality {
  const WeeklyMortality({
    required this.week,
    required this.deaths,
    required this.pct,
  });

  final int week;
  final int deaths;
  final double pct;
}

class PerformanceSummary {
  const PerformanceSummary({
    required this.currentDay,
    required this.currentMortalityPct,
    required this.currentAvgWeightGrams,
    required this.currentFcr,
    required this.totalFeedKg,
    required this.pef,
  });

  final int currentDay;
  final double currentMortalityPct;
  final double currentAvgWeightGrams;
  final double totalFeedKg;
  final double? currentFcr;
  final double? pef;
}
