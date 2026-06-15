import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/data/user_state_service.dart';

/// Provider for UserStateService instance
final userStateServiceProvider = Provider<UserStateService>((ref) {
  return UserStateService();
});

/// Provider for current user state (single value)
final userStateProvider = FutureProvider<UserState>((ref) async {
  final service = ref.watch(userStateServiceProvider);
  return service.getUserState();
});

/// Provider for user state stream (reactive)
final userStateStreamProvider = StreamProvider<UserState>((ref) {
  final service = ref.watch(userStateServiceProvider);
  return service.getUserStateStream();
});
