import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits whether this device currently has a working internet connection.
///
/// Checked with a real DNS lookup rather than "is wifi/mobile data switched
/// on", because a phone can show full signal bars while the network has no
/// actual route to the internet (a common case on flaky rural/farm
/// connections, which is exactly the situation this app needs to handle
/// well). No extra pub package is needed for this -- `dart:io`'s
/// `InternetAddress.lookup` is part of the Flutter/Dart SDK already, which
/// matters here since this project's `lib/` doesn't have network access to
/// fetch new packages from pub.dev in every environment.
///
/// `dart:io` sockets work on Android, iOS, and desktop, which covers this
/// project's Android target; they are not available on Flutter Web.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  Future<bool> checkOnce() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Emit an immediate reading, then re-check periodically. Riverpod cancels
  // this subscription (stopping the periodic checks) once nothing is
  // watching the provider anymore.
  yield await checkOnce();
  yield* Stream.periodic(const Duration(seconds: 6)).asyncMap((_) => checkOnce());
});
