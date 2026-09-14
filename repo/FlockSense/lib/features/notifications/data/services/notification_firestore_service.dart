import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

class NotificationFirestoreService {
  NotificationFirestoreService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static final List<NotificationModel> _localNotifications = [];
  static final List<ReminderModel> _localReminders = [];
  static NotificationSettingsModel _localSettings =
      const NotificationSettingsModel();

  static String _notificationKey(NotificationModel n) {
    return '${n.type.name}_${n.title.trim().toLowerCase()}_${n.body.trim().toLowerCase()}';
  }

  // --- Notifications Stream & CRUD ---
  static Stream<List<NotificationModel>> streamNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      final deduplicated = <NotificationModel>[];
      final seenKeys = <String>{};
      for (final n in _localNotifications) {
        if (seenKeys.add(_notificationKey(n))) {
          deduplicated.add(n);
        }
      }
      return Stream<List<NotificationModel>>.value(
        List<NotificationModel>.unmodifiable(deduplicated),
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<NotificationModel>>((snap) {
          final deduplicated = <NotificationModel>[];
          final seenIds = <String>{};
          final seenKeys = <String>{};
          final seenPendingBatches = <String>{};

          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            final notif = NotificationModel.fromJson(data);
            final titleLower = notif.title.toLowerCase();
            final bodyLower = notif.body.toLowerCase();

            // Discard any dummy or sample notifications
            if (titleLower.contains('dummy') ||
                bodyLower.contains('dummy') ||
                titleLower.contains('sample alert') ||
                titleLower.contains('test notification') ||
                titleLower.contains('demo notification') ||
                notif.id.contains('test_')) {
              continue;
            }

            // Deduplicate daily record pending: keep only newest 1 per batch
            if (notif.id.startsWith('daily_record_pending') ||
                notif.title.contains('Daily Record Pending')) {
              final batchId = notif.relatedBatchId ??
                  notif.id.replaceFirst('daily_record_pending_', '');
              if (!seenPendingBatches.add(batchId)) continue;
            }

            final key = _notificationKey(notif);
            if (seenIds.add(notif.id) && seenKeys.add(key)) {
              deduplicated.add(notif);
            }
          }

          return deduplicated;
        })
        .handleError((err) {
          debugPrint(
            '[NotificationFirestoreService] streamNotifications error: $err',
          );
          return List<NotificationModel>.unmodifiable(_localNotifications);
        });
  }

  /// Scans Firestore notifications and removes duplicate documents and dummy data
  static Future<int> cleanupDuplicateNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      final seenKeys = <String>{};
      final seenPendingBatches = <String>{};
      final duplicateRefs = <DocumentReference>[];

      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final notif = NotificationModel.fromJson(data);
        final titleLower = notif.title.toLowerCase();
        final bodyLower = notif.body.toLowerCase();

        // 1. Purge dummy/test notifications
        final isDummy = titleLower.contains('dummy') ||
            bodyLower.contains('dummy') ||
            titleLower.contains('sample alert') ||
            titleLower.contains('test notification') ||
            titleLower.contains('demo notification') ||
            notif.id.contains('test_');

        if (isDummy) {
          duplicateRefs.add(doc.reference);
          continue;
        }

        // 2. Daily record pending deduplication: keep only the newest 1 per batch
        if (notif.id.startsWith('daily_record_pending') ||
            notif.title.contains('Daily Record Pending')) {
          final batchId = notif.relatedBatchId ??
              notif.id.replaceFirst('daily_record_pending_', '');
          if (!seenPendingBatches.add(batchId)) {
            duplicateRefs.add(doc.reference);
            continue;
          }
        }

        // 3. General semantic deduplication
        final key = _notificationKey(notif);
        if (!seenKeys.add(key)) {
          duplicateRefs.add(doc.reference);
        }
      }

      if (duplicateRefs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final ref in duplicateRefs) {
          batch.delete(ref);
        }
        await batch.commit();
        debugPrint(
          '[NotificationFirestoreService] Removed ${duplicateRefs.length} duplicate/dummy notifications',
        );
      }

      return duplicateRefs.length;
    } catch (e) {
      debugPrint(
        '[NotificationFirestoreService] cleanupDuplicateNotifications error: $e',
      );
      return 0;
    }
  }

  /// Removes all pending daily record notification alerts for a given batch
  static Future<void> deletePendingDailyRecordNotifications(
    String batchId,
  ) async {
    _localNotifications.removeWhere(
      (n) =>
          n.id == 'daily_record_pending_$batchId' ||
          n.id.startsWith('daily_record_pending_${batchId}_') ||
          (n.relatedBatchId == batchId &&
              n.id.startsWith('daily_record_pending')),
    );

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .get();

        final batch = _firestore.batch();
        var deletedCount = 0;
        for (final doc in snap.docs) {
          final id = doc.id;
          final data = doc.data();
          final relatedBatchId = data['relatedBatchId'] as String?;
          if (id == 'daily_record_pending_$batchId' ||
              id.startsWith('daily_record_pending_${batchId}_') ||
              (relatedBatchId == batchId &&
                  id.startsWith('daily_record_pending'))) {
            batch.delete(doc.reference);
            deletedCount++;
          }
        }
        if (deletedCount > 0) {
          await batch.commit();
        }
      } catch (e) {
        debugPrint(
          '[NotificationFirestoreService] deletePendingDailyRecordNotifications error: $e',
        );
      }
    }
  }

  static Future<void> saveNotification(NotificationModel notification) async {
    final user = _auth.currentUser;
    final key = _notificationKey(notification);
    final index = _localNotifications.indexWhere(
      (n) => n.id == notification.id || _notificationKey(n) == key,
    );
    if (index >= 0) {
      _localNotifications[index] = notification;
    } else {
      _localNotifications.insert(0, notification);
    }

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint(
          '[NotificationFirestoreService] saveNotification failed: $e',
        );
      }
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _localNotifications[index] = _localNotifications[index].copyWith(
        status: NotificationStatus.read,
      );
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'status': NotificationStatus.read.name});
      } catch (e) {
        debugPrint('[NotificationFirestoreService] markAsRead failed: $e');
      }
    }
  }

  static Future<void> markAllAsRead() async {
    for (var i = 0; i < _localNotifications.length; i++) {
      _localNotifications[i] = _localNotifications[i].copyWith(
        status: NotificationStatus.read,
      );
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('status', isEqualTo: NotificationStatus.unread.name)
            .get();

        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {'status': NotificationStatus.read.name});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('[NotificationFirestoreService] markAllAsRead failed: $e');
      }
    }
  }

  static Future<void> togglePin(String notificationId) async {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final current = _localNotifications[index];
      final newStatus = current.status == NotificationStatus.pinned
          ? NotificationStatus.read
          : NotificationStatus.pinned;
      _localNotifications[index] = current.copyWith(status: newStatus);

      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(notificationId)
              .update({'status': newStatus.name});
        } catch (e) {
          debugPrint('[NotificationFirestoreService] togglePin failed: $e');
        }
      }
    }
  }

  static Future<void> archiveNotification(String notificationId) async {
    final index = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _localNotifications[index] = _localNotifications[index].copyWith(
        status: NotificationStatus.archived,
      );
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'status': NotificationStatus.archived.name});
      } catch (e) {
        debugPrint(
          '[NotificationFirestoreService] archiveNotification failed: $e',
        );
      }
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    _localNotifications.removeWhere((n) => n.id == notificationId);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      } catch (e) {
        debugPrint(
          '[NotificationFirestoreService] deleteNotification failed: $e',
        );
      }
    }
  }

  // --- Reminders Stream & CRUD ---
  static Stream<List<ReminderModel>> streamReminders() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<List<ReminderModel>>.value(
        List<ReminderModel>.unmodifiable(_localReminders),
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .orderBy('date', descending: false)
        .snapshots()
        .map<List<ReminderModel>>((snap) {
          final list = snap.docs
              .map((doc) => ReminderModel.fromJson(doc.data()))
              .toList();
          return list.isEmpty
              ? List<ReminderModel>.unmodifiable(_localReminders)
              : list;
        })
        .handleError((err) {
          debugPrint(
            '[NotificationFirestoreService] streamReminders error: $err',
          );
          return List<ReminderModel>.unmodifiable(_localReminders);
        });
  }

  static Future<void> createReminder(ReminderModel reminder) async {
    _localReminders.insert(0, reminder);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminder.id)
            .set(reminder.toJson());
      } catch (e) {
        debugPrint('[NotificationFirestoreService] createReminder failed: $e');
      }
    }
  }

  static Future<void> toggleReminderCompletion(String reminderId) async {
    final index = _localReminders.indexWhere((r) => r.id == reminderId);
    if (index >= 0) {
      final current = _localReminders[index];
      final updated = current.copyWith(isCompleted: !current.isCompleted);
      _localReminders[index] = updated;

      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('reminders')
              .doc(reminderId)
              .update({'isCompleted': updated.isCompleted});
        } catch (e) {
          debugPrint(
            '[NotificationFirestoreService] toggleReminderCompletion failed: $e',
          );
        }
      }
    }
  }

  static Future<void> deleteReminder(String reminderId) async {
    _localReminders.removeWhere((r) => r.id == reminderId);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .delete();
      } catch (e) {
        debugPrint('[NotificationFirestoreService] deleteReminder failed: $e');
      }
    }
  }

  // --- Settings Stream & Update ---
  static Stream<NotificationSettingsModel> streamSettings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(_localSettings);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notification_settings')
        .doc('general')
        .snapshots()
        .map(
          (doc) => doc.exists
              ? NotificationSettingsModel.fromJson(doc.data()!)
              : _localSettings,
        )
        .handleError((err) => _localSettings);
  }

  static Future<void> updateSettings(NotificationSettingsModel settings) async {
    _localSettings = settings;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notification_settings')
            .doc('general')
            .set(settings.toJson());
      } catch (e) {
        debugPrint('[NotificationFirestoreService] updateSettings failed: $e');
      }
    }
  }
}
