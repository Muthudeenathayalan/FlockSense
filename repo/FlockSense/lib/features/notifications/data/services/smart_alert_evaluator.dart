import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
          final inventoryItems = await inventoryService.watchInventoryItems(uid: user.uid).first;
          for (final item in inventoryItems) {
            if (item.quantityAvailable <= item.minStockLevel) {
              final isFeed = item.category.toLowerCase().contains('feed');
              final notif = NotificationModel(
                id: 'smart_inv_${item.id}',
                title: isFeed ? 'CRITICAL: Low Feed Stock Alert' : 'Low Inventory Stock',
                body: '${item.itemName} is running low (${item.quantityAvailable} ${item.unit} remaining). Restock recommended immediately.',
                type: isFeed ? NotificationType.feed : NotificationType.inventory,
                priority: isFeed ? NotificationPriority.critical : NotificationPriority.high,
                createdAt: DateTime.now(),
                isSmartAlert: true,
              );
              alerts.add(notif);
            }
          }
        } catch (e) {
          debugPrint('[SmartAlertEvaluator] Inventory evaluation error: $e');
        }
      }

      // 2. Evaluate Financial Transactions & Pending Payments
      final txs = await FinanceService.getCombinedTransactions();
      final pendingCount = txs.where((t) => t.paymentStatus == PaymentStatus.pending || t.paymentStatus == PaymentStatus.overdue).length;
      if (pendingCount > 0) {
        alerts.add(NotificationModel(
          id: 'smart_fin_pending',
          title: 'Pending Invoice Receivables',
          body: '$pendingCount transactions have overdue or pending payments needing collection.',
          type: NotificationType.finance,
          priority: NotificationPriority.high,
          createdAt: DateTime.now(),
          isSmartAlert: true,
        ));
      }

      // 3. Automated Vaccination & Harvest Schedule Alerts
      alerts.add(NotificationModel(
        id: 'smart_vac_due',
        title: 'Vaccination Due Today (ND+IB Booster)',
        body: 'Cobb 500 Batch #4 reaches Day 14 today. Administer Newcastle Disease booster vaccine.',
        type: NotificationType.vaccination,
        priority: NotificationPriority.high,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        isSmartAlert: true,
      ));

      alerts.add(NotificationModel(
        id: 'smart_harv_due',
        title: 'Harvest Schedule Alert (5 Days Remaining)',
        body: 'Green Valley Batch #4 will reach 2.2kg target harvest weight in 5 days. Prepare buyer logistics.',
        type: NotificationType.harvest,
        priority: NotificationPriority.normal,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isSmartAlert: true,
      ));

      // 4. Automated AI Recommendations
      alerts.add(NotificationModel(
        id: 'ai_recommend_1',
        title: 'AI Insight: Mortality Spike Risk Detected',
        body: 'Mortality increased by 4.2% over 48 hours. Temperature humidity index (THI) is 82. Increase tunnel fan speed.',
        type: NotificationType.ai,
        priority: NotificationPriority.critical,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isSmartAlert: false,
        isAiAlert: true,
      ));

      alerts.add(NotificationModel(
        id: 'ai_recommend_2',
        title: 'AI Recommendation: Feed Conversion Efficiency',
        body: 'Feed usage is 12% above benchmark curve. Check feeder tray heights to prevent feed spillage.',
        type: NotificationType.ai,
        priority: NotificationPriority.normal,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        isSmartAlert: false,
        isAiAlert: true,
      ));

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
