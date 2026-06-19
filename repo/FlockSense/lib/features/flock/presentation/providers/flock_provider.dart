import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/flock/domain/flock.dart';
import 'package:flock_sense/features/flock/data/firestore_service.dart';

final flockListProvider = StreamProvider.autoDispose<List<Flock>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return const Stream<List<Flock>>.empty();
      }
      return FirestoreService(uid: user.uid).watchFlocks();
    },
    loading: () => const Stream<List<Flock>>.empty(),
    error: (error, _) => const Stream<List<Flock>>.empty(),
  );
});
