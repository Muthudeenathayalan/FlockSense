import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';
import 'package:flock_sense/features/reports/data/report_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

// Filter State Notifier
class ReportsFilterNotifier extends Notifier<ReportFilterState> {
  @override
  ReportFilterState build() => const ReportFilterState();

  void setFarmId(String? farmId) {
    state = state.copyWith(selectedFarmId: farmId, clearBatch: true);
  }

  void setBatchId(String? batchId) {
    state = state.copyWith(selectedBatchId: batchId);
  }

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(datePreset: preset);
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      datePreset: DateRangePreset.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = const ReportFilterState();
  }
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportFilterState>(
      ReportsFilterNotifier.new,
    );

// Data Provider watching active filter
final reportsDataProvider = FutureProvider<ReportData>((ref) async {
  final filter = ref.watch(reportsFilterProvider);
  return ReportService.loadFilteredReportData(filter: filter);
});

// Report History Notifier
class ReportsHistoryNotifier extends Notifier<List<ReportHistoryItem>> {
  @override
  List<ReportHistoryItem> build() {
    loadHistory();
    return [];
  }

  Future<void> loadHistory() async {
    final history = await ReportHistoryService.getHistory();
    state = history;
  }

  Future<void> addHistoryItem(ReportHistoryItem item) async {
    await ReportHistoryService.saveHistoryItem(item);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await ReportHistoryService.clearHistory();
    state = [];
  }
}

final reportsHistoryProvider =
    NotifierProvider<ReportsHistoryNotifier, List<ReportHistoryItem>>(
      ReportsHistoryNotifier.new,
    );
