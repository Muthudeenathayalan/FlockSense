import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkllx22TkV5JVuDeZVCwEK4CG0WBUguMI',
    appId: '1:522217107399:android:fbcb7e50007d28a094b3e2',
    messagingSenderId: '522217107399',
    projectId: 'flocksense-app',
    storageBucket: 'flocksense-app.firebasestorage.app',
  );
}
