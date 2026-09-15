import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class AiContextBuilder {
  AiContextBuilder._();

  /// Builds a comprehensive live telemetry context snapshot from Firebase Firestore.
  static Future<String> buildFarmContext({
    String? farmId,
    String? batchId,
  }) async {
    try {
      final filter = ReportFilterState(
        selectedFarmId: farmId,
        selectedBatchId: batchId,
      );

      // Increased timeout to 12 seconds to ensure Firestore multi-collection reads complete reliably
      final data = await ReportService.loadFilteredReportData(
        filter: filter,
      ).timeout(const Duration(seconds: 12));

      return formatReportDataToPromptContext(data);
    } catch (e) {
      debugPrint('[AiContextBuilder] Error querying Firebase farm data: $e');
      return 'Context: Live farm snapshot temporarily unavailable. Answer general poultry queries using expert standards.';
    }
  }

  /// Formats all Firebase farm, flock, climate, health, and financial data into a rich prompt context.
  static String formatReportDataToPromptContext(ReportData data) {
    if (data.farms.isEmpty ||
        (data.farm.farmName == 'No Farm Selected' &&
            data.batch.totalBirds == 0)) {
      return '''=== NO ACTIVE FARM OR FLOCK DATA LOGGED IN FIREBASE ===
User currently has 0 registered farms or 0 active birds placed.
INSTRUCTIONS FOR AI: If the user asks to analyze their farm or check live flock health, inform them clearly that no active farm or flock telemetry is currently logged in Firebase. Direct them to set up a farm in the Farms tab and place a batch with daily records. Answer general poultry knowledge queries accurately using standard guidelines.''';
    }

    final farm = data.farm;
    final batch = data.batch;
    final recs = data.dailyRecords.take(10).toList();

    String? authUser;
    try {
      final user = FirebaseAuth.instance.currentUser;
      authUser = user?.displayName ?? user?.email;
    } catch (_) {
      // Offline / unit test fallback
    }

    final buffer = StringBuffer();
    buffer.writeln('=== FLOCKSENSE REAL-TIME FIREBASE FARM TELEMETRY ===');

    // 1. Account & Farmer Identity
    final farmerName = (farm.farmerName != null && farm.farmerName!.isNotEmpty)
        ? farm.farmerName!
        : (authUser ?? 'Farm Owner');
    buffer.writeln('Farmer/Account: $farmerName');

    // 2. Primary Farm Facility
    final facilityType = farm.farmType.isNotEmpty ? farm.farmType : 'Commercial Broiler';
    final dimensions = (farm.lengthFt > 0 && farm.widthFt > 0)
        ? ' (${farm.lengthFt.toStringAsFixed(0)}x${farm.widthFt.toStringAsFixed(0)} ft, ${farm.totalSqFt.toStringAsFixed(0)} sqft)'
        : '';
    buffer.writeln('Active Farm: ${farm.farmName} [$facilityType]$dimensions');
    if (farm.address.isNotEmpty) {
      buffer.writeln('Facility Location: ${farm.address}');
    }

    // Other facilities in Firebase if multi-farm
    if (data.farms.length > 1) {
      final otherFarms = data.farms
          .where((f) => f.id != farm.id)
          .map((f) => '${f.farmName} (${f.farmType})')
          .join(', ');
      buffer.writeln('Other Facilities in Firebase (${data.farms.length} total): $otherFarms');
    }

    // 3. Active Flock / Batch
    buffer.writeln(
      'Active Batch/Flock: ${batch.batchName} [Breed: ${batch.breedOrFlockType}, Status: ${batch.status}]',
    );
    buffer.writeln(
      'Flock Population: Initial Placed=${batch.totalBirds} birds | Current Live=${batch.currentBirds} birds | Mean Age=${data.meanAge} Days',
    );

    // Other batches on this farm
    if (data.batches.length > 1) {
      final otherBatches = data.batches
          .where((b) => b.id != batch.id)
          .map((b) => '${b.batchName} (${b.currentBirds} birds, ${b.status})')
          .join(', ');
      buffer.writeln('Other Batches in Facility: $otherBatches');
    }

    // Historical / Past Batches in Facility
    final closedBatches = data.batches
        .where((b) => b.id != batch.id && (!b.isActive || b.status.toLowerCase() == 'completed'))
        .toList();
    if (closedBatches.isNotEmpty) {
      final historyStr = closedBatches
          .map((b) => '${b.batchName} (Placed: ${b.placementDate.day}/${b.placementDate.month}/${b.placementDate.year}, ${b.totalBirds} chicks, ${b.breedOrFlockType})')
          .join('; ');
      buffer.writeln('Historical/Past Batches Archive (${closedBatches.length} completed): $historyStr');
    }

    // 4. Mortality & Health Risk
    final lossRate = (100 - data.liveabilityPct).clamp(0, 100);
    buffer.writeln(
      'Mortality Analytics: Cumulative Loss=${data.totalMortality} birds (${lossRate.toStringAsFixed(2)}% mortality rate | Liveability: ${data.liveabilityPct.toStringAsFixed(2)}% | Risk Level: ${data.mortalityRiskLevel})',
    );

    // 5. Growth, Weight & ADG vs Standard
    final avgWeight = data.avgBodyWeightGrams ?? 0;
    final expWeight = data.expectedWeightGrams;
    final diffWeight = data.weightDiffGrams;
    final diffLabel = diffWeight >= 0
        ? '+${diffWeight.toStringAsFixed(0)}g ahead of standard'
        : '${diffWeight.toStringAsFixed(0)}g below standard';
    buffer.writeln(
      'Body Weight & Growth: Current Avg=${avgWeight.toStringAsFixed(0)}g | Breed Standard=${expWeight.toStringAsFixed(0)}g ($diffLabel) | ADG=${data.adgGrams.toStringAsFixed(1)}g/day',
    );

    // 6. Feed & Water Efficiency (FCR)
    final fcrStr = data.overallFcr?.toStringAsFixed(2) ?? '1.55';
    buffer.writeln(
      'Feed & Water Efficiency: Total Feed Consumed=${data.totalFeedKg.toStringAsFixed(0)}kg | Estimated FCR=$fcrStr | Daily Feed/Bird=${data.avgFeedPerBirdGrams.toStringAsFixed(0)}g | Total Water Intake=${data.totalWaterLiters.toStringAsFixed(0)}L',
    );

    // 7. Algorithmic Diagnostics from Real Data
    if (data.detectedProblems.isNotEmpty) {
      buffer.writeln('FlockSense Algorithmic Diagnostics (from Firestore):');
      for (final p in data.detectedProblems) {
        buffer.writeln(' - [${p.severity.toUpperCase()}] ${p.title}: ${p.description}');
      }
    }

    // 8. Financial Telemetry
    buffer.writeln(
      'Financial Telemetry: Gross Revenue=₹${data.totalRevenue.toStringAsFixed(0)} | Operating Expenses=₹${data.totalExpenses.toStringAsFixed(0)} | Net Operating Profit=₹${data.netProfit.toStringAsFixed(0)} (ROI: ${data.roiPct.toStringAsFixed(1)}%)',
    );
    if (data.birdSales.isNotEmpty) {
      final totalSold = data.birdSales.fold<int>(0, (sum, s) => sum + s.birdsSold);
      final totalKg = data.birdSales.fold<double>(
        0,
        (sum, s) => sum + (s.birdsSold * s.averageWeightKg),
      );
      buffer.writeln(
        'Sales Summary: $totalSold birds harvested and sold ($totalKg kg total)',
      );
    }

    // 9. Clinical Treatments (Vaccines & Medications)
    if (data.vaccineRecords.isNotEmpty) {
      final vacList = data.vaccineRecords
          .take(5)
          .map((v) => '${v.vaccineName} (Day ${v.batchAgeDay})')
          .join(', ');
      buffer.writeln('Administered Vaccines: $vacList');
    }
    if (data.medicineRecords.isNotEmpty) {
      final medList = data.medicineRecords
          .take(5)
          .map((m) => '${m.medicineName} (Day ${m.batchAgeDay})')
          .join(', ');
      buffer.writeln('Administered Medications: $medList');
    }

    // 10. Shed Infrastructure & Inventory
    if (data.sheds.isNotEmpty) {
      final shedList = data.sheds
          .map((s) => '${s.shedName} (${s.capacity} cap)')
          .join(', ');
      buffer.writeln('Shed Infrastructure (${data.sheds.length} sheds): $shedList');
    }
    if (data.inventoryItems.isNotEmpty) {
      final lowStock = data.inventoryItems
          .where((i) => i.isLowStock)
          .map((i) => '${i.itemName} (${i.quantityAvailable}${i.unit})')
          .join(', ');
      buffer.writeln(
        'Inventory Status: ${data.inventoryItems.length} items logged | Low Stock Alert: ${lowStock.isNotEmpty ? lowStock : "None (Healthy)"}',
      );
    }

    // 11. Recent Daily Logs with Climate / Environmental Sensors
    if (recs.isNotEmpty) {
      buffer.writeln('Recent Daily Telemetry Logs (from Firebase):');
      for (final r in recs.take(7)) {
        final envParts = <String>[];
        if (r.temperature != null && r.temperature! > 0) {
          envParts.add('${r.temperature}°C');
        }
        if (r.humidity != null && r.humidity! > 0) {
          envParts.add('${r.humidity}% RH');
        }
        if (r.weather != null && r.weather!.isNotEmpty) {
          envParts.add(r.weather!);
        }
        final envStr = envParts.isNotEmpty ? ' | Env: [${envParts.join(", ")}]' : '';
        final notesStr = (r.notes != null && r.notes!.trim().isNotEmpty)
            ? ' | Notes: "${r.notes!.trim()}"'
            : '';

        buffer.writeln(
          ' - Day ${r.batchAgeDay}: Live=${r.closingBirds}, Mort=${r.mortalityCount}, Culls=${r.cullCount}, Feed=${r.feedConsumedKg}kg, Water=${r.waterConsumedLiters}L, AvgWt=${r.avgWeightGrams}g$envStr$notesStr',
        );
      }
    }

    buffer.writeln('=== END OF LIVE FIREBASE CONTEXT ===');
    buffer.writeln('''INSTRUCTIONS FOR AI:
- You have direct access to the farmer's live Firebase database records above.
- When the farmer asks about their flock, farm, mortality, weight, feed, FCR, climate, or finances, analyze and quote their actual numbers from this telemetry.
- Provide proactive veterinarian guidance, pinpointing any critical or warning deviations from standard Cobb/Ross growth curves.
- If the user asks about multiple batches or other farms, reference the facilities and batches listed above.
- Address the user practically as a veterinary consultant and farm specialist.''');

    return buffer.toString();
  }
}
