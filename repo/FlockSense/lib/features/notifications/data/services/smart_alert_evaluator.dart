import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/fcm_local_notification_service.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';
import 'package:flock_sense/features/notifications/data/services/daily_recommendation_service.dart';
import 'package:flock_sense/features/notifications/data/services/data_anomaly_detector_service.dart';

class SmartAlertEvaluator {
  SmartAlertEvaluator._();

  static final Set<String> _recentlyNotifiedPushKeys = {};

  static Future<List<NotificationModel>> evaluateSmartAlerts() async {
    final alerts = <NotificationModel>[];

    try {
      FirebaseAuth? auth;
      try {
        auth = FirebaseAuth.instance;
      } catch (_) {}
      final user = auth?.currentUser;
      if (user != null) {
        try {
          final inventoryService = InventoryService();
          final inventoryItems = await inventoryService
              .watchInventoryItems(uid: user.uid)
              .first;
          for (final item in inventoryItems) {
            final invAlertId = 'smart_inv_${item.id}';
            if (item.quantityAvailable <= item.minStockLevel) {
              final isFeed = item.category.toLowerCase().contains('feed');
              final notif = NotificationModel(
                id: invAlertId,
                title: isFeed
                    ? 'CRITICAL: Low Feed Stock Alert'
                    : 'Low Inventory Stock',
                body:
                    '${item.itemName} is running low (${item.quantityAvailable} ${item.unit} remaining). Restock recommended immediately.',
                type: isFeed
                    ? NotificationType.feed
                    : NotificationType.inventory,
                priority: isFeed
                    ? NotificationPriority.critical
                    : NotificationPriority.high,
                createdAt: DateTime.now(),
                isSmartAlert: true,
                relatedFarmId: item.farmId,
              );
              alerts.add(notif);
            } else {
              await NotificationFirestoreService.deleteNotification(invAlertId);
            }
          }
        } catch (e) {
          debugPrint('[SmartAlertEvaluator] Inventory evaluation error: $e');
        }

        // 2. Evaluate Financial Transactions & Pending Payments
        try {
          final txs = await FinanceService.getCombinedTransactions();
          final pendingCount = txs
              .where(
                (t) =>
                    t.paymentStatus == PaymentStatus.pending ||
                    t.paymentStatus == PaymentStatus.overdue,
              )
              .length;
          if (pendingCount > 0) {
            alerts.add(
              NotificationModel(
                id: 'smart_fin_pending',
                title: 'Pending Invoice Receivables',
                body:
                    '$pendingCount transactions have overdue or pending payments needing collection.',
                type: NotificationType.finance,
                priority: NotificationPriority.high,
                createdAt: DateTime.now(),
                isSmartAlert: true,
              ),
            );
          } else {
            await NotificationFirestoreService.deleteNotification(
              'smart_fin_pending',
            );
          }
        } catch (e) {
          debugPrint('[SmartAlertEvaluator] Finance evaluation error: $e');
        }

        // 3. Evaluate Real User Flock Batches for Vaccination, Harvest & Mortality
        try {
          final farms = await FarmService.getUserFarms();
          if (farms.isEmpty) {
            // User has 0 farms: clear all smart batch alerts and return
            await NotificationFirestoreService.cleanupDuplicateNotifications();
          } else {
            for (final farm in farms) {
              final batches = await BatchService.getBatchesForFarm(farm.id);
              for (final b in batches) {
                if (b.status.toLowerCase() != 'active' || b.currentBirds <= 0) {
                  // Inactive or empty batch - clean up any dangling alerts
                  await NotificationFirestoreService.deletePendingDailyRecordNotifications(
                    b.id,
                  );
                  await NotificationFirestoreService.deleteNotification(
                    'smart_harv_${b.id}',
                  );
                  continue;
                }

                final ageDays =
                    DateTime.now().difference(b.placementDate).inDays + 1;
                // Guard against future placement dates or invalid negative ages
                if (ageDays <= 0) {
                  continue;
                }

                // 3.0 Real-Time Daily Record Pending Reminder
                try {
                  final now = DateTime.now();
                  final todayRecord =
                      await DailyRecordService.getDailyRecordByDate(
                        farmId: farm.id,
                        batchId: b.id,
                        recordDate: now,
                      );
                  final pendingAlertId = 'daily_record_pending_${b.id}';

                  if (todayRecord == null) {
                    final recentRecords = await DailyRecordService.getAllDailyRecords(
                      farmId: farm.id,
                      batchId: b.id,
                    );
                    final guidance = DailyRecommendationService.getGuidanceForBatch(
                      batch: b,
                      recentRecords: recentRecords,
                    );

                    alerts.add(
                      NotificationModel(
                        id: pendingAlertId,
                        title: guidance.pushNotificationTitle,
                        body: guidance.pushNotificationBody,
                        type: NotificationType.batch,
                        priority: NotificationPriority.high,
                        createdAt: DateTime.now(),
                        isSmartAlert: true,
                        relatedFarmId: farm.id,
                        relatedBatchId: b.id,
                        actionUrl: '/daily-record',
                        metadata: {
                          'batchId': b.id,
                          'farmId': farm.id,
                          'batchAgeDay': guidance.ageDays,
                          'recommendations': guidance.actionItems,
                          'primaryTip': guidance.primaryTip,
                          'phase': guidance.phase,
                          'targetWeightGrams': guidance.targetWeightGrams,
                          'totalEstimatedFeedKg': guidance.totalEstimatedFeedKg,
                        },
                      ),
                    );
                  } else {
                    await NotificationFirestoreService.deletePendingDailyRecordNotifications(
                      b.id,
                    );
                  }
                } catch (e) {
                  debugPrint('[SmartAlertEvaluator] Daily record check error: $e');
                }

              // Vaccination Schedule Alert (e.g. Day 7 Lasota, Day 14 Gumboro)
              if (ageDays == 7 || ageDays == 14 || ageDays == 21) {
                final vaccineName = ageDays == 7
                    ? 'ND Lasota Booster'
                    : (ageDays == 14 ? 'Gumboro IBD' : 'Gumboro Booster');
                alerts.add(
                  NotificationModel(
                    id: 'smart_vac_${b.id}_$ageDays',
                    title: 'Vaccination Due Today ($vaccineName)',
                    body:
                        '${b.batchName} reaches Day $ageDays today. Administer $vaccineName protocol.',
                    type: NotificationType.vaccination,
                    priority: NotificationPriority.high,
                    createdAt: DateTime.now(),
                    isSmartAlert: true,
                    relatedFarmId: farm.id,
                    relatedBatchId: b.id,
                  ),
                );
              }

              // Harvest Schedule Alert (Commercial broiler target: ~42 days)
              if (ageDays >= 37 && ageDays <= 45) {
                alerts.add(
                  NotificationModel(
                    id: 'smart_harv_${b.id}',
                    title: 'Harvest Window Alert — ${b.batchName}',
                    body:
                        '${b.batchName} is at Day $ageDays (target maturity: 42 days). Finalize bird sales logistics.',
                    type: NotificationType.harvest,
                    priority: NotificationPriority.normal,
                    createdAt: DateTime.now(),
                    isSmartAlert: true,
                    relatedFarmId: farm.id,
                    relatedBatchId: b.id,
                  ),
                );
              } else {
                await NotificationFirestoreService.deleteNotification(
                  'smart_harv_${b.id}',
                );
              }

              // Telemetry Anomaly Detection from live user daily records
              try {
                final records = await DailyRecordService.getAllDailyRecords(
                  farmId: farm.id,
                  batchId: b.id,
                );
                if (records.isNotEmpty) {
                  records.sort((x, y) => y.recordDate.compareTo(x.recordDate));
                  final latest = records.first;
                  final prior = records.length > 1 ? records[1] : null;

                  final telemetryAnomalies =
                      await DataAnomalyDetectorService.detectAndDispatchAnomalies(
                        record: latest,
                        farmId: farm.id,
                        batchId: b.id,
                        batch: b,
                        previousRecord: prior,
                      );
                  alerts.addAll(telemetryAnomalies);
                }
              } catch (e) {
                debugPrint(
                  '[SmartAlertEvaluator] Batch anomaly evaluation error: $e',
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[SmartAlertEvaluator] Farm & batch evaluation error: $e');
      }
      }

      // Persist alerts to Firestore & local cache
      for (final alert in alerts) {
        await NotificationFirestoreService.saveNotification(alert);
        final now = DateTime.now();
        final pushKey =
            '${alert.id}_${now.year}_${now.month}_${now.day}';

        final shouldPush = alert.priority == NotificationPriority.critical ||
            alert.priority == NotificationPriority.high;

        if (shouldPush && !_recentlyNotifiedPushKeys.contains(pushKey)) {
          _recentlyNotifiedPushKeys.add(pushKey);
          final settings = await NotificationFirestoreService.getSettings();
          await FcmLocalNotificationService.showLocalNotification(
            title: alert.title,
            body: alert.body,
            priority: alert.priority,
            settings: settings,
          );
        }
      }

      // Automatically clean up any duplicate documents in Firestore
      await NotificationFirestoreService.cleanupDuplicateNotifications();
    } catch (e) {
      debugPrint('[SmartAlertEvaluator] Evaluation error: $e');
    }

    return alerts;
  }
}
