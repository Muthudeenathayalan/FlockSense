import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/app/app.dart';
import 'package:flock_sense/config/firebase_options.dart';
import 'package:flock_sense/core/services/cache_service.dart';
import 'package:flock_sense/core/services/fcm_token_service.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/core/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase core init.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // 2. Enable Firestore OFFLINE PERSISTENCE.
  //    This is the single most important setting for offline support.
  //    With this on, every set()/update()/delete() call succeeds immediately
  //    regardless of network state — the SDK stores the write in a local
  //    SQLite file and replays it to the server automatically once the device
  //    reconnects. snapshots() streams also emit from the local cache
  //    instantly (isFromCache=true) and re-emit when server data arrives.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 3. Local Hive cache (our own queue layer on top of Firestore's built-in one).
  await CacheService().initialize();

  // 4. SyncService — drains app-level pending queue when back online.
  await SyncService().initialize();

  await NotificationService.initialize();

  try {
    await FcmTokenService.saveTokenToFirestore();
  } catch (e) {
    debugPrint('FcmTokenService save token error: $e');
  }

  runApp(const ProviderScope(child: App()));
}
