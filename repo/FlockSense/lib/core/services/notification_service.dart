import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    ),
  );

  await plugin.show(
    1000,
    message.notification?.title ?? 'Farm Alert',
    message.notification?.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService._channelId,
        NotificationService._channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: message.data['route'],
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const String _prefsKey = 'notif_prefs';
  static const String _channelId = 'flocksense_alerts';
  static const String _channelName = 'Farm Alerts';
  static String? _pendingPayload;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final didRequest = prefs.getBool('fcm_permission_requested') ?? false;

    final androidSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: !didRequest,
      requestBadgePermission: !didRequest,
      requestSoundPermission: !didRequest,
    );

    await _local.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) async {
        await _handleNotificationTap(details.payload);
      },
    );

    await _createNotificationChannel();
    tz.initializeTimeZones();

    if (!didRequest) {
      await _requestPermissions();
      await prefs.setBool('fcm_permission_requested', true);
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.notification == null) return;
      await _showLocalNotification(
        id: 1000,
        title: message.notification?.title ?? 'Farm Alert',
        body: message.notification?.body ?? '',
        payload: message.data['route'],
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleNotificationTap(message.data['route']);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationTap(initialMessage.data['route']);
    }

    _fcm.onTokenRefresh.listen((_) async {
      await _saveFcmTokenToFirestore();
    });

    await _saveFcmTokenToFirestore();

    final prefsMap = await getPreferences();
    if (prefsMap['daily'] == true) {
      await scheduleDailyRecordReminder();
    } else {
      await cancelDailyReminder();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingPayload();
    });
  }

  static Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      return {'daily': true, 'mortality': true, 'vaccine': true, 'feed': false};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return {'daily': true, 'mortality': true, 'vaccine': true, 'feed': false};
    }

    return {
      'daily': decoded['daily'] as bool? ?? true,
      'mortality': decoded['mortality'] as bool? ?? true,
      'vaccine': decoded['vaccine'] as bool? ?? true,
      'feed': decoded['feed'] as bool? ?? false,
    };
  }

  static Future<void> savePreferences({
    required bool daily,
    required bool mortality,
    required bool vaccine,
    required bool feed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'daily': daily,
        'mortality': mortality,
        'vaccine': vaccine,
        'feed': feed,
      }),
    );

    if (daily) {
      await scheduleDailyRecordReminder();
    } else {
      await cancelDailyReminder();
    }
  }

  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      id: 1001,
      title: 'FlockSense Test Alert',
      body: 'This is a test notification from FlockSense.',
      payload: '/main',
    );
  }

  static Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        playSound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  static Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      await _local
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _saveFcmTokenToFirestore() async {
    final token = await _fcm.getToken();
    if (token == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    _pendingPayload = payload;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingPayload();
    });
  }

  static void _flushPendingPayload() {
    if (_pendingPayload == null) return;
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) return;

    navigatorState.pushNamed(_pendingPayload!);
    _pendingPayload = null;
  }

  static Future<void> scheduleVaccinationReminder({
    required String batchId,
    required String batchName,
    required DateTime placementDate,
  }) async {
    final prefsMap = await getPreferences();
    if (prefsMap['vaccine'] != true) return;

    final firstDate = placementDate.add(const Duration(days: 14));
    final secondDate = placementDate.add(const Duration(days: 18));
    final baseId = batchId.hashCode;

    if (firstDate.isAfter(DateTime.now())) {
      final firstSchedule = tz.TZDateTime.from(firstDate, tz.local);
      await _local.zonedSchedule(
        baseId,
        'Gumboro (IBD) vaccination due today for $batchName',
        'Schedule the vaccine and mark it in the batch record.',
        firstSchedule,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/main',
      );
    }

    if (secondDate.isAfter(DateTime.now())) {
      final secondSchedule = tz.TZDateTime.from(secondDate, tz.local);
      await _local.zonedSchedule(
        baseId + 1,
        'NDV (Newcastle) vaccination due today for $batchName',
        'Schedule the vaccine and mark it in the batch record.',
        secondSchedule,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/main',
      );
    }
  }

  static Future<void> scheduleDailyRecordReminder() async {
    final prefsMap = await getPreferences();
    if (prefsMap['daily'] != true) return;

    final now = DateTime.now();
    final scheduled = DateTime(now.year, now.month, now.day, 19);
    final target = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;

    final scheduledDate = tz.TZDateTime.from(target, tz.local);
    await _local.zonedSchedule(
      9999,
      'Daily record pending',
      "Don't forget to log today's farm records",
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/main',
    );
  }

  static Future<void> cancelBatchReminders(String batchId) async {
    final baseId = batchId.hashCode;
    await _local.cancel(baseId);
    await _local.cancel(baseId + 1);
  }

  static Future<void> cancelDailyReminder() async {
    await _local.cancel(9999);
  }

  static Future<void> checkMortalityAlert({
    required String batchName,
    required int mortalityCount,
    required int totalBirds,
    required int batchAgeDay,
  }) async {
    final prefsMap = await getPreferences();
    if (prefsMap['mortality'] != true) return;
    if (totalBirds <= 0) return;
    final rate = mortalityCount / totalBirds * 100;
    if (rate <= 2.0) return;

    await _showLocalNotification(
      id: 9000,
      title: '⚠ High Mortality Alert — $batchName',
      body:
          '$mortalityCount birds died today (Day $batchAgeDay). Check your flock immediately.',
      payload: '/main',
    );
  }
}
