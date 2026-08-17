import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/data/services/finance_service.dart';
import 'package:flock_sense/features/finance/domain/finance_analytics_engine.dart';

class FinanceFilterState {
  final String? selectedFarmId;
  final String? selectedBatchId;
  final FinanceTransactionType? typeFilter; // null = All, income, expense
  final PaymentStatus? paymentStatusFilter;
  final int month;
  final int year;
  final String searchQuery;

  const FinanceFilterState({
    this.selectedFarmId,
    this.selectedBatchId,
    this.typeFilter,
    this.paymentStatusFilter,
    int? month,
    int? year,
    this.searchQuery = '',
  })  : month = month ?? 8,
        year = year ?? 2026;

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
      selectedFarmId: clearFarm ? null : (selectedFarmId ?? this.selectedFarmId),
      selectedBatchId: clearBatch ? null : (selectedBatchId ?? this.selectedBatchId),
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      paymentStatusFilter: clearStatus ? null : (paymentStatusFilter ?? this.paymentStatusFilter),
      month: month ?? this.month,
      year: year ?? this.year,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FinanceFilterNotifier extends Notifier<FinanceFilterState> {
  @override
  FinanceFilterState build() => const FinanceFilterState();

  void setFarmId(String? farmId) {
    state = state.copyWith(selectedFarmId: farmId, clearBatch: true);
  }

  void setBatchId(String? batchId) {
    state = state.copyWith(selectedBatchId: batchId);
  }

  void setTypeFilter(FinanceTransactionType? type) {
    state = state.copyWith(typeFilter: type, clearType: type == null);
  }

  void setPaymentStatusFilter(PaymentStatus? status) {
    state = state.copyWith(paymentStatusFilter: status, clearStatus: status == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = const FinanceFilterState();
  }
}

final financeFilterProvider =
    NotifierProvider<FinanceFilterNotifier, FinanceFilterState>(
  FinanceFilterNotifier.new,
);

final financeTransactionsProvider =
    FutureProvider<List<FinanceTransactionModel>>((ref) async {
  return FinanceService.getCombinedTransactions();
});

final financeBudgetStreamProvider =
    StreamProvider<FinanceBudgetModel>((ref) {
  final currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
  return FinanceService.streamBudget(currentMonthYear);
});

final financeAnalyticsProvider = Provider<FinanceAnalyticsResult>((ref) {
  final txsAsync = ref.watch(financeTransactionsProvider);
  final budgetAsync = ref.watch(financeBudgetStreamProvider);

  final transactions = txsAsync.asData?.value ?? [];
  final budget = budgetAsync.asData?.value ??
      FinanceBudgetModel(
        id: 'bud_current',
        farmId: 'all',
        monthYear: DateFormat('yyyy-MM').format(DateTime.now()),
        updatedAt: DateTime.now(),
      );

  return FinanceAnalyticsEngine.calculateAnalytics(
    transactions: transactions,
    budget: budget,
  );
});
