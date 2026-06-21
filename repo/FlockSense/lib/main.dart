import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/app/app.dart';
import 'package:flock_sense/config/firebase_options.dart';
import 'package:flock_sense/core/services/cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local cache service
  await CacheService().initialize();

  runApp(const ProviderScope(child: App()));
}
