import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/core/models/sync_status.dart';

/// Family provider: pass farmId to get its sheds as a real-time stream.
final shedListProvider = StreamProvider.autoDispose.family<List<ShedModel>, String>((ref, farmId) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ShedService.watchSheds(farmId);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Sync status for a specific farm's sheds collection.
final shedSyncStatusProvider = StreamProvider.autoDispose.family<SyncStatus, String>((ref, farmId) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(SyncStatus.synced);
      return ShedService.watchSyncStatus(farmId);
    },
    loading: () => Stream.value(SyncStatus.synced),
    error: (_, __) => Stream.value(SyncStatus.synced),
  );
});
