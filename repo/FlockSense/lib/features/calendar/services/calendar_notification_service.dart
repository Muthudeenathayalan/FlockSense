import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flock_sense/features/calendar/domain/calendar_event_model.dart';

class CalendarNotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'flocksense_reminders';
  static const String _channelName = 'Smart Calendar Reminders';
  static const String _channelDescription =
      'Notifications for scheduled farm tasks, vaccinations, and telemetry alerts.';

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      await _localPlugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
    } catch (e) {
      debugPrint('Error initializing CalendarNotificationService: $e');
    }
  }

  /// Schedule a local notification for a calendar event
  static Future<void> scheduleEventNotification(
    CalendarEventModel event,
  ) async {
    try {
      if (event.isCompleted) return;

      final fullTime = event.fullDateTime;
      final triggerTime = fullTime.subtract(
        Duration(minutes: event.reminderBeforeMinutes),
      );

      if (triggerTime.isBefore(DateTime.now())) {
        return; // Don't schedule past notifications
      }

      final notifId = event.id.hashCode & 0x7FFFFFFF;
      final tzScheduledTime = tz.TZDateTime.from(triggerTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: _importanceForPriority(event.priority),
        priority: _priorityForPriority(event.priority),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localPlugin.zonedSchedule(
        notifId,
        '⏰ ${event.title} (${event.eventType})',
        'Scheduled for ${event.eventTime}. Priority: ${event.priority.toUpperCase()}',
        tzScheduledTime,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/calendar',
      );
    } catch (e) {
      debugPrint('Error scheduling notification for event ${event.id}: $e');
    }
  }

  /// Cancel a scheduled notification for an event
  static Future<void> cancelEventNotification(String eventId) async {
    try {
      final notifId = eventId.hashCode & 0x7FFFFFFF;
      await _localPlugin.cancel(notifId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  static Importance _importanceForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        return Importance.max;
      case 'medium':
        return Importance.high;
      case 'low':
      default:
        return Importance.defaultImportance;
    }
  }

  static Priority _priorityForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        return Priority.max;
      case 'medium':
        return Priority.high;
      case 'low':
      default:
        return Priority.defaultPriority;
    }
  }
}
