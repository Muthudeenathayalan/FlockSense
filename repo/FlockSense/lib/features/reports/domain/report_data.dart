import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';

typedef BirdSaleModel = SalesRecordModel;

const Map<int, double> kStandardBodyWeightGrams = {
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

class DetectedProblem {
  final String title;
  final String severity; // 'Critical', 'Warning', 'Normal'
  final String description;

  const DetectedProblem({
    required this.title,
    required this.severity,
    required this.description,
  });
}

class FarmingTechniqueInsight {
  final String title;
  final String category; // 'Feeding & FCR', 'Brooding Management', 'Water & Litter Hygiene', 'Climate & Ventilation', 'Health & Biosecurity'
  final String severity; // 'Critical', 'Warning', 'Advantage'
  final String metricObserved;
  final String techniqueFlaw;
  final String correctiveAction;
  final double? financialImpactRs;
  final bool isDisadvantage;

  const FarmingTechniqueInsight({
    required this.title,
    required this.category,
    required this.severity,
    required this.metricObserved,
    required this.techniqueFlaw,
    required this.correctiveAction,
    this.financialImpactRs,
    this.isDisadvantage = true,
  });
}

class ReportData {
  const ReportData({
    required this.farm,
    required this.batch,
    required this.farms,
    required this.batches,
    required this.sheds,
    required this.dailyRecords,
    required this.feedTransactions,
    required this.medicineRecords,
    required this.vaccineRecords,
    required this.birdSales,
    required this.inventoryItems,
    required this.generatedAt,
  });

  final FarmModel farm;
  final BatchModel batch;
  final List<FarmModel> farms;
  final List<BatchModel> batches;
  final List<ShedModel> sheds;
  final List<DailyRecordModel> dailyRecords;
  final List<FeedTransactionModel> feedTransactions;
  final List<MedicineRecordModel> medicineRecords;
  final List<VaccineRecordModel> vaccineRecords;
  final List<BirdSaleModel> birdSales;
  final List<InventoryItemModel> inventoryItems;
  final DateTime generatedAt;

  int get totalMortality => dailyRecords.fold(
    0,
    (sum, record) => sum + record.mortalityCount + record.cullCount,
  );

  double get totalFeedKg {
    if (feedTransactions.isNotEmpty) {
      return feedTransactions.fold(0.0, (sum, t) => sum + t.weightKg);
    }
    return dailyRecords.fold(0.0, (sum, r) => sum + r.feedConsumedKg);
  }

  double get totalWaterLiters =>
      dailyRecords.fold(0.0, (sum, r) => sum + r.waterConsumedLiters);

  int get totalBirdsSold =>
      birdSales.fold(0, (sum, sale) => sum + sale.birdsSold);

  double get totalSaleWeightKg => birdSales.fold(
    0.0,
    (sum, sale) => sum + (sale.birdsSold * sale.averageWeightKg),
  );

  double get totalRevenue =>
      birdSales.fold(0.0, (sum, sale) => sum + sale.totalValue);

  double get totalExpenses {
    final feedCost = totalFeedKg * 42.0;
    final medCost = medicineRecords.fold(
      0.0,
      (sum, m) => sum + (m.valueRs ?? 0.0),
    );
    final vaccineCost = 0.0;
    final chickCost = batch.totalBirds * 35.0;
    return feedCost + medCost + vaccineCost + chickCost;
  }

  double get netProfit => totalRevenue - totalExpenses;

  double get liveabilityPct {
    if (batch.totalBirds <= 0) return 0.0;
    final initial = batch.totalBirds;
    return (((initial - totalMortality) / initial) * 100.0).clamp(0.0, 100.0);
  }

  double? get overallFcr {
    final lastRec = _latestRecord;
    if (lastRec == null || lastRec.avgWeightGrams <= 0 || totalFeedKg <= 0) {
      return null;
    }
    final liveBirds = lastRec.closingBirds > 0
        ? lastRec.closingBirds
        : (batch.totalBirds - totalMortality);
    final totalBiomassKg = liveBirds * (lastRec.avgWeightGrams / 1000.0);
    if (totalBiomassKg <= 0) return null;
    return totalFeedKg / totalBiomassKg;
  }

  double? get avgBodyWeightGrams {
    final lastRec = _latestRecord;
    if (lastRec == null || lastRec.avgWeightGrams <= 0) return null;
    return lastRec.avgWeightGrams;
  }

  int get meanAge {
    final lastRec = _latestRecord;
    if (lastRec != null) return lastRec.batchAgeDay;
    if (batch.placementDate.isBefore(DateTime.now())) {
      return (DateTime.now().difference(batch.placementDate).inDays + 1)
          .clamp(0, 365);
    }
    return 0;
  }

  double? get pef {
    final fcr = overallFcr;
    final wt = avgBodyWeightGrams;
    if (fcr == null || fcr <= 0 || wt == null || wt <= 0 || meanAge <= 0) {
      return null;
    }
    final wtKg = wt / 1000.0;
    return (liveabilityPct * wtKg) / (meanAge * fcr) * 100;
  }

  DailyRecordModel? get _latestRecord {
    if (dailyRecords.isEmpty) return null;
    return dailyRecords.reduce(
      (current, next) =>
          current.batchAgeDay >= next.batchAgeDay ? current : next,
    );
  }

  // --- Extended Intelligence Metrics ---

  double get adgGrams {
    final age = meanAge;
    final wt = avgBodyWeightGrams;
    if (age <= 0 || wt == null || wt <= 42.0) return 0.0;
    return (wt - 42.0) / age;
  }

  double get expectedWeightGrams => kStandardBodyWeightGrams[meanAge] ?? 0.0;

  double get weightDiffGrams {
    final wt = avgBodyWeightGrams;
    if (wt == null || expectedWeightGrams <= 0) return 0.0;
    return wt - expectedWeightGrams;
  }

  double get growthRatePct {
    final wt = avgBodyWeightGrams;
    if (wt == null || expectedWeightGrams <= 0) return 0.0;
    return (((wt) / expectedWeightGrams) * 100.0).clamp(0.0, 200.0);
  }

  double get feedRemainingKg {
    final stockBags = inventoryItems
        .where((i) => i.category.toLowerCase().contains('feed'))
        .fold(0.0, (sum, item) => sum + item.quantityAvailable);
    return stockBags * 50.0; // 50kg per bag
  }

  double get avgFeedPerBirdGrams {
    if (batch.currentBirds <= 0 || _latestRecord == null) return 0.0;
    final dailyFeedKg = _latestRecord!.feedConsumedKg;
    return (dailyFeedKg * 1000.0) / batch.currentBirds;
  }

  double get avgWaterPerBirdMl {
    if (batch.currentBirds <= 0 || _latestRecord == null) return 0.0;
    final dailyWaterL = _latestRecord!.waterConsumedLiters;
    return (dailyWaterL * 1000.0) / batch.currentBirds;
  }

  double get maxDailyWaterLiters => dailyRecords.isEmpty
      ? 0.0
      : dailyRecords
            .map((r) => r.waterConsumedLiters)
            .reduce((a, b) => a > b ? a : b);

  double get minDailyWaterLiters => dailyRecords.isEmpty
      ? 0.0
      : dailyRecords
            .map((r) => r.waterConsumedLiters)
            .reduce((a, b) => a < b ? a : b);

  String get mortalityRiskLevel {
    if (batch.totalBirds <= 0) return 'None';
    final mortPct = 100.0 - liveabilityPct;
    if (mortPct > 5.0) return 'Critical';
    if (mortPct > 3.0) return 'High';
    if (mortPct > 1.5) return 'Moderate';
    return 'Low';
  }

  double get roiPct {
    if (totalExpenses <= 0) return 0.0;
    return (netProfit / totalExpenses) * 100.0;
  }

  // --- Scorecard Calculations (0 - 100) ---

  int get growthScore {
    final wt = avgBodyWeightGrams;
    if (wt == null || expectedWeightGrams <= 0) return 0;
    final ratio = wt / expectedWeightGrams;
    return (ratio * 92.0).clamp(0.0, 100.0).round();
  }

  int get healthScore {
    if (batch.totalBirds <= 0) return 0;
    final score = liveabilityPct - (medicineRecords.length * 1.5);
    return score.clamp(0.0, 100.0).round();
  }

  int get feedScore {
    final fcr = overallFcr;
    if (fcr == null || fcr <= 0) return 0;
    if (fcr <= 1.45) return 98;
    if (fcr <= 1.55) return 92;
    if (fcr <= 1.65) return 84;
    if (fcr <= 1.75) return 74;
    return 60;
  }

  int get profitScore {
    if (totalExpenses <= 0 && totalRevenue <= 0) return 0;
    if (roiPct >= 25) return 96;
    if (roiPct >= 15) return 90;
    if (roiPct >= 5) return 80;
    if (roiPct >= 0) return 65;
    return 40;
  }

  int get mortalityScore {
    if (batch.totalBirds <= 0) return 0;
    final mortPct = 100.0 - liveabilityPct;
    if (mortPct <= 1.5) return 96;
    if (mortPct <= 3.0) return 86;
    if (mortPct <= 5.0) return 72;
    return 50;
  }

  int get inventoryScore {
    if (inventoryItems.isEmpty) return 0;
    final lowStockCount = lowStockItems.length;
    final expCount = expiringItems.length;
    final score = 95 - (lowStockCount * 8) - (expCount * 12);
    return score.clamp(0, 100);
  }

  int get overallScore {
    if (batch.totalBirds <= 0 || dailyRecords.isEmpty) return 0;
    return ((growthScore +
                healthScore +
                feedScore +
                profitScore +
                mortalityScore +
                inventoryScore) /
            6)
        .round();
  }

  int get starRating {
    if (overallScore == 0) return 0;
    if (overallScore >= 90) return 5;
    if (overallScore >= 80) return 4;
    if (overallScore >= 70) return 3;
    if (overallScore >= 60) return 2;
    return 1;
  }

  String get overallHealthGrade {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Good';
    if (overallScore >= 70) return 'Average';
    if (overallScore >= 60) return 'Needs Improvement';
    return 'Critical';
  }

  // --- Dynamic Content Generators ---

  List<String> get aiInsights {
    final insights = <String>[];
    if (growthScore >= 88) {
      insights.add(
        'Bird growth performance is excellent, matching benchmark Cobb 500 standard curves.',
      );
    } else {
      insights.add(
        'Average bird weight is slightly below expected curve; evaluate feed nutrient density.',
      );
    }

    if (overallFcr != null && overallFcr! <= 1.60) {
      insights.add(
        'Feed conversion ratio (FCR ${overallFcr!.toStringAsFixed(2)}) is optimized for profitable harvest.',
      );
    }

    if (liveabilityPct >= 96.5) {
      insights.add(
        'Mortality rate is low (${(100.0 - liveabilityPct).toStringAsFixed(2)}%), indicating robust flock biosecurity.',
      );
    } else {
      insights.add(
        'Elevated mortality detected; monitor ventilation and water sanitation protocols.',
      );
    }

    if (vaccineRecords.isNotEmpty) {
      insights.add(
        'Vaccination schedule is active with ${vaccineRecords.length} completed treatments.',
      );
    }

    if (netProfit > 0) {
      insights.add(
        'Financial trend is positive with estimated net margin of ₹${netProfit.toStringAsFixed(0)} (${roiPct.toStringAsFixed(1)}% ROI).',
      );
    }

    if (lowStockItems.isEmpty) {
      insights.add(
        'Inventory buffer is sufficient for the next 14 days of operations.',
      );
    } else {
      insights.add(
        'Low stock alert triggered for ${lowStockItems.length} inventory categories.',
      );
    }

    return insights;
  }

  List<DetectedProblem> get detectedProblems {
    final problems = <DetectedProblem>[];

    final mortPct = 100.0 - liveabilityPct;
    if (mortPct > 4.0) {
      problems.add(
        const DetectedProblem(
          title: 'Elevated Mortality Rate',
          severity: 'Critical',
          description:
              'Cumulative mortality exceeds 4.0% threshold. Immediate post-mortem and vet consultation advised.',
        ),
      );
    } else if (mortPct > 2.5) {
      problems.add(
        const DetectedProblem(
          title: 'Moderate Mortality Spike',
          severity: 'Warning',
          description:
              'Mortality rate is above normal 2.0% baseline. Check shed temperature and water line hygiene.',
        ),
      );
    }

    if ((overallFcr ?? 1.55) > 1.68) {
      problems.add(
        const DetectedProblem(
          title: 'Suboptimal Feed Conversion (FCR)',
          severity: 'Warning',
          description:
              'FCR is higher than target 1.55. Inspect for feed wastage, feeder height, or gut health issues.',
        ),
      );
    }

    if (lowStockItems.isNotEmpty) {
      problems.add(
        DetectedProblem(
          title: 'Inventory Stock Depletion',
          severity: 'Warning',
          description:
              '${lowStockItems.length} essential inventory item(s) are below minimum threshold safety levels.',
        ),
      );
    }

    if (expiringItems.isNotEmpty) {
      problems.add(
        DetectedProblem(
          title: 'Expiring Medications/Vaccines',
          severity: 'Warning',
          description:
              '${expiringItems.length} item(s) in cold storage will expire within 30 days.',
        ),
      );
    }

    if (problems.isEmpty) {
      problems.add(
        const DetectedProblem(
          title: 'All System Operations Normal',
          severity: 'Normal',
          description:
              'No critical telemetry anomalies or biosecurity violations detected.',
        ),
      );
    }

    return problems;
  }

  List<String> get recommendations {
    final recs = <String>[];
    if (growthRatePct < 98) {
      recs.add(
        'Increase amino acid and protein density in finisher feed formula by 2%.',
      );
    }
    if (liveabilityPct < 97) {
      recs.add(
        'Sanitize water lines with chlorine dioxide solution to reduce bacterial load.',
      );
    }
    if ((overallFcr ?? 1.55) > 1.60) {
      recs.add(
        'Adjust feeder pan height to bird shoulder height to eliminate feed spillage.',
      );
    }
    if (lowStockItems.isNotEmpty) {
      recs.add(
        'Place purchase order for feed and medicine replenish within 48 hours.',
      );
    }
    recs.add(
      'Maintain brooding/tunnel ventilation air velocity at 2.5 m/s for optimal heat stress prevention.',
    );
    recs.add(
      'Schedule pre-harvest bird weighing 5 days prior to final batch catch.',
    );
    return recs;
  }

  List<InventoryItemModel> get lowStockItems =>
      inventoryItems.where((item) => item.isLowStock).toList();

  List<InventoryItemModel> get expiringItems {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return inventoryItems.where((item) {
      final exp = item.expiryDate;
      return exp != null && exp.isBefore(thirtyDaysFromNow);
    }).toList();
  }

  // --- Farming Technique Disadvantages & Audit Engine ---

  double get totalBiomassKg {
    final lastRec = _latestRecord;
    final liveBirds = (lastRec != null && lastRec.closingBirds > 0)
        ? lastRec.closingBirds
        : (batch.totalBirds - totalMortality);
    final wtGrams = avgBodyWeightGrams ?? 0.0;
    return (liveBirds * wtGrams) / 1000.0;
  }

  double get waterToFeedRatio {
    if (totalFeedKg <= 0 || totalWaterLiters <= 0) return 0.0;
    return totalWaterLiters / totalFeedKg;
  }

  double get excessFeedKg {
    final fcr = overallFcr;
    if (fcr == null || fcr <= 1.55) return 0.0;
    final biomass = totalBiomassKg;
    if (biomass <= 0) return 0.0;
    return (fcr - 1.55) * biomass;
  }

  double get excessFeedCostRs => excessFeedKg * 42.0;

  int get firstWeekMortalityCount {
    return dailyRecords
        .where((r) => r.batchAgeDay <= 7)
        .fold(0, (sum, r) => sum + r.mortalityCount + r.cullCount);
  }

  double get firstWeekMortalityPct {
    if (batch.totalBirds <= 0) return 0.0;
    return (firstWeekMortalityCount / batch.totalBirds) * 100.0;
  }

  double get maxRecordedTemp {
    final temps = dailyRecords
        .map((r) => r.temperature)
        .where((t) => t != null && t > 0)
        .map((t) => t!)
        .toList();
    if (temps.isEmpty) return 0.0;
    return temps.reduce((a, b) => a > b ? a : b);
  }

  List<FarmingTechniqueInsight> get techniqueDisadvantages {
    final list = <FarmingTechniqueInsight>[];

    // 1. Feeding Technique: Feeder Pan Height & Spillage (FCR > 1.60)
    final fcr = overallFcr;
    if (fcr != null && fcr > 1.60) {
      final fcrDiff = fcr - 1.55;
      final cost = excessFeedCostRs > 0 ? excessFeedCostRs : 12500.0;
      list.add(
        FarmingTechniqueInsight(
          title: 'Feed Wastage & Feeder Height Sub-Optimal',
          category: 'Feeding & FCR',
          severity: fcr > 1.70 ? 'Critical' : 'Warning',
          metricObserved:
              'FCR ${fcr.toStringAsFixed(2)} vs target 1.55 (+${fcrDiff.toStringAsFixed(2)})',
          techniqueFlaw:
              'Feeder pans are set too low or pans flooded too deep, allowing birds to flick pellets onto floor litter.',
          correctiveAction:
              'Raise feeder lines so pan lip is level with birds\' backs. Adjust feed flow regulator slide to 1/3 pan depth.',
          financialImpactRs: cost,
          isDisadvantage: true,
        ),
      );
    }

    // 2. Watering & Litter Hygiene: Imbalanced Water-to-Feed Ratio
    final wfRatio = waterToFeedRatio;
    if (wfRatio > 2.20) {
      final leakageCost =
          (batch.totalBirds * 0.02 * 180.0).clamp(1500.0, 45000.0);
      list.add(
        FarmingTechniqueInsight(
          title: 'Drinker Line Leaks / Wet Litter Risk',
          category: 'Water & Litter Hygiene',
          severity: wfRatio > 2.40 ? 'Critical' : 'Warning',
          metricObserved:
              'Water:Feed ratio is ${wfRatio.toStringAsFixed(2)}:1 (normal: 1.80:1 – 2.00:1)',
          techniqueFlaw:
              'Nipple water pressure is set too high or subclinical enteritis is driving flushing, creating wet litter and toxic ammonia.',
          correctiveAction:
              'Reduce water column pressure to 20-25cm. Check nipple seals for drips. Acidify water to pH 6.0.',
          financialImpactRs: leakageCost,
          isDisadvantage: true,
        ),
      );
    } else if (wfRatio > 0 && wfRatio < 1.65) {
      final lostGrowthCost =
          ((expectedWeightGrams - (avgBodyWeightGrams ?? expectedWeightGrams))
                  .abs() *
              batch.totalBirds *
              0.10).clamp(1000.0, 30000.0);
      list.add(
        FarmingTechniqueInsight(
          title: 'Restricted Water Flow & Reduced Feed Appetite',
          category: 'Water & Litter Hygiene',
          severity: 'Warning',
          metricObserved:
              'Water:Feed ratio is low at ${wfRatio.toStringAsFixed(2)}:1',
          techniqueFlaw:
              'Drinker nipples are blocked by bio-film or line pressure is deficient, preventing birds from drinking and eating.',
          correctiveAction:
              'Flush water lines with high-pressure pulse. Measure flow rate at end of line (target: >60ml/min/nipple).',
          financialImpactRs: lostGrowthCost,
          isDisadvantage: true,
        ),
      );
    }

    // 3. Brooding Technique: 7-Day Weight Deficit
    if (meanAge >= 7 &&
        (weightDiffGrams < -40.0 ||
            (growthRatePct > 0 && growthRatePct < 94.0))) {
      final deficit = weightDiffGrams.abs();
      final weightLossCost =
          ((deficit / 1000.0) * batch.totalBirds * 110.0).clamp(2000.0, 50000.0);
      list.add(
        FarmingTechniqueInsight(
          title: 'Brooding Weight Lag & Cold Stress',
          category: 'Brooding Management',
          severity: weightDiffGrams < -80.0 ? 'Critical' : 'Warning',
          metricObserved:
              'Current avg weight is ${(avgBodyWeightGrams ?? 0).toStringAsFixed(0)}g (${deficit.toStringAsFixed(0)}g below standard)',
          techniqueFlaw:
              'Floor concrete was not pre-heated to 32°C prior to chick placement, or chick paper feed area was under 20%.',
          correctiveAction:
              'Pre-heat brooding house 24h before chick arrival. Ensure 95% crop fill is achieved by 24h post-placement.',
          financialImpactRs: weightLossCost,
          isDisadvantage: true,
        ),
      );
    }

    // 4. Early Chick Management: 1st-Week Mortality Spike
    if (firstWeekMortalityPct > 1.0) {
      final chickCost =
          (firstWeekMortalityCount * 45.0).clamp(500.0, 35000.0);
      list.add(
        FarmingTechniqueInsight(
          title: 'Elevated 1st-Week Brooding Mortality',
          category: 'Brooding Management',
          severity: firstWeekMortalityPct > 1.8 ? 'Critical' : 'Warning',
          metricObserved:
              'Week 1 mortality reached ${firstWeekMortalityPct.toStringAsFixed(1)}% ($firstWeekMortalityCount chicks)',
          techniqueFlaw:
              'Dehydration during transit, cold brooding draft, or inadequate drinker tray accessibility.',
          correctiveAction:
              'Provide 5% dextrose + electrolyte water on arrival. Maintain 33°C under brooders with zero floor draft.',
          financialImpactRs: chickCost,
          isDisadvantage: true,
        ),
      );
    }

    // 5. Ventilation & Climate Technique: Heat Stress / Air Velocity
    final peakTemp = maxRecordedTemp;
    if (peakTemp > 31.0) {
      final heatLossCost = (batch.totalBirds * 2.8).clamp(1000.0, 25000.0);
      list.add(
        FarmingTechniqueInsight(
          title: 'Tunnel Air Velocity Inadequate During Heat Peaks',
          category: 'Climate & Ventilation',
          severity: peakTemp > 33.0 ? 'Critical' : 'Warning',
          metricObserved:
              'Peak recorded temp reached ${peakTemp.toStringAsFixed(1)}°C',
          techniqueFlaw:
              'Tunnel fans are staged too late or cooling pads dry out, causing thermal panting and reduced feed digestion.',
          correctiveAction:
              'Engage full tunnel ventilation before shed hits 28°C. Ensure wind-chill airspeed reaches 2.5 m/s.',
          financialImpactRs: heatLossCost,
          isDisadvantage: true,
        ),
      );
    }

    return list;
  }

  List<FarmingTechniqueInsight> get techniqueAdvantages {
    final list = <FarmingTechniqueInsight>[];

    // 1. Biosecurity & Liveability
    if (liveabilityPct >= 96.5 && batch.totalBirds > 0) {
      list.add(
        FarmingTechniqueInsight(
          title: 'Exceptional Biosecurity & Disease Exclusion',
          category: 'Health & Biosecurity',
          severity: 'Advantage',
          metricObserved:
              'Liveability is ${liveabilityPct.toStringAsFixed(1)}% (Mortality: ${(100 - liveabilityPct).toStringAsFixed(1)}%)',
          techniqueFlaw:
              'Strict vehicle disinfection and clean footbath protocol successfully prevented flock disease incursions.',
          correctiveAction:
              'Continue current biosecurity discipline; schedule terminal shed fogging post-harvest.',
          financialImpactRs: null,
          isDisadvantage: false,
        ),
      );
    }

    // 2. Average Daily Gain (ADG)
    if (adgGrams >= 58.0) {
      list.add(
        FarmingTechniqueInsight(
          title: 'Superior Daily Weight Velocity (ADG)',
          category: 'Feeding & FCR',
          severity: 'Advantage',
          metricObserved:
              'ADG is ${adgGrams.toStringAsFixed(1)} g/day (Breed standard: 56.0 g/day)',
          techniqueFlaw:
              'High flock uniformity and optimal feeder spacing allowed birds uninterrupted access to nutrients.',
          correctiveAction:
              'Maintain current feeding schedule and photoperiod program.',
          financialImpactRs: null,
          isDisadvantage: false,
        ),
      );
    }

    // 3. Optimized FCR
    final fcr = overallFcr;
    if (fcr != null && fcr <= 1.55) {
      list.add(
        FarmingTechniqueInsight(
          title: 'High Feed Conversion Efficiency',
          category: 'Feeding & FCR',
          severity: 'Advantage',
          metricObserved: 'FCR is ${fcr.toStringAsFixed(2)} (Benchmark: 1.55)',
          techniqueFlaw:
              'Tight feeder height management prevented billing out and feed spillage into bedding.',
          correctiveAction:
              'Keep feeder heights locked to bird shoulder level as flock continues to grow.',
          financialImpactRs: null,
          isDisadvantage: false,
        ),
      );
    }

    // 4. Vaccination Routine Adherence
    if (vaccineRecords.isNotEmpty) {
      list.add(
        FarmingTechniqueInsight(
          title: 'Proactive Disease Immunization Adherence',
          category: 'Health & Biosecurity',
          severity: 'Advantage',
          metricObserved:
              '${vaccineRecords.length} preventative vaccination rounds logged',
          techniqueFlaw:
              'Flock maintains maternal and acquired antibody titers against Newcastle and Gumboro diseases.',
          correctiveAction:
              'Record booster vaccination dates and cold-chain temperature verification.',
          financialImpactRs: null,
          isDisadvantage: false,
        ),
      );
    }

    // 5. Hydration Balance
    final wfRatio = waterToFeedRatio;
    if (wfRatio >= 1.75 && wfRatio <= 2.15) {
      list.add(
        FarmingTechniqueInsight(
          title: 'Optimal Water-to-Feed Consumption Balance',
          category: 'Water & Litter Hygiene',
          severity: 'Advantage',
          metricObserved:
              'Water:Feed ratio is balanced at ${wfRatio.toStringAsFixed(2)}:1',
          techniqueFlaw:
              'Drinker flow rates match bird appetite without causing wet bedding or ammonia release.',
          correctiveAction:
              'Continue weekly drinker nipple flow-rate checks.',
          financialImpactRs: null,
          isDisadvantage: false,
        ),
      );
    }

    return list;
  }

  double get totalTechniqueFinancialLeakage {
    return techniqueDisadvantages.fold(
      0.0,
      (sum, item) => sum + (item.financialImpactRs ?? 0.0),
    );
  }

  List<String> get techniqueActionPlan {
    final list = <String>[];
    for (final dis in techniqueDisadvantages) {
      list.add('[${dis.category}] ${dis.correctiveAction}');
    }
    if (list.isEmpty) {
      list.add(
        'Maintain current elite management protocols across feeding, water sanitation, and ventilation.',
      );
      list.add(
        'Conduct routine litter moisture checks to keep floor bedding below 25% relative moisture.',
      );
      list.add(
        'Calibrate bird weighing scales 3 days prior to planned batch sale.',
      );
    }
    return list;
  }

  List<Map<String, dynamic>> get benchmarkMatrix {
    final curFcr = overallFcr ?? 1.55;
    final curWt = avgBodyWeightGrams ??
        (expectedWeightGrams > 0 ? expectedWeightGrams : 2000.0);
    final curMort = 100.0 - liveabilityPct;
    final curWf = waterToFeedRatio > 0 ? waterToFeedRatio : 1.85;
    final curAdg = adgGrams > 0 ? adgGrams : 58.0;
    final curPef = pef ?? 320.0;

    return [
      {
        'metric': 'Average Body Weight',
        'actual': '${curWt.toStringAsFixed(0)} g',
        'target':
            '${expectedWeightGrams > 0 ? expectedWeightGrams.toStringAsFixed(0) : "2,050"} g',
        'variance':
            '${weightDiffGrams >= 0 ? "+" : ""}${weightDiffGrams.toStringAsFixed(0)} g',
        'status': weightDiffGrams >= -40 ? 'Optimal' : 'Lagging',
        'isGood': weightDiffGrams >= -40,
        'action': weightDiffGrams >= -40
            ? 'Maintain intake'
            : 'Increase starter protein density',
      },
      {
        'metric': 'Feed Conversion (FCR)',
        'actual': curFcr.toStringAsFixed(2),
        'target': '1.55',
        'variance':
            '${curFcr <= 1.55 ? "-" : "+"}${(curFcr - 1.55).abs().toStringAsFixed(2)}',
        'status': curFcr <= 1.60 ? 'Optimal' : 'Excess Feed',
        'isGood': curFcr <= 1.60,
        'action': curFcr <= 1.60
            ? 'Feeder heights locked'
            : 'Raise pan lip to shoulder height',
      },
      {
        'metric': 'Flock Mortality',
        'actual': '${curMort.toStringAsFixed(1)}%',
        'target': '< 3.0%',
        'variance':
            '${curMort <= 3.0 ? "-" : "+"}${(curMort - 3.0).abs().toStringAsFixed(1)}%',
        'status': curMort <= 3.0
            ? 'Safe'
            : (curMort <= 4.5 ? 'Moderate' : 'Critical'),
        'isGood': curMort <= 3.0,
        'action': curMort <= 3.0
            ? 'Biosecurity strong'
            : 'Sanitize water lines & check litter',
      },
      {
        'metric': 'Water : Feed Ratio',
        'actual': '${curWf.toStringAsFixed(2)}:1',
        'target': '1.85:1',
        'variance': (curWf - 1.85).abs().toStringAsFixed(2),
        'status': (curWf >= 1.75 && curWf <= 2.15) ? 'Balanced' : 'Imbalanced',
        'isGood': (curWf >= 1.75 && curWf <= 2.15),
        'action': (curWf >= 1.75 && curWf <= 2.15)
            ? 'Normal'
            : 'Inspect nipple drinker pressure',
      },
      {
        'metric': 'Average Daily Gain (ADG)',
        'actual': '${curAdg.toStringAsFixed(1)} g/d',
        'target': '58.0 g/d',
        'variance':
            '${curAdg >= 58.0 ? "+" : ""}${(curAdg - 58.0).toStringAsFixed(1)} g/d',
        'status': curAdg >= 56.0 ? 'High' : 'Suboptimal',
        'isGood': curAdg >= 56.0,
        'action': curAdg >= 56.0
            ? 'Fast turn-around'
            : 'Improve brooding temperature',
      },
      {
        'metric': 'Production Index (EPEF)',
        'actual': curPef.toStringAsFixed(0),
        'target': '350+',
        'variance': '${(curPef - 350).toStringAsFixed(0)} pts',
        'status': curPef >= 340 ? 'Excellent' : 'Needs Focus',
        'isGood': curPef >= 340,
        'action': curPef >= 340
            ? 'Top 10% commercial'
            : 'Target FCR reduction to 1.55',
      },
    ];
  }
}

