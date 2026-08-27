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

  // --- Notifications Stream & CRUD ---
  static Stream<List<NotificationModel>> streamNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<List<NotificationModel>>.value(
        List<NotificationModel>.unmodifiable(_localNotifications),
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<List<NotificationModel>>((snap) {
          final list = snap.docs
              .map((doc) => NotificationModel.fromJson(doc.data()))
              .toList();
          return list.isEmpty
              ? List<NotificationModel>.unmodifiable(_localNotifications)
              : list;
        })
        .handleError((err) {
          debugPrint(
            '[NotificationFirestoreService] streamNotifications error: $err',
          );
          return List<NotificationModel>.unmodifiable(_localNotifications);
        });
  }

  static Future<void> saveNotification(NotificationModel notification) async {
    final user = _auth.currentUser;
    final index = _localNotifications.indexWhere(
      (n) => n.id == notification.id,
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
            .set(notification.toJson());
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
