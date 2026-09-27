import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/flock_plan/domain/daily_plan_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class FlockPlanService {
  FlockPlanService._();

  static const String _prefTaskPrefix = 'flock_plan_task_';

  /// Calculate the bird age in days for the given batch.
  static int getFlockAge(BatchModel batch) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final placement = DateTime(
      batch.placementDate.year,
      batch.placementDate.month,
      batch.placementDate.day,
    );

    if (today.isBefore(placement)) {
      return 1;
    }
    final diff = today.difference(placement).inDays + 1;
    return diff.clamp(1, 60);
  }

  /// Generates the complete, customized daily plan for today.
  static Future<DailyFlockPlan> getTodayPlan({
    required String farmId,
    required BatchModel batch,
  }) async {
    final day = getFlockAge(batch);
    try {
      return await getPlanForSpecificDay(farmId: farmId, batch: batch, day: day);
    } catch (e) {
      debugPrint('[FlockPlanService] getTodayPlan failed, using standard plan fallback: $e');
      return getStandardPlanForDay(batch: batch, day: day);
    }
  }

  /// Synchronous standard benchmark plan fallback for any day.
  static DailyFlockPlan getStandardPlanForDay({
    required BatchModel batch,
    required int day,
  }) {
    final std = FlockLifecycleStandard.getForDay(day);
    final liveBirds = batch.currentBirds > 0 ? batch.currentBirds : batch.totalBirds;
    final totalFeedKg = FlockLifecycleStandard.calculateDailyFeedKg(day, liveBirds);
    final totalWaterLiters = FlockLifecycleStandard.calculateDailyWaterLiters(day, liveBirds);

    final tasks = <DailyPlanTask>[
      DailyPlanTask(
        id: 'log_telemetry_$day',
        title: 'Log Day $day Daily Telemetry',
        description: "Record today's feed consumed, water intake, bird mortality, and weight sampling.",
        category: TaskCategory.diagnostic,
        priority: TaskPriority.critical,
        actionLabel: 'Log Day $day Telemetry',
        actionRoute: '/daily-record',
      ),
      DailyPlanTask(
        id: 'feed_$day',
        title: 'Provide ${totalFeedKg.toStringAsFixed(1)} kg ${std.feedType}',
        description: 'Standard: ${std.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird × $liveBirds live birds.',
        category: TaskCategory.feeding,
        priority: TaskPriority.high,
        actionLabel: 'Analyze Feed',
        actionRoute: '/reports',
      ),
      DailyPlanTask(
        id: 'water_$day',
        title: 'Provide ${totalWaterLiters.toStringAsFixed(0)} L Clean Sanitized Water',
        description: 'Standard: ${std.dailyWaterPerBirdMl.toStringAsFixed(0)} ml/bird × $liveBirds birds. Maintain 2-3 ppm free chlorine.',
        category: TaskCategory.water,
        priority: TaskPriority.routine,
      ),
      DailyPlanTask(
        id: 'env_$day',
        title: 'Set Shed Temp to ${std.targetTempCelsius}°C • ${std.lightingHours}h Light',
        description: 'Observe bird distribution: no huddling (too cold) or panting (too hot).',
        category: TaskCategory.environment,
        priority: TaskPriority.routine,
      ),
    ];

    if (std.vaccineName != null) {
      tasks.add(
        DailyPlanTask(
          id: 'vac_$day',
          title: 'Vaccine Due: ${std.vaccineName!}',
          description: 'Route: ${std.vaccineRoute ?? "Drinking water"}. Administer during cool morning hours.',
          category: TaskCategory.vaccine,
          priority: TaskPriority.critical,
          actionLabel: 'Record Vaccine',
          actionRoute: '/vaccine',
        ),
      );
    }

    if (std.medicineProtocol != null) {
      tasks.add(
        DailyPlanTask(
          id: 'med_$day',
          title: 'Medicine & Health Protocol',
          description: std.medicineProtocol!,
          category: TaskCategory.medicine,
          priority: TaskPriority.high,
          actionLabel: 'Record Medicine',
          actionRoute: '/medicine',
        ),
      );
    }

    for (int i = 0; i < std.managementTasks.length; i++) {
      tasks.add(
        DailyPlanTask(
          id: 'mgmt_${day}_$i',
          title: std.managementTasks[i],
          description: 'Commercial broiler operational protocol for Day $day.',
          category: TaskCategory.environment,
          priority: TaskPriority.routine,
        ),
      );
    }

    return DailyFlockPlan(
      day: day,
      phase: std.phase,
      liveBirds: liveBirds,
      targetWeightGrams: std.targetWeightGrams,
      dailyFeedPerBirdGrams: std.dailyFeedPerBirdGrams,
      totalFeedKg: totalFeedKg,
      dailyWaterPerBirdMl: std.dailyWaterPerBirdMl,
      totalWaterLiters: totalWaterLiters,
      feedType: std.feedType,
      targetTempCelsius: std.targetTempCelsius,
      lightingHours: std.lightingHours,
      vaccineDue: std.vaccineName,
      vaccineRoute: std.vaccineRoute,
      medicineDue: std.medicineProtocol,
      tasks: tasks,
      diagnosticAlerts: const [],
      isRealDataValidated: false,
      hasLoggedTodayRecord: false,
    );
  }

  /// Generates the plan for any specific flock age day (1 to 45+).
  static Future<DailyFlockPlan> getPlanForSpecificDay({
    required String farmId,
    required BatchModel batch,
    required int day,
    List<DailyRecordModel>? prefetchedDailyRecords,
    List<VaccineRecordModel>? prefetchedVaccineRecords,
    List<MedicineRecordModel>? prefetchedMedicineRecords,
    List<InventoryItemModel>? prefetchedInventoryItems,
  }) async {
    final std = FlockLifecycleStandard.getForDay(day);
    final isToday = day == getFlockAge(batch);

    // ─────────────────────────────────────────────────────────────
    // 1. Fetch REAL user data from Firestore (if not prefetched)
    // ─────────────────────────────────────────────────────────────
    DailyRecordModel? todayRecord;
    List<DailyRecordModel> recentRecords = prefetchedDailyRecords ?? [];
    List<VaccineRecordModel> userVaccineRecords = prefetchedVaccineRecords ?? [];
    List<MedicineRecordModel> userMedicineRecords = prefetchedMedicineRecords ?? [];
    List<InventoryItemModel> userInventoryItems = prefetchedInventoryItems ?? [];

    if (farmId.isNotEmpty && batch.id.isNotEmpty && prefetchedDailyRecords == null) {
      try {
        recentRecords = await DailyRecordService.getAllDailyRecords(
          farmId: farmId,
          batchId: batch.id,
        );
      } catch (e) {
        debugPrint('[FlockPlanService] Error fetching daily records: $e');
      }

      if (isToday) {
        try {
          todayRecord = await DailyRecordService.getDailyRecordByDate(
            farmId: farmId,
            batchId: batch.id,
            recordDate: DateTime.now(),
          );
        } catch (_) {}
      }

      if (prefetchedVaccineRecords == null) {
        try {
          userVaccineRecords = await VaccineService.getVaccineRecords(
            farmId: farmId,
            batchId: batch.id,
          );
        } catch (_) {}
      }

      if (prefetchedMedicineRecords == null) {
        try {
          userMedicineRecords = await MedicineService.getMedicineRecords(
            farmId: farmId,
            batchId: batch.id,
          );
        } catch (_) {}
      }

      if (prefetchedInventoryItems == null) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final invService = InventoryService();
            try {
              userInventoryItems = await invService
                  .watchInventoryItems(uid: user.uid, farmId: farmId)
                  .first
                  .timeout(const Duration(seconds: 2));
            } catch (_) {}
            if (userInventoryItems.isEmpty) {
              try {
                userInventoryItems = await invService
                    .watchInventoryItems(uid: user.uid)
                    .first
                    .timeout(const Duration(seconds: 2));
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } else if (isToday && recentRecords.isNotEmpty) {
      final now = DateTime.now();
      for (final r in recentRecords) {
        if (r.recordDate.year == now.year &&
            r.recordDate.month == now.month &&
            r.recordDate.day == now.day) {
          todayRecord = r;
          break;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. Real-time Live Bird Count & Flock Aggregations
    // ─────────────────────────────────────────────────────────────
    final sortedRecords = [...recentRecords]
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    // Live bird count: take the latest recorded closingBirds if available
    int liveBirds = batch.currentBirds > 0 ? batch.currentBirds : batch.totalBirds;
    if (sortedRecords.isNotEmpty && sortedRecords.first.closingBirds > 0) {
      liveBirds = sortedRecords.first.closingBirds;
    }
    if (liveBirds <= 0) liveBirds = batch.totalBirds > 0 ? batch.totalBirds : 1;

    // Cumulative stats
    final cumulativeMortality = recentRecords.fold<int>(
      0,
      (sum, r) => sum + r.mortalityCount,
    );
    final cumulativeMortalityPct = batch.totalBirds > 0
        ? ((cumulativeMortality / batch.totalBirds) * 100.0).clamp(0.0, 100.0)
        : 0.0;
    final cumulativeFeedKg = recentRecords.fold<double>(
      0.0,
      (sum, r) => sum + r.feedConsumedKg,
    );

    // Latest sampled weight from real records
    DailyRecordModel? latestWeightRecord;
    for (final r in sortedRecords) {
      if (r.avgWeightGrams > 0) {
        latestWeightRecord = r;
        break;
      }
    }
    final actualSampledWeight = latestWeightRecord?.avgWeightGrams;

    // Real FCR calculation with safety checks
    double? actualFcr;
    if (cumulativeFeedKg > 0 &&
        actualSampledWeight != null &&
        actualSampledWeight > 0 &&
        liveBirds > 0) {
      final biomassKg = (liveBirds * actualSampledWeight) / 1000.0;
      if (biomassKg > 0) {
        final calculatedFcr = cumulativeFeedKg / biomassKg;
        if (calculatedFcr.isFinite && !calculatedFcr.isNaN && calculatedFcr > 0) {
          actualFcr = calculatedFcr;
        }
      }
    }

    // Standard targets scaled to real live birds
    final totalFeedKg = FlockLifecycleStandard.calculateDailyFeedKg(day, liveBirds);
    final totalWaterLiters = FlockLifecycleStandard.calculateDailyWaterLiters(day, liveBirds);

    final tasks = <DailyPlanTask>[];
    final diagnosticAlerts = <String>[];

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    bool isTaskCompleted(String taskId) {
      if (prefs == null) return false;
      return prefs.getBool('$_prefTaskPrefix${batch.id}_d${day}_$taskId') ?? false;
    }

    // ─────────────────────────────────────────────────────────────
    // 3. Telemetry Task (Log Day X)
    // ─────────────────────────────────────────────────────────────
    final hasLoggedToday = todayRecord != null;
    final logTaskId = 'log_telemetry_$day';

    if (isToday) {
      tasks.add(
        DailyPlanTask(
          id: logTaskId,
          title: hasLoggedToday
              ? 'Day $day Daily Telemetry Logged'
              : 'Log Day $day Daily Telemetry',
          description: hasLoggedToday
              ? 'Closing: ${todayRecord.closingBirds} birds • Feed: ${todayRecord.feedConsumedKg} kg • Water: ${todayRecord.waterConsumedLiters} L • Mortality: ${todayRecord.mortalityCount}'
              : "Record today's feed consumed, water intake, bird mortality, and weight sampling.",
          category: TaskCategory.diagnostic,
          priority: TaskPriority.critical,
          isCompleted: hasLoggedToday || isTaskCompleted(logTaskId),
          isRealRecordVerified: hasLoggedToday,
          verificationNote: hasLoggedToday ? 'Recorded in FlockSense' : null,
          actionLabel: hasLoggedToday ? 'View/Edit Record' : 'Log Day $day Telemetry',
          actionRoute: '/daily-record',
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 4. Feed & Nutrition Task (Validated with real log)
    // ─────────────────────────────────────────────────────────────
    final feedTaskId = 'feed_$day';
    final actualFeedGiven = isToday ? todayRecord?.feedConsumedKg : null;
    final hasFeedLogged = actualFeedGiven != null && actualFeedGiven > 0;

    final feedComparisonPct = (hasFeedLogged && totalFeedKg > 0)
        ? ((actualFeedGiven / totalFeedKg) * 100.0).toStringAsFixed(0)
        : '100';

    tasks.add(
      DailyPlanTask(
        id: feedTaskId,
        title: hasFeedLogged
            ? 'Feed Provided: ${actualFeedGiven.toStringAsFixed(1)} kg (${std.feedType})'
            : 'Provide ${totalFeedKg.toStringAsFixed(1)} kg ${std.feedType}',
        description: hasFeedLogged
            ? 'Logged ${actualFeedGiven.toStringAsFixed(1)} kg vs target ${totalFeedKg.toStringAsFixed(1)} kg ($feedComparisonPct% of Cobb/Ross standard).'
            : 'Standard: ${std.dailyFeedPerBirdGrams.toStringAsFixed(0)}g/bird × $liveBirds live birds. Distribute in clean pans to stimulate feeding.',
        category: TaskCategory.feeding,
        priority: TaskPriority.high,
        isCompleted: hasFeedLogged || isTaskCompleted(feedTaskId),
        isRealRecordVerified: hasFeedLogged,
        verificationNote: hasFeedLogged ? '${actualFeedGiven.toStringAsFixed(1)} kg logged' : null,
        actionLabel: 'Analyze Feed',
        actionRoute: '/reports',
      ),
    );

    // ─────────────────────────────────────────────────────────────
    // 5. Water & Hydration Task (Validated with real log)
    // ─────────────────────────────────────────────────────────────
    final waterTaskId = 'water_$day';
    final actualWaterGiven = isToday ? todayRecord?.waterConsumedLiters : null;
    final hasWaterLogged = actualWaterGiven != null && actualWaterGiven > 0;

    tasks.add(
      DailyPlanTask(
        id: waterTaskId,
        title: hasWaterLogged
            ? 'Water Supplied: ${actualWaterGiven.toStringAsFixed(0)} L Clean Sanitized'
            : 'Provide ${totalWaterLiters.toStringAsFixed(0)} L Clean Sanitized Water',
        description: hasWaterLogged
            ? 'Logged ${actualWaterGiven.toStringAsFixed(0)} L vs target ${totalWaterLiters.toStringAsFixed(0)} L. Check nipple line pressure & hygiene.'
            : 'Standard: ${std.dailyWaterPerBirdMl.toStringAsFixed(0)} ml/bird × $liveBirds birds. Maintain 2-3 ppm free chlorine in drinking water.',
        category: TaskCategory.water,
        priority: TaskPriority.routine,
        isCompleted: hasWaterLogged || isTaskCompleted(waterTaskId),
        isRealRecordVerified: hasWaterLogged,
        verificationNote: hasWaterLogged ? '${actualWaterGiven.toStringAsFixed(0)} L logged' : null,
      ),
    );

    // ─────────────────────────────────────────────────────────────
    // 6. Vaccination Protocol (Cross-checked against real logs)
    // ─────────────────────────────────────────────────────────────
    if (std.vaccineName != null) {
      final vacTaskId = 'vac_$day';
      final vaccineLower = std.vaccineName!.toLowerCase();

      // Check if user has an actual record in VaccineService or DailyRecord
      final recordedInVaccineService = userVaccineRecords.any((v) {
        final vName = v.vaccineName.toLowerCase();
        return vName.contains(vaccineLower) || vaccineLower.contains(vName);
      });
      final recordedInDailyRecords = recentRecords.any((r) {
        if (!r.vaccineGiven || r.vaccineName == null) return false;
        final rName = r.vaccineName!.toLowerCase();
        return rName.contains(vaccineLower) || vaccineLower.contains(rName);
      });
      final isVaccineAdministered =
          recordedInVaccineService || recordedInDailyRecords || isTaskCompleted(vacTaskId);

      final currentAge = getFlockAge(batch);
      final isOverdue = !isVaccineAdministered && currentAge > day;
      final isDueToday = !isVaccineAdministered && currentAge == day;

      tasks.add(
        DailyPlanTask(
          id: vacTaskId,
          title: isVaccineAdministered
              ? 'Vaccine Administered: ${std.vaccineName!}'
              : (isOverdue
                  ? 'Overdue Vaccine: ${std.vaccineName!} (Day $day)'
                  : (isDueToday
                      ? 'Vaccine Due Today: ${std.vaccineName!}'
                      : 'Vaccine: ${std.vaccineName!}')),
          description: isVaccineAdministered
              ? 'Administration verified from batch records.'
              : (isOverdue
                  ? 'Missed scheduled administration on Day $day. Consult flock veterinarian and administer immediately.'
                  : 'Route: ${std.vaccineRoute ?? "Drinking water"}. Administer during cool morning hours with skim milk stabilizer.'),
          category: TaskCategory.vaccine,
          priority: TaskPriority.critical,
          isCompleted: isVaccineAdministered,
          isRealRecordVerified: recordedInVaccineService || recordedInDailyRecords,
          verificationNote: (recordedInVaccineService || recordedInDailyRecords)
              ? 'Verified from batch health logs'
              : null,
          actionLabel: 'Record Vaccine',
          actionRoute: '/vaccine',
        ),
      );

      if (isOverdue && isToday) {
        diagnosticAlerts.add(
          'Overdue Vaccine Alert: "${std.vaccineName}" was scheduled for Day $day but has no record in batch logs. Administer promptly.',
        );
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 7. Medicine & Health Protocol (Cross-checked against real logs)
    // ─────────────────────────────────────────────────────────────
    if (std.medicineProtocol != null) {
      final medTaskId = 'med_$day';
      final recordedInMedicineService = userMedicineRecords.any((m) => m.batchAgeDay == day);
      final recordedInDailyRecords = recentRecords.any((r) => r.medicineGiven && r.batchAgeDay == day);
      final isMedAdministered =
          recordedInMedicineService || recordedInDailyRecords || isTaskCompleted(medTaskId);

      tasks.add(
        DailyPlanTask(
          id: medTaskId,
          title: isMedAdministered
              ? 'Medicine Administered: Health Protocol'
              : 'Medicine & Health Protocol',
          description: isMedAdministered
              ? 'Administered and logged in flock medical records.'
              : std.medicineProtocol!,
          category: TaskCategory.medicine,
          priority: TaskPriority.high,
          isCompleted: isMedAdministered,
          isRealRecordVerified: recordedInMedicineService || recordedInDailyRecords,
          verificationNote: (recordedInMedicineService || recordedInDailyRecords)
              ? 'Logged in medical registry'
              : null,
          actionLabel: 'Record Medicine',
          actionRoute: '/medicine',
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 8. Climate & Environment Task
    // ─────────────────────────────────────────────────────────────
    final envTaskId = 'env_$day';
    final recordedTemp = isToday ? todayRecord?.temperature : null;
    final hasRecordedTemp = recordedTemp != null;

    tasks.add(
      DailyPlanTask(
        id: envTaskId,
        title: hasRecordedTemp
            ? 'Shed Temp: ${recordedTemp.toStringAsFixed(1)}°C (Target: ${std.targetTempCelsius}°C)'
            : 'Set Shed Temp to ${std.targetTempCelsius}°C • ${std.lightingHours}h Light',
        description:
            'Observe bird distribution: no huddling (too cold) or panting with outstretched wings (too hot).',
        category: TaskCategory.environment,
        priority: TaskPriority.routine,
        isCompleted: hasRecordedTemp || isTaskCompleted(envTaskId),
        isRealRecordVerified: hasRecordedTemp,
      ),
    );

    // ─────────────────────────────────────────────────────────────
    // 9. Operational Management & Biosecurity Checklist
    // ─────────────────────────────────────────────────────────────
    for (int i = 0; i < std.managementTasks.length; i++) {
      final taskText = std.managementTasks[i];
      final mgmtTaskId = 'mgmt_${day}_$i';
      tasks.add(
        DailyPlanTask(
          id: mgmtTaskId,
          title: taskText,
          description: 'Standard Cobb/Ross commercial broiler operational protocol for Day $day.',
          category: TaskCategory.environment,
          priority: TaskPriority.routine,
          isCompleted: isTaskCompleted(mgmtTaskId),
        ),
      );
    }

    for (int i = 0; i < std.biosecurityChecklist.length; i++) {
      final bioText = std.biosecurityChecklist[i];
      final bioTaskId = 'bio_${day}_$i';
      tasks.add(
        DailyPlanTask(
          id: bioTaskId,
          title: bioText,
          description: 'Flock biosecurity and hygiene protocol to prevent disease entry.',
          category: TaskCategory.biosecurity,
          priority: TaskPriority.routine,
          isCompleted: isTaskCompleted(bioTaskId),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 10. Real-time Telemetry Diagnostics & Anomaly Detection
    // ─────────────────────────────────────────────────────────────
    if (isToday && sortedRecords.isNotEmpty) {
      final latest = sortedRecords.first;

      // 10.1 High Daily Mortality Alert (> 0.1% of live flock)
      final mortPct = liveBirds > 0 ? (latest.mortalityCount / liveBirds) * 100.0 : 0.0;
      if (mortPct > 0.10) {
        final alertText =
            'Elevated mortality detected (${latest.mortalityCount} birds, ${mortPct.toStringAsFixed(2)}%). Inspect drinker flow, respiratory sounds, and post-mortem symptoms.';
        diagnosticAlerts.add(alertText);
        final diagTaskId = 'diag_mort_$day';
        tasks.insert(
          0,
          DailyPlanTask(
            id: diagTaskId,
            title: 'Critical Mortality Check',
            description: alertText,
            category: TaskCategory.diagnostic,
            priority: TaskPriority.critical,
            isCompleted: isTaskCompleted(diagTaskId),
            actionLabel: 'View Performance',
            actionRoute: '/performance',
          ),
        );
      }

      // 10.2 Cumulative Mortality Check (> 4.0% cumulative)
      if (cumulativeMortalityPct > 4.0) {
        diagnosticAlerts.add(
          'Cumulative batch mortality has reached ${cumulativeMortalityPct.toStringAsFixed(2)}% ($cumulativeMortality birds total). Review biosecurity and water sanitation.',
        );
      }

      // 10.3 Feed Intake Drop Check (> 10% drop vs yesterday)
      if (sortedRecords.length >= 2) {
        final prev = sortedRecords[1];
        if (prev.feedConsumedKg > 0 && latest.feedConsumedKg > 0) {
          final dropPct =
              ((prev.feedConsumedKg - latest.feedConsumedKg) / prev.feedConsumedKg) * 100.0;
          if (dropPct > 10.0) {
            final alertText =
                'Feed intake dropped by ${dropPct.toStringAsFixed(1)}% compared to yesterday (${latest.feedConsumedKg.toStringAsFixed(1)} kg vs ${prev.feedConsumedKg.toStringAsFixed(1)} kg). Inspect water availability and feed freshness.';
            diagnosticAlerts.add(alertText);
            final feedDropTaskId = 'diag_feed_drop_$day';
            tasks.insert(
              1,
              DailyPlanTask(
                id: feedDropTaskId,
                title: 'Feed Intake Drop Alert',
                description: alertText,
                category: TaskCategory.diagnostic,
                priority: TaskPriority.critical,
                isCompleted: isTaskCompleted(feedDropTaskId),
              ),
            );
          }
        }
      }

      // 10.4 Water / Feed Ratio Mismatch (Standard is 1.6 to 2.2)
      if (latest.feedConsumedKg > 0 && latest.waterConsumedLiters > 0) {
        final ratio = latest.waterConsumedLiters / latest.feedConsumedKg;
        if (ratio > 2.5) {
          diagnosticAlerts.add(
            'High water intake ratio (${ratio.toStringAsFixed(1)}:1). Check for drinker pipe leaks, heat stress, or high sodium in drinking water.',
          );
        } else if (ratio < 1.4) {
          diagnosticAlerts.add(
            'Low water intake ratio (${ratio.toStringAsFixed(1)}:1). Check drinker line pressure and verify nipples are unclogged.',
          );
        }
      }

      // 10.5 Sampled Weight Variance Check
      if (actualSampledWeight != null && actualSampledWeight > 0 && std.targetWeightGrams > 0) {
        final wtDiff = actualSampledWeight - std.targetWeightGrams;
        final wtDiffPct = (wtDiff / std.targetWeightGrams) * 100.0;
        if (wtDiffPct < -10.0) {
          diagnosticAlerts.add(
            'Flock is underweight: Sampled weight is ${actualSampledWeight.toStringAsFixed(0)}g vs target ${std.targetWeightGrams.toStringAsFixed(0)}g (${wtDiff.toStringAsFixed(0)}g / ${wtDiffPct.toStringAsFixed(1)}%). Consider increasing feeder pan space.',
          );
        }
      }

      // 10.6 Pre-Harvest Chemical Withdrawal Window (Days 36 - 45)
      if (day >= 36) {
        final recentMeds = userMedicineRecords.where((m) {
          final diff = DateTime.now().difference(m.date).inDays;
          return diff >= 0 && diff <= 7;
        }).toList();
        if (recentMeds.isNotEmpty) {
          diagnosticAlerts.add(
            'Antibiotic Withdrawal Notice: "${recentMeds.first.medicineName}" was administered in the last 7 days. Ensure 0 chemical residue before harvest.',
          );
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 11. Real-time Inventory Stock Validation (Feed & Vaccines)
    // ─────────────────────────────────────────────────────────────
    double? feedStockDaysRemaining;
    double? feedStockBagsAvailable;

    if (isToday && userInventoryItems.isNotEmpty) {
      final feedItems = userInventoryItems.where((i) {
        final cat = i.category.toLowerCase();
        final name = i.itemName.toLowerCase();
        return cat.contains('feed') ||
            name.contains('feed') ||
            name.contains('starter') ||
            name.contains('grower') ||
            name.contains('finisher') ||
            name.contains('pellet') ||
            name.contains('crumble');
      }).toList();

      double availableFeedKg = 0;
      for (final item in feedItems) {
        final u = item.unit.toLowerCase();
        if (u.contains('bag')) {
          availableFeedKg += item.quantityAvailable * 50.0;
        } else if (u.contains('ton')) {
          availableFeedKg += item.quantityAvailable * 1000.0;
        } else if (u.contains('quintal')) {
          availableFeedKg += item.quantityAvailable * 100.0;
        } else {
          availableFeedKg += item.quantityAvailable; // kg
        }
      }

      if (totalFeedKg > 0 && availableFeedKg >= 0) {
        final remaining = availableFeedKg / totalFeedKg;
        if (remaining.isFinite && !remaining.isNaN) {
          feedStockDaysRemaining = remaining;
          feedStockBagsAvailable = availableFeedKg / 50.0;
        }

        if (availableFeedKg <= 0) {
          final stockTaskId = 'diag_stock_$day';
          final alertMsg =
              'Zero feed in inventory! No available feed stock recorded in Farm Inventory. Update inventory or purchase feed immediately.';
          diagnosticAlerts.add(alertMsg);
          tasks.insert(
            tasks.length > 2 ? 2 : tasks.length,
            DailyPlanTask(
              id: stockTaskId,
              title: 'Critical: Restock ${std.feedType}',
              description: alertMsg,
              category: TaskCategory.feeding,
              priority: TaskPriority.critical,
              isCompleted: isTaskCompleted(stockTaskId),
              actionLabel: 'Restock Feed',
              actionRoute: '/inventory',
            ),
          );
        } else if (feedStockDaysRemaining != null && feedStockDaysRemaining <= 3.5) {
          final stockTaskId = 'diag_stock_$day';
          final alertMsg =
              'Feed stock low: ~${feedStockDaysRemaining.toStringAsFixed(1)} days of ${std.feedType} remaining (${feedStockBagsAvailable?.toStringAsFixed(0) ?? "0"} bags / ${availableFeedKg.toStringAsFixed(0)} kg). Reorder feed today.';
          diagnosticAlerts.add(alertMsg);
          tasks.insert(
            tasks.length > 2 ? 2 : tasks.length,
            DailyPlanTask(
              id: stockTaskId,
              title: 'Reorder ${std.feedType}',
              description: alertMsg,
              category: TaskCategory.feeding,
              priority: TaskPriority.high,
              isCompleted: isTaskCompleted(stockTaskId),
              actionLabel: 'Restock Feed',
              actionRoute: '/inventory',
            ),
          );
        }
      }

      // Check upcoming vaccine inventory
      if (std.vaccineName != null) {
        final vName = std.vaccineName!.toLowerCase();
        final hasVaccineInStock = userInventoryItems.any((i) {
          final cat = i.category.toLowerCase();
          final name = i.itemName.toLowerCase();
          return (cat.contains('vaccine') || name.contains('vaccine') || name.contains(vName)) &&
              i.quantityAvailable > 0 &&
              !i.isExpired;
        });
        if (!hasVaccineInStock) {
          diagnosticAlerts.add(
            'Vaccine Stock Notice: "${std.vaccineName}" is due on Day $day but no active stock was found in Farm Inventory. Order vaccine supplies in advance.',
          );
        }
      }
    }

    return DailyFlockPlan(
      day: day,
      phase: std.phase,
      liveBirds: liveBirds,
      targetWeightGrams: std.targetWeightGrams,
      dailyFeedPerBirdGrams: std.dailyFeedPerBirdGrams,
      totalFeedKg: totalFeedKg,
      dailyWaterPerBirdMl: std.dailyWaterPerBirdMl,
      totalWaterLiters: totalWaterLiters,
      feedType: std.feedType,
      targetTempCelsius: std.targetTempCelsius,
      lightingHours: std.lightingHours,
      vaccineDue: std.vaccineName,
      vaccineRoute: std.vaccineRoute,
      medicineDue: std.medicineProtocol,
      tasks: tasks,
      diagnosticAlerts: diagnosticAlerts,
      isRealDataValidated: recentRecords.isNotEmpty || userInventoryItems.isNotEmpty,
      hasLoggedTodayRecord: hasLoggedToday,
      actualFeedGivenKg: todayRecord?.feedConsumedKg,
      actualWaterGivenLiters: todayRecord?.waterConsumedLiters,
      actualAvgWeightGrams: (todayRecord != null && todayRecord.avgWeightGrams > 0)
          ? todayRecord.avgWeightGrams
          : actualSampledWeight,
      actualMortalityToday: todayRecord?.mortalityCount,
      cumulativeMortality: cumulativeMortality,
      cumulativeMortalityPct: cumulativeMortalityPct,
      actualFcr: actualFcr,
      feedStockDaysRemaining: feedStockDaysRemaining,
      feedStockBagsAvailable: feedStockBagsAvailable,
    );
  }

  /// Toggle task completion state and persist it locally in SharedPreferences.
  static Future<void> toggleTaskCompletion({
    required String batchId,
    required int day,
    required String taskId,
    required bool completed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefTaskPrefix${batchId}_d${day}_$taskId', completed);
    } catch (e) {
      debugPrint('[FlockPlanService] Error saving task completion: $e');
    }
  }

  /// Generates the 7-day schedule for the requested growth week (Weeks 1 to 6).
  static Future<WeekFlockPlan> getWeekPlan({
    required String farmId,
    required BatchModel batch,
    int? weekNumber,
  }) async {
    final currentAge = getFlockAge(batch);
    final currentWeek = ((currentAge - 1) ~/ 7) + 1;
    final targetWeek = (weekNumber ?? currentWeek).clamp(1, 6);

    final startDay = (targetWeek - 1) * 7 + 1;
    final endDay = (targetWeek * 7).clamp(1, 45);

    // Prefetch records once to avoid 7 redundant Firestore network queries
    List<DailyRecordModel> records = [];
    List<VaccineRecordModel> vaccines = [];
    List<MedicineRecordModel> medicines = [];
    List<InventoryItemModel> inventory = [];

    if (farmId.isNotEmpty && batch.id.isNotEmpty) {
      try {
        records = await DailyRecordService.getAllDailyRecords(
          farmId: farmId,
          batchId: batch.id,
        );
      } catch (_) {}
      try {
        vaccines = await VaccineService.getVaccineRecords(
          farmId: farmId,
          batchId: batch.id,
        );
      } catch (_) {}
      try {
        medicines = await MedicineService.getMedicineRecords(
          farmId: farmId,
          batchId: batch.id,
        );
      } catch (_) {}
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          inventory = await InventoryService()
              .watchInventoryItems(uid: user.uid, farmId: farmId)
              .first
              .timeout(const Duration(seconds: 2));
        }
      } catch (_) {}
    }

    final dailyPlans = <DailyFlockPlan>[];
    double totalWeeklyFeedKg = 0;

    for (int d = startDay; d <= endDay; d++) {
      try {
        final plan = await getPlanForSpecificDay(
          farmId: farmId,
          batch: batch,
          day: d,
          prefetchedDailyRecords: records,
          prefetchedVaccineRecords: vaccines,
          prefetchedMedicineRecords: medicines,
          prefetchedInventoryItems: inventory,
        );
        dailyPlans.add(plan);
        totalWeeklyFeedKg += plan.totalFeedKg;
      } catch (e) {
        debugPrint('[FlockPlanService] Error loading day $d plan: $e');
        final fallback = getStandardPlanForDay(batch: batch, day: d);
        dailyPlans.add(fallback);
        totalWeeklyFeedKg += fallback.totalFeedKg;
      }
    }

    String weekTitle;
    String milestone;
    switch (targetWeek) {
      case 1:
        weekTitle = 'Week 1: Brooding & Vital Foundation';
        milestone = 'Day 7 Weight Target: ~185g (4-5x hatch weight) • ND LaSota Vaccine';
        break;
      case 2:
        weekTitle = 'Week 2: Expansion & Immunity';
        milestone = 'Day 14 Weight Target: ~500g • Gumboro (IBD) Vaccine • Starter Transition';
        break;
      case 3:
        weekTitle = 'Week 3: Frame Development & Skeletal Growth';
        milestone = 'Day 21 Weight Target: ~915g • ND Booster Vaccine • FCR Target: 1.30';
        break;
      case 4:
        weekTitle = 'Week 4: Muscle Deposition & Grower Phase';
        milestone = 'Day 28 Weight Target: ~1,475g • Transition to Grower Pellets';
        break;
      case 5:
        weekTitle = 'Week 5: Finisher & Rapid Biomass Accumulation';
        milestone = 'Day 35 Weight Target: ~2,115g • Finisher Transition • FCR Target: 1.55';
        break;
      case 6:
      default:
        weekTitle = 'Week 6: Pre-Harvest, Withdrawal & Marketing';
        milestone = 'Day 42 Weight Target: ~2,750g • Strict Withdrawal • Batch Catching';
        break;
    }

    return WeekFlockPlan(
      weekNumber: targetWeek,
      title: weekTitle,
      primaryMilestone: milestone,
      totalWeeklyFeedKg: totalWeeklyFeedKg,
      dailyPlans: dailyPlans,
    );
  }

  /// Returns the master lifecycle chart dataset dynamically sized to the batch cycle.
  static List<DailyFlockPlan> getFullCycleChartSync(BatchModel batch, [List<DailyRecordModel>? records]) {
    final liveBirds = batch.currentBirds > 0 ? batch.currentBirds : batch.totalBirds;
    final totalMortality = (batch.totalBirds - liveBirds).clamp(0, batch.totalBirds);
    final mortPct = batch.totalBirds > 0 ? (totalMortality / batch.totalBirds) * 100.0 : 0.0;
    final list = <DailyFlockPlan>[];

    final recordMap = <int, DailyRecordModel>{};
    if (records != null) {
      for (final r in records) {
        recordMap[r.batchAgeDay] = r;
      }
    }

    final totalDays = batch.cycleTargetDays;
    for (int day = 1; day <= totalDays; day++) {
      final std = FlockLifecycleStandard.getForDay(day);
      final totalFeedKg = FlockLifecycleStandard.calculateDailyFeedKg(day, liveBirds);
      final totalWaterLiters = FlockLifecycleStandard.calculateDailyWaterLiters(day, liveBirds);
      final dayRec = recordMap[day];

      list.add(
        DailyFlockPlan(
          day: day,
          phase: std.phase,
          liveBirds: dayRec != null && dayRec.closingBirds > 0 ? dayRec.closingBirds : liveBirds,
          targetWeightGrams: std.targetWeightGrams,
          dailyFeedPerBirdGrams: std.dailyFeedPerBirdGrams,
          totalFeedKg: totalFeedKg,
          dailyWaterPerBirdMl: std.dailyWaterPerBirdMl,
          totalWaterLiters: totalWaterLiters,
          feedType: std.feedType,
          targetTempCelsius: std.targetTempCelsius,
          lightingHours: std.lightingHours,
          vaccineDue: std.vaccineName,
          vaccineRoute: std.vaccineRoute,
          medicineDue: std.medicineProtocol,
          tasks: [],
          actualFeedGivenKg: dayRec?.feedConsumedKg,
          actualWaterGivenLiters: dayRec?.waterConsumedLiters,
          actualAvgWeightGrams: dayRec != null && dayRec.avgWeightGrams > 0 ? dayRec.avgWeightGrams : null,
          actualMortalityToday: dayRec?.mortalityCount,
          cumulativeMortality: totalMortality,
          cumulativeMortalityPct: mortPct,
        ),
      );
    }

    return list;
  }
}
