import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';

final batchListProvider = StreamProvider.autoDispose.family<List<BatchModel>, String>((ref, farmId) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return BatchService.watchBatches(farmId);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
