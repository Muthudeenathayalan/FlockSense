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

class SmartAlertEvaluator {
  SmartAlertEvaluator._();

  static Future<List<NotificationModel>> evaluateSmartAlerts() async {
    final alerts = <NotificationModel>[];

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final inventoryService = InventoryService();
          final inventoryItems = await inventoryService
              .watchInventoryItems(uid: user.uid)
              .first;
          for (final item in inventoryItems) {
            if (item.quantityAvailable <= item.minStockLevel) {
              final isFeed = item.category.toLowerCase().contains('feed');
              final notif = NotificationModel(
                id: 'smart_inv_${item.id}',
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
          }
        } catch (e) {
          debugPrint('[SmartAlertEvaluator] Finance evaluation error: $e');
        }

        // 3. Evaluate Real User Flock Batches for Vaccination, Harvest & Mortality
        try {
          final farms = await FarmService.getUserFarms();
          for (final farm in farms) {
            final batches = await BatchService.getBatchesForFarm(farm.id);
            for (final b in batches) {
              if (b.status.toLowerCase() != 'active') continue;

              final ageDays =
                  DateTime.now().difference(b.placementDate).inDays + 1;

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
              }

              // Mortality Spike Alert from live daily records
              try {
                final records = await DailyRecordService.getAllDailyRecords(
                  farmId: farm.id,
                  batchId: b.id,
                );
                if (records.isNotEmpty) {
                  records.sort((x, y) => y.recordDate.compareTo(x.recordDate));
                  final latest = records.first;
                  if (latest.mortalityCount > 0 && latest.openingBirds > 0) {
                    final mortPct =
                        (latest.mortalityCount / latest.openingBirds) * 100;
                    if (mortPct >= 1.0) {
                      alerts.add(
                        NotificationModel(
                          id: 'smart_mort_spike_${b.id}_${latest.batchAgeDay}',
                          title:
                              'CRITICAL: High Mortality Spike — ${b.batchName}',
                          body:
                              '${latest.mortalityCount} bird mortality recorded (${mortPct.toStringAsFixed(1)}% of flock) on Day ${latest.batchAgeDay}. Check ventilation, water lines, and bird health immediately.',
                          type: NotificationType.batch,
                          priority: NotificationPriority.critical,
                          createdAt: DateTime.now(),
                          isSmartAlert: true,
                          relatedFarmId: farm.id,
                          relatedBatchId: b.id,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                debugPrint(
                  '[SmartAlertEvaluator] Batch record evaluation error: $e',
                );
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
        if (alert.priority == NotificationPriority.critical) {
          await FcmLocalNotificationService.showLocalNotification(
            title: alert.title,
            body: alert.body,
            priority: alert.priority,
          );
        }
      }
    } catch (e) {
      debugPrint('[SmartAlertEvaluator] Evaluation error: $e');
    }

    return alerts;
  }
}
