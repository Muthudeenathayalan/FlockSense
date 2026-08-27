import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class AiContextBuilder {
  AiContextBuilder._();

  static Future<String> buildFarmContext({
    String? farmId,
    String? batchId,
  }) async {
    try {
      final filter = ReportFilterState(
        selectedFarmId: farmId,
        selectedBatchId: batchId,
      );

      final data = await ReportService.loadFilteredReportData(
        filter: filter,
      ).timeout(const Duration(seconds: 2));
      return formatReportDataToPromptContext(data);
    } catch (e) {
      return 'Context: Live farm snapshot temporarily unavailable. Answer general poultry queries using expert standards.';
    }
  }

  static String formatReportDataToPromptContext(ReportData data) {
    final farm = data.farm;
    final batch = data.batch;
    final recs = data.dailyRecords.take(10).toList();

    final buffer = StringBuffer();
    buffer.writeln('=== FLOCKSENSE LIVE FARM TELEMETRY CONTEXT ===');
    buffer.writeln('Farm Name: ${farm.farmName} (${farm.farmType})');
    buffer.writeln(
      'Location: ${farm.address.isNotEmpty ? farm.address : "Tamil Nadu, India"}',
    );
    buffer.writeln('Farmer/Owner: ${farm.farmerName ?? "Farm Manager"}');
    buffer.writeln(
      'Current Active Batch: ${batch.batchName} (${batch.breedOrFlockType})',
    );
    buffer.writeln(
      'Placement Count: ${batch.totalBirds} birds | Current Live Count: ${batch.currentBirds} birds',
    );
    buffer.writeln('Flock Mean Age: ${data.meanAge} Days');
    buffer.writeln(
      'Cumulative Mortality: ${data.totalMortality} birds (${(100 - data.liveabilityPct).toStringAsFixed(2)}% loss rate | Risk: ${data.mortalityRiskLevel})',
    );
    buffer.writeln(
      'Weight Metrics: Avg Weight=${(data.avgBodyWeightGrams ?? 0).toStringAsFixed(0)}g | Standard=${data.expectedWeightGrams.toStringAsFixed(0)}g | Diff=${data.weightDiffGrams.toStringAsFixed(0)}g | ADG=${data.adgGrams.toStringAsFixed(1)}g/day',
    );
    buffer.writeln(
      'Feed & Water Metrics: Total Feed=${data.totalFeedKg.toStringAsFixed(0)}kg | FCR=${data.overallFcr?.toStringAsFixed(2) ?? "1.55"} | Avg Feed/Bird=${data.avgFeedPerBirdGrams.toStringAsFixed(0)}g | Total Water=${data.totalWaterLiters.toStringAsFixed(0)}L',
    );
    buffer.writeln(
      'Financial Summary: Gross Revenue=₹${data.totalRevenue.toStringAsFixed(0)} | Total Expenses=₹${data.totalExpenses.toStringAsFixed(0)} | Net Operating Profit=₹${data.netProfit.toStringAsFixed(0)} (ROI: ${data.roiPct.toStringAsFixed(1)}%)',
    );
    buffer.writeln(
      'Overall Farm Score: ${data.overallScore}/100 (${data.overallHealthGrade.toUpperCase()}) | Rating: ${data.starRating} Stars',
    );

    if (data.vaccineRecords.isNotEmpty) {
      buffer.writeln(
        'Recent Vaccines: ${data.vaccineRecords.take(5).map((v) => "${v.vaccineName} (Day ${v.batchAgeDay})").join(", ")}',
      );
    }
    if (data.medicineRecords.isNotEmpty) {
      buffer.writeln(
        'Recent Treatments: ${data.medicineRecords.take(5).map((m) => "${m.medicineName} (Day ${m.batchAgeDay})").join(", ")}',
      );
    }
    if (data.inventoryItems.isNotEmpty) {
      final lowStock = data.inventoryItems
          .where((i) => i.isLowStock)
          .map((i) => "${i.itemName} (${i.quantityAvailable}${i.unit})")
          .join(", ");
      buffer.writeln(
        'Low Stock Alerts: ${lowStock.isNotEmpty ? lowStock : "None (Stock levels healthy)"}',
      );
    }

    if (recs.isNotEmpty) {
      buffer.writeln('Recent Daily Log Snapshots:');
      for (final r in recs.take(5)) {
        buffer.writeln(
          ' - Day ${r.batchAgeDay}: Birds=${r.closingBirds}, Mort=${r.mortalityCount}, Feed=${r.feedConsumedKg}kg, Water=${r.waterConsumedLiters}L, Weight=${r.avgWeightGrams}g',
        );
      }
    }

    buffer.writeln('=== END OF LIVE CONTEXT ===');
    buffer.writeln(
      'INSTRUCTIONS FOR AI: Use this exact real telemetry when giving recommendations, diagnosis, chart insights, or farm guidance. Do not mention that context was supplied automatically. Be helpful, concise, professional, and practical.',
    );

    return buffer.toString();
  }
}
