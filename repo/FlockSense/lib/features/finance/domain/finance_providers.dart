import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';
import 'package:flock_sense/features/finance/domain/finance_analytics_engine.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';

import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class FinanceFilterState {
  final String? selectedFarmId;
  final String? selectedBatchId;
  final FinanceTransactionType? typeFilter; // null = All, income, expense
  final PaymentStatus? paymentStatusFilter;
  final int month;
  final int year;
  final String searchQuery;

  FinanceFilterState({
    this.selectedFarmId,
    this.selectedBatchId,
    this.typeFilter,
    this.paymentStatusFilter,
    int? month,
    int? year,
    this.searchQuery = '',
  }) : month = month ?? DateTime.now().month,
       year = year ?? DateTime.now().year;

  FinanceFilterState copyWith({
    String? selectedFarmId,
    String? selectedBatchId,
    FinanceTransactionType? typeFilter,
    PaymentStatus? paymentStatusFilter,
    int? month,
    int? year,
    String? searchQuery,
    bool clearFarm = false,
    bool clearBatch = false,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return FinanceFilterState(
      selectedFarmId: clearFarm
          ? null
          : (selectedFarmId ?? this.selectedFarmId),
      selectedBatchId: clearBatch
          ? null
          : (selectedBatchId ?? this.selectedBatchId),
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      paymentStatusFilter: clearStatus
          ? null
          : (paymentStatusFilter ?? this.paymentStatusFilter),
      month: month ?? this.month,
      year: year ?? this.year,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FinanceFilterNotifier extends Notifier<FinanceFilterState> {
  @override
  FinanceFilterState build() {
    final activeFarmId = ref.watch(selectedDashboardFarmIdProvider);
    return FinanceFilterState(selectedFarmId: activeFarmId);
  }

  void setFarmId(String? farmId) {
    state = state.copyWith(
      selectedFarmId: farmId,
      clearFarm: farmId == null || farmId == 'all',
      clearBatch: true,
    );
  }

  void setBatchId(String? batchId) {
    state = state.copyWith(
      selectedBatchId: batchId,
      clearBatch: batchId == null || batchId == 'all',
    );
  }

  void setTypeFilter(FinanceTransactionType? type) {
    state = state.copyWith(typeFilter: type, clearType: type == null);
  }

  void setPaymentStatusFilter(PaymentStatus? status) {
    state = state.copyWith(
      paymentStatusFilter: status,
      clearStatus: status == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    final activeFarmId = ref.read(selectedDashboardFarmIdProvider);
    state = FinanceFilterState(selectedFarmId: activeFarmId);
  }
}

final financeFilterProvider =
    NotifierProvider<FinanceFilterNotifier, FinanceFilterState>(
      FinanceFilterNotifier.new,
    );

final financeTransactionsProvider =
    FutureProvider<List<FinanceTransactionModel>>((ref) async {
      // Re-fetch automatically whenever batches or farms update
      ref.watch(allUserBatchesProvider);
      ref.watch(farmListProvider);
      return FinanceService.getCombinedTransactions();
    });

final financeBudgetStreamProvider = StreamProvider<FinanceBudgetModel>((ref) {
  final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
  return FinanceService.streamBudget(currentMonthYear);
});

final financeAnalyticsProvider = Provider<FinanceAnalyticsResult>((ref) {
  final filter = ref.watch(financeFilterProvider);
  final txsAsync = ref.watch(financeTransactionsProvider);
  final budgetAsync = ref.watch(financeBudgetStreamProvider);
  final batchesAsync = ref.watch(allUserBatchesProvider);
  final farmsAsync = ref.watch(farmListProvider);

  var transactions = txsAsync.asData?.value ?? [];

  // Filter transactions by farm if a specific farm is selected
  if (filter.selectedFarmId != null &&
      filter.selectedFarmId!.isNotEmpty &&
      filter.selectedFarmId != 'all') {
    transactions = transactions
        .where((t) => t.farmId == filter.selectedFarmId)
        .toList();
  }

  // Filter transactions by batch if a specific batch is selected
  if (filter.selectedBatchId != null &&
      filter.selectedBatchId!.isNotEmpty &&
      filter.selectedBatchId != 'all') {
    transactions = transactions
        .where((t) => t.batchId == filter.selectedBatchId)
        .toList();
  }

  final budget =
      budgetAsync.asData?.value ??
      FinanceBudgetModel(
        id: 'bud_current',
        farmId: filter.selectedFarmId ?? 'all',
        monthYear: DateFormat('yyyy-MM').format(DateTime.now()),
        updatedAt: DateTime.now(),
      );

  final batches = batchesAsync.asData?.value ?? [];
  final farms = farmsAsync.asData?.value ?? [];

  final batchNames = <String, String>{
    for (final b in batches) b.id: b.batchName,
  };
  final farmNames = <String, String>{
    for (final f in farms) f.id: f.farmName,
  };

  final filteredBatches = (filter.selectedFarmId != null &&
          filter.selectedFarmId!.isNotEmpty &&
          filter.selectedFarmId != 'all')
      ? batches.where((b) => b.farmId == filter.selectedFarmId).toList()
      : batches;

  final activeBirds = filteredBatches
      .where((b) => b.isActive)
      .fold<int>(0, (sum, b) => sum + b.currentBirds);

  return FinanceAnalyticsEngine.calculateAnalytics(
    transactions: transactions,
    budget: budget,
    activeBirdCount: activeBirds,
    batchNames: batchNames,
    farmNames: farmNames,
  );
});
