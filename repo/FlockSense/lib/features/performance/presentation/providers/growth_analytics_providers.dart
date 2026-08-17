import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/performance/data/growth_analytics_service.dart';
import 'package:flock_sense/features/performance/domain/growth_analytics_model.dart';

final growthAnalyticsServiceProvider = Provider<GrowthAnalyticsService>((ref) {
  return GrowthAnalyticsService();
});

class GrowthAnalyticsFilterNotifier extends Notifier<GrowthAnalyticsFilterState> {
  @override
  GrowthAnalyticsFilterState build() => const GrowthAnalyticsFilterState();

  void selectFarm(String? farmId) {
    state = state.copyWith(
      selectedFarmId: farmId,
      clearFarm: farmId == null,
      clearBatch: true,
    );
  }

  void selectBatch(String? batchId) {
    state = state.copyWith(
      selectedBatchId: batchId,
      clearBatch: batchId == null,
    );
  }

  void selectDateRange(AnalyticsDateRange range) {
    state = state.copyWith(dateRange: range);
  }

  void resetFilters() {
    state = const GrowthAnalyticsFilterState();
  }
}

final growthAnalyticsFilterProvider =
    NotifierProvider<GrowthAnalyticsFilterNotifier, GrowthAnalyticsFilterState>(
  GrowthAnalyticsFilterNotifier.new,
);

final growthAnalyticsStreamProvider =
    StreamProvider.autoDispose<GrowthAnalyticsData>((ref) {
  final authState = ref.watch(authStateProvider);
  final filter = ref.watch(growthAnalyticsFilterProvider);
  final service = ref.watch(growthAnalyticsServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(service.getFallbackData(filter: filter));
      return service.watchAnalytics(uid: user.uid, filter: filter);
    },
    loading: () => Stream.value(service.getFallbackData(filter: filter)),
    error: (err, stack) => Stream.value(service.getFallbackData(filter: filter)),
  );
});
