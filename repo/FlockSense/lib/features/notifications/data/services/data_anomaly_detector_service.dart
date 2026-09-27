import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/flock_plan/domain/flock_lifecycle_standard.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/fcm_local_notification_service.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class DataAnomalyDetectorService {
  DataAnomalyDetectorService._();

  static final Set<String> _sentAnomalyKeys = {};

  /// Evaluates telemetry and entries inside a DailyRecordModel.
  /// If any abnormal behavior is detected, generates notifications and dispatches
  /// immediate push/local alerts to the user's device.
  static Future<List<NotificationModel>> detectAndDispatchAnomalies({
    required DailyRecordModel record,
    required String farmId,
    required String batchId,
    BatchModel? batch,
    DailyRecordModel? previousRecord,
  }) async {
    final anomalies = <NotificationModel>[];

    try {
      // 1. Resolve batch metadata if not provided
      BatchModel? effectiveBatch = batch;
      if (effectiveBatch == null) {
        try {
          effectiveBatch = await BatchService.getBatchById(farmId, batchId);
        } catch (_) {}
      }

      final batchName = effectiveBatch?.batchName ?? 'Flock';
      final now = DateTime.now();

      // 2. Resolve flock age
      final ageDays = record.batchAgeDay > 0
          ? record.batchAgeDay
          : (effectiveBatch != null
              ? now.difference(effectiveBatch.placementDate).inDays + 1
              : 1);

      // 3. Resolve previous record if not provided
      DailyRecordModel? prior = previousRecord;
      if (prior == null) {
        try {
          prior = await DailyRecordService.getLatestRecordBeforeDate(
            farmId: farmId,
            batchId: batchId,
            beforeDate: record.recordDate,
          );
        } catch (_) {}
      }

      // 4. Retrieve breed standard parameters for this day
      final std = FlockLifecycleStandard.getForDay(ageDays);
      final flockSize = record.openingBirds > 0
          ? record.openingBirds
          : (effectiveBatch?.currentBirds ?? 1000);
      final expectedFeedKg =
          (std.dailyFeedPerBirdGrams * (flockSize > 0 ? flockSize : 1000)) /
              1000.0;

      // -------------------------------------------------------------
      // ANOMALY 1: Mortality Spike / High Daily Mortality Rate
      // -------------------------------------------------------------
      if (record.mortalityCount > 0 && record.openingBirds > 0) {
        final mortPct = (record.mortalityCount / record.openingBirds) * 100.0;

        if (mortPct >= 1.0 || record.mortalityCount >= 15) {
          final isSevere = mortPct >= 2.0 || record.mortalityCount >= 25;
          anomalies.add(
            NotificationModel(
              id: 'anomaly_mort_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: isSevere
                  ? '🚨 CRITICAL MORTALITY SPIKE — $batchName'
                  : '⚠️ High Mortality Alert — $batchName',
              body:
                  '${record.mortalityCount} birds died today (${mortPct.toStringAsFixed(1)}% of flock) on Day $ageDays. Check ventilation, water pressure, and bird health immediately.',
              type: NotificationType.batch,
              priority: NotificationPriority.critical,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'mortality_spike',
                'mortalityCount': record.mortalityCount,
                'mortalityRatePct': mortPct,
                'recommendations': [
                  'Inspect drinker nipples for contamination or water shut-off',
                  'Verify static pressure and tunnel fan operation',
                  'Perform post-mortem necropsy or submit dead birds to lab',
                  'Quarantine weak or moribund birds to hospital pen',
                ],
              },
            ),
          );
        } else if (prior != null && prior.mortalityCount >= 0) {
          final jump = record.mortalityCount - prior.mortalityCount;
          if (jump >= 8 && record.mortalityCount >= 10) {
            anomalies.add(
              NotificationModel(
                id: 'anomaly_mort_jump_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
                title: '⚠️ Sudden Mortality Surge — $batchName',
                body:
                    'Mortality surged from ${prior.mortalityCount} to ${record.mortalityCount} birds (+${jump} dead) in 24 hours. Investigate shed conditions immediately.',
                type: NotificationType.batch,
                priority: NotificationPriority.critical,
                createdAt: now,
                isSmartAlert: true,
                relatedFarmId: farmId,
                relatedBatchId: batchId,
                actionUrl: '/daily-record',
                metadata: {
                  'anomalyType': 'mortality_jump',
                  'recommendations': [
                    'Check for nocturnal smothering or predator fright',
                    'Verify air speed at bird height',
                    'Examine litter for blood or enteritis stains',
                  ],
                },
              ),
            );
          }
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 2: High Culling Rate
      // -------------------------------------------------------------
      if (record.cullCount > 0 && record.openingBirds > 0) {
        final cullPct = (record.cullCount / record.openingBirds) * 100.0;
        if (cullPct >= 1.0 || record.cullCount >= 12) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_cull_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '⚠️ High Cull Rate Detected — $batchName',
              body:
                  '${record.cullCount} birds culled (${cullPct.toStringAsFixed(1)}%) on Day $ageDays. Check flock uniformity, leg issues, and ascites.',
              type: NotificationType.batch,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'high_culling',
                'cullCount': record.cullCount,
                'recommendations': [
                  'Adjust feed distribution timing to improve uniformity',
                  'Check for subclinical rickets or lameness',
                  'Review ventilation to prevent fluid retention (ascites)',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 3: Acute Feed Intake Drop (Critical Disease Sign)
      // -------------------------------------------------------------
      if (record.feedConsumedKg > 0) {
        if (prior != null && prior.feedConsumedKg > 15.0) {
          final feedDropPct =
              ((prior.feedConsumedKg - record.feedConsumedKg) /
                      prior.feedConsumedKg) *
                  100.0;
          if (feedDropPct >= 20.0) {
            anomalies.add(
              NotificationModel(
                id: 'anomaly_feed_drop_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
                title: '⚠️ Severe Feed Intake Drop (-${feedDropPct.toStringAsFixed(0)}%) — $batchName',
                body:
                    'Feed consumption plunged from ${prior.feedConsumedKg.toStringAsFixed(1)}kg to ${record.feedConsumedKg.toStringAsFixed(1)}kg. Sudden appetite loss is a primary warning of flock disease or heat stress.',
                type: NotificationType.feed,
                priority: NotificationPriority.critical,
                createdAt: now,
                isSmartAlert: true,
                relatedFarmId: farmId,
                relatedBatchId: batchId,
                actionUrl: '/daily-record',
                metadata: {
                  'anomalyType': 'feed_intake_drop',
                  'priorFeedKg': prior.feedConsumedKg,
                  'currentFeedKg': record.feedConsumedKg,
                  'dropPct': feedDropPct,
                  'recommendations': [
                    'Check crop fill to see if birds are eating or starving',
                    'Inspect feed quality for mold, clumps, or rancidity',
                    'Verify water supply (birds cannot eat without drinking)',
                  ],
                },
              ),
            );
          }
        } else if (expectedFeedKg > 10.0 &&
            record.feedConsumedKg < expectedFeedKg * 0.70) {
          final deficitPct =
              ((expectedFeedKg - record.feedConsumedKg) / expectedFeedKg) *
                  100.0;
          anomalies.add(
            NotificationModel(
              id: 'anomaly_feed_deficit_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '⚠️ Feed Consumption Lag (-${deficitPct.toStringAsFixed(0)}%) — $batchName',
              body:
                  'Flock ate ${record.feedConsumedKg.toStringAsFixed(1)}kg today vs breed standard target of ${expectedFeedKg.toStringAsFixed(1)}kg.',
              type: NotificationType.feed,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'feed_intake_lag',
                'recommendations': [
                  'Inspect feeder line augers and pan distribution',
                  'Check shed temperature (high heat depresses appetite)',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 4: Feed Overconsumption / Wastage
      // -------------------------------------------------------------
      if (expectedFeedKg > 15.0 &&
          record.feedConsumedKg > expectedFeedKg * 1.35) {
        final overPct =
            ((record.feedConsumedKg - expectedFeedKg) / expectedFeedKg) *
                100.0;
        anomalies.add(
          NotificationModel(
            id: 'anomaly_feed_over_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
            title: '⚠️ Feed Overconsumption Alert (+${overPct.toStringAsFixed(0)}%) — $batchName',
            body:
                'Feed logged (${record.feedConsumedKg.toStringAsFixed(1)}kg) is ${overPct.toStringAsFixed(0)}% above standard. Inspect feeder pans for spillage into litter.',
            type: NotificationType.feed,
            priority: NotificationPriority.normal,
            createdAt: now,
            isSmartAlert: true,
            relatedFarmId: farmId,
            relatedBatchId: batchId,
            actionUrl: '/daily-record',
            metadata: {
              'anomalyType': 'feed_overconsumption',
              'recommendations': [
                'Raise feeder pans so pan lip is level with birds\' backs',
                'Check litter under feeders for spilled pellets',
                'Verify feed weigh scale accuracy',
              ],
            },
          ),
        );
      }

      // -------------------------------------------------------------
      // ANOMALY 5: Severe Water Intake Drop
      // -------------------------------------------------------------
      if (record.waterConsumedLiters > 0 && prior != null && prior.waterConsumedLiters > 20.0) {
        final waterDropPct =
            ((prior.waterConsumedLiters - record.waterConsumedLiters) /
                    prior.waterConsumedLiters) *
                100.0;
        if (waterDropPct >= 25.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_water_drop_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '🚨 Severe Water Intake Drop (-${waterDropPct.toStringAsFixed(0)}%) — $batchName',
              body:
                  'Water intake plummeted from ${prior.waterConsumedLiters.toStringAsFixed(0)}L to ${record.waterConsumedLiters.toStringAsFixed(0)}L. Check for airlocks, closed valves, or drinker blockages immediately!',
              type: NotificationType.water,
              priority: NotificationPriority.critical,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'water_intake_drop',
                'priorWaterLiters': prior.waterConsumedLiters,
                'currentWaterLiters': record.waterConsumedLiters,
                'recommendations': [
                  'Immediately walk drinker lines and test nipple discharge',
                  'Check main water pump and header tank level',
                  'Flush drinker lines to clear potential airlocks',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 6: Water-to-Feed Ratio Anomaly
      // -------------------------------------------------------------
      if (record.waterConsumedLiters > 0 && record.feedConsumedKg > 0) {
        final ratio = record.waterConsumedLiters / record.feedConsumedKg;
        if (ratio > 2.4) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_wf_ratio_high_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '⚠️ Abnormally High Water Ratio (${ratio.toStringAsFixed(1)}:1) — $batchName',
              body:
                  'Water consumed is elevated (${ratio.toStringAsFixed(1)}:1 vs ~1.8:1 normal). Check for drinker line leaks, loose nipples, heat stress panting, or enteritis.',
              type: NotificationType.water,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'water_ratio_high',
                'ratio': ratio,
                'recommendations': [
                  'Inspect litter for wet spots under drinker lines',
                  'Check for stuck or leaking nipple pins',
                  'Verify shed temperature (birds flush water under heat stress)',
                ],
              },
            ),
          );
        } else if (ratio < 1.4) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_wf_ratio_low_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '⚠️ Low Water-to-Feed Ratio (${ratio.toStringAsFixed(1)}:1) — $batchName',
              body:
                  'Flock is drinking insufficient water for the feed eaten (${ratio.toStringAsFixed(1)}:1). Restricting water severely hampers feed conversion and bird health.',
              type: NotificationType.water,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'water_ratio_low',
                'ratio': ratio,
                'recommendations': [
                  'Check drinker water pressure regulators',
                  'Inspect for mineral scale or biofilm inside water filters',
                  'Ensure drinkers are at correct height for birds to reach',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 7: Heat Stress Emergency (High THI / Temp)
      // -------------------------------------------------------------
      if (record.temperature != null) {
        final temp = record.temperature!;
        final hum = record.humidity ?? 65.0;
        final thi = 0.8 * temp + (hum / 100.0) * (temp - 14.4) + 46.4;

        if (temp >= 34.0 || thi >= 80.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_heat_emergency_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '🔥 HEAT STRESS EMERGENCY (THI ${thi.toStringAsFixed(1)}) — $batchName',
              body:
                  'Shed temperature reached ${temp.toStringAsFixed(1)}°C with ${hum.toStringAsFixed(0)}% RH (THI ${thi.toStringAsFixed(1)}). Fatal heat stroke imminent. Turn on cooling pads and maximum tunnel fans!',
              type: NotificationType.weather,
              priority: NotificationPriority.critical,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'heat_stress_emergency',
                'temperature': temp,
                'humidity': hum,
                'thi': thi,
                'recommendations': [
                  'Run evaporative cooling pads and all tunnel exhaust fans',
                  'Ensure cool, fresh water is available in drinker lines',
                  'Do NOT disturb or move birds during peak afternoon heat',
                  'Add electrolytes or vitamin C to drinking water',
                ],
              },
            ),
          );
        } else if (temp >= 32.0 || thi >= 76.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_heat_warn_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '🌡️ Heat Stress Warning (THI ${thi.toStringAsFixed(1)}) — $batchName',
              body:
                  'Elevated heat index recorded (${temp.toStringAsFixed(1)}°C, ${hum.toStringAsFixed(0)}% RH). Activate cooling pads and maintain air velocity.',
              type: NotificationType.weather,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'heat_stress_warning',
                'recommendations': [
                  'Check air velocity in the center and sidewalls of the shed',
                  'Flush drinker lines with cool water',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 8: Cold Stress & Chick Chilling Hazard
      // -------------------------------------------------------------
      if (record.temperature != null) {
        final temp = record.temperature!;
        if (ageDays <= 7 && temp < 28.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_cold_brood_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '❄️ CRITICAL: Chick Chilling Emergency (${temp.toStringAsFixed(1)}°C) — $batchName',
              body:
                  'Brooding temperature fell to ${temp.toStringAsFixed(1)}°C (target: 32–33°C). Chicks cannot thermoregulate and will huddle, stop feeding, and suffer high mortality. Ignite brooders immediately!',
              type: NotificationType.weather,
              priority: NotificationPriority.critical,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'chick_chilling',
                'temperature': temp,
                'recommendations': [
                  'Ignite gas brooders or heat lamps immediately',
                  'Check brooding ring curtains for cold drafts',
                  'Verify floor litter temperature is at least 30°C',
                ],
              },
            ),
          );
        } else if (ageDays > 7 && temp < 18.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_cold_growth_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '❄️ Cold Stress Warning (${temp.toStringAsFixed(1)}°C) — $batchName',
              body:
                  'House temperature is below minimum comfort range (${temp.toStringAsFixed(1)}°C). Chilling causes energy diversion to body heat and wet litter.',
              type: NotificationType.weather,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'cold_stress',
                'temperature': temp,
                'recommendations': [
                  'Adjust minimum ventilation timer and close inlet gaps',
                  'Ensure litter remains dry to prevent foot-pad dermatitis',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 9: Extreme Shed Humidity Anomaly
      // -------------------------------------------------------------
      if (record.humidity != null) {
        final hum = record.humidity!;
        if (hum >= 85.0) {
          anomalies.add(
            NotificationModel(
              id: 'anomaly_hum_high_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '⚠️ High Shed Humidity Alert (${hum.toStringAsFixed(0)}%) — $batchName',
              body:
                  'Humidity is excessive (${hum.toStringAsFixed(0)}%). High moisture causes wet litter, toxic ammonia generation, and coccidiosis flare-ups.',
              type: NotificationType.weather,
              priority: NotificationPriority.normal,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'high_humidity',
                'humidity': hum,
                'recommendations': [
                  'Increase minimum ventilation fan run time',
                  'Check for leaking drinker cups or faulty fogger nozzles',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 10: Growth Lag or Flock Weight Loss
      // -------------------------------------------------------------
      if (record.avgWeightGrams > 0) {
        if (prior != null &&
            prior.avgWeightGrams > 0 &&
            prior.avgWeightGrams > record.avgWeightGrams + 20.0) {
          final lostGrams =
              (prior.avgWeightGrams - record.avgWeightGrams).toStringAsFixed(0);
          anomalies.add(
            NotificationModel(
              id: 'anomaly_wt_loss_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '📉 Flock Weight Loss Detected (-${lostGrams}g) — $batchName',
              body:
                  'Flock average weight decreased from ${prior.avgWeightGrams.toStringAsFixed(0)}g to ${record.avgWeightGrams.toStringAsFixed(0)}g. Broilers should never lose weight; check for disease, feed outage, or weighing discrepancy.',
              type: NotificationType.batch,
              priority: NotificationPriority.critical,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'weight_loss',
                'priorWeightGrams': prior.avgWeightGrams,
                'currentWeightGrams': record.avgWeightGrams,
                'recommendations': [
                  'Re-sample weigh a cross-section of 50–100 birds',
                  'Check feed bins to ensure feed was not interrupted',
                  'Examine flock for subclinical enteritis or coccidiosis',
                ],
              },
            ),
          );
        } else if (std.targetWeightGrams > 0 &&
            record.avgWeightGrams < std.targetWeightGrams * 0.82) {
          final lagPct =
              ((std.targetWeightGrams - record.avgWeightGrams) /
                      std.targetWeightGrams *
                      100.0)
                  .toStringAsFixed(0);
          anomalies.add(
            NotificationModel(
              id: 'anomaly_wt_lag_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
              title: '📉 Severe Growth Lag Alert (-$lagPct%) — $batchName',
              body:
                  'Flock weight (${record.avgWeightGrams.toStringAsFixed(0)}g) is lagging significantly behind breed target (${std.targetWeightGrams.toStringAsFixed(0)}g) on Day $ageDays.',
              type: NotificationType.batch,
              priority: NotificationPriority.high,
              createdAt: now,
              isSmartAlert: true,
              relatedFarmId: farmId,
              relatedBatchId: batchId,
              actionUrl: '/daily-record',
              metadata: {
                'anomalyType': 'growth_lag',
                'targetWeightGrams': std.targetWeightGrams,
                'actualWeightGrams': record.avgWeightGrams,
                'recommendations': [
                  'Assess stocking density and feeder pan access',
                  'Verify nutrient density and protein level of current feed',
                  'Ensure adequate lighting program for feed consumption',
                ],
              },
            ),
          );
        }
      }

      // -------------------------------------------------------------
      // ANOMALY 11: Clinical Disease Symptoms Reported
      // -------------------------------------------------------------
      if (record.symptoms != null && record.symptoms!.trim().isNotEmpty) {
        final sym = record.symptoms!.trim();
        anomalies.add(
          NotificationModel(
            id: 'anomaly_sym_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
            title: '🩺 Clinical Symptoms Reported — $batchName',
            body:
                'Health observation recorded on Day $ageDays: "$sym". Isolate affected birds and consult your poultry veterinarian.',
            type: NotificationType.medicine,
            priority: NotificationPriority.critical,
            createdAt: now,
            isSmartAlert: true,
            relatedFarmId: farmId,
            relatedBatchId: batchId,
            actionUrl: '/daily-record',
            metadata: {
              'anomalyType': 'symptoms_reported',
              'symptoms': sym,
              'recommendations': [
                'Immediately isolate sick birds in a quarantine pen',
                'Replenish biosecurity footbaths at all shed entrances',
                'Call your poultry veterinarian for prescription intervention',
              ],
            },
          ),
        );
      }

      // -------------------------------------------------------------
      // ANOMALY 12: Generator (DG) Low Fuel Warning
      // -------------------------------------------------------------
      if (record.dgLevelLiters != null && record.dgLevelLiters! <= 20.0) {
        anomalies.add(
          NotificationModel(
            id: 'anomaly_dg_${batchId}_${record.recordDate.millisecondsSinceEpoch}',
            title: '⛽ Critical Generator Fuel Alert (${record.dgLevelLiters!.toStringAsFixed(0)}L)',
            body:
                'Diesel generator fuel level is dangerously low (${record.dgLevelLiters!.toStringAsFixed(0)}L). In the event of a power outage, ventilation will fail. Refill immediately!',
            type: NotificationType.dg,
            priority: NotificationPriority.critical,
            createdAt: now,
            isSmartAlert: true,
            relatedFarmId: farmId,
            relatedBatchId: batchId,
            actionUrl: '/daily-record',
            metadata: {
              'anomalyType': 'low_dg_fuel',
              'dgLevelLiters': record.dgLevelLiters,
              'recommendations': [
                'Refill diesel storage tank immediately',
                'Test automatic transfer switch (ATS) operation',
              ],
            },
          ),
        );
      }

      // -------------------------------------------------------------
      // DISPATCH NOTIFICATIONS TO FIRESTORE & LOCAL PUSH CHANNELS
      // -------------------------------------------------------------
      if (anomalies.isNotEmpty) {
        final settings = await NotificationFirestoreService.getSettings();

        for (final alert in anomalies) {
          // 1. Save to Notification Center (Firestore & in-memory)
          await NotificationFirestoreService.saveNotification(alert);

          // 2. Trigger push / local notification
          final pushKey = '${alert.id}_${alert.title}';
          if (!_sentAnomalyKeys.contains(pushKey)) {
            _sentAnomalyKeys.add(pushKey);

            try {
              await FcmLocalNotificationService.showLocalNotification(
                title: alert.title,
                body: alert.body,
                priority: alert.priority,
                settings: settings,
              );
            } catch (e) {
              debugPrint(
                '[DataAnomalyDetectorService] Local push alert dispatch skipped: $e',
              );
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[DataAnomalyDetectorService] Error evaluating anomalies: $e\n$stack');
    }

    return anomalies;
  }
}
