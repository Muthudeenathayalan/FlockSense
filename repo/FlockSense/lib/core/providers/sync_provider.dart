import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/services/sync_service.dart';

/// Exposes the number of operations still queued for sync.
/// Screens watch this to show/hide the SyncStatusBanner.
final pendingOpsCountProvider = StreamProvider<int>((ref) {
  return SyncService().pendingCountStream;
});
