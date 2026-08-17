import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

class FcmLocalNotificationService {
  FcmLocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[FcmLocalNotificationService] Notification tapped: ${details.payload}');
        },
      );

      // Create Android Notification Channels
      const alertChannel = AndroidNotificationChannel(
        'flocksense_alerts',
        'FlockSense General Alerts',
        description: 'Notifications for farm, batch, feed, medicine, and AI alerts.',
        importance: Importance.high,
      );

      const criticalChannel = AndroidNotificationChannel(
        'flocksense_critical',
        'FlockSense Emergency & Critical Alerts',
        description: 'Urgent mortality spikes, disease alerts, and budget breaches.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(alertChannel);
        await androidImpl.createNotificationChannel(criticalChannel);
      }

      // Initialize FCM Messaging Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground Message Received: ${message.notification?.title}');
        final notif = message.notification;
        if (notif != null) {
          showLocalNotification(
            title: notif.title ?? 'FlockSense Alert',
            body: notif.body ?? '',
            priority: NotificationPriority.high,
          );
        }
      });

      _initialized = true;
      debugPrint('[FcmLocalNotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[FcmLocalNotificationService] Initialization error: $e');
    }
  }

  static bool isQuietHourActive(NotificationSettingsModel settings) {
    if (!settings.quietHoursEnabled) return false;
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final startParts = settings.quietHoursStart.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      final endParts = settings.quietHoursEnd.split(':');
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (startMinutes <= endMinutes) {
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
      } else {
        // Overnight quiet hours e.g. 22:00 to 06:00
        return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    await initialize();

    // Enforce Quiet Hours
    if (isQuietHourActive(settings)) {
      final isEmergency = priority == NotificationPriority.critical;
      if (!isEmergency || !settings.emergencyOverride) {
        debugPrint('[FcmLocalNotificationService] Suppressed by Quiet Hours: $title');
        return;
      }
    }

    final isCritical = priority == NotificationPriority.critical;
    final channelId = isCritical ? 'flocksense_critical' : 'flocksense_alerts';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isCritical ? 'FlockSense Emergency' : 'FlockSense Alerts',
      channelDescription: 'Smart poultry farm notifications',
      importance: isCritical ? Importance.max : Importance.high,
      priority: isCritical ? Priority.max : Priority.high,
      playSound: settings.soundEnabled,
      enableVibration: settings.vibrationEnabled,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, title, body, details);
  }

  static Future<String?> getFcmToken() async {
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();
      return await fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] Get token failed: $e');
      return null;
    }
  }
}
