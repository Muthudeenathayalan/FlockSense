import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';

class FinanceAnalyticsResult {
  final double todayIncome;
  final double todayExpense;
  final double todayProfit;

  final double monthlyRevenue;
  final double monthlyExpenses;
  final double monthlyProfit;

  final double currentCashFlow;
  final double outstandingPayments;
  final double profitMarginPct;
  final double roiPct;

  // Unit Economics
  final double costPerBird;
  final double revenuePerBird;
  final double feedCostPerBird;
  final double medicineCostPerBird;

  // Business Insights
  final String highestExpenseCategory;
  final double highestExpenseAmount;
  final String mostProfitableBatch;
  final String leastProfitableBatch;
  final String highestFeedCostBatch;
  final String highestMedCostBatch;
  final String mostExpensiveFarm;
  final String bestPerformingFarm;

  // Predictions
  final double expectedHarvestRevenue;
  final double expectedProfit;
  final double expectedFeedCost;
  final double expectedMedicineCost;
  final double expectedMonthlyIncome;

  // Budget Warnings
  final bool isMonthlyBudgetExceeded;
  final double monthlyBudgetPct;
  final bool isFeedBudgetExceeded;
  final double feedBudgetPct;
  final bool isMedicineBudgetExceeded;
  final double medicineBudgetPct;

  const FinanceAnalyticsResult({
    required this.todayIncome,
    required this.todayExpense,
    required this.todayProfit,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.monthlyProfit,
    required this.currentCashFlow,
    required this.outstandingPayments,
    required this.profitMarginPct,
    required this.roiPct,
    required this.costPerBird,
    required this.revenuePerBird,
    required this.feedCostPerBird,
    required this.medicineCostPerBird,
    required this.highestExpenseCategory,
    required this.highestExpenseAmount,
    required this.mostProfitableBatch,
    required this.leastProfitableBatch,
    required this.highestFeedCostBatch,
    required this.highestMedCostBatch,
    required this.mostExpensiveFarm,
    required this.bestPerformingFarm,
    required this.expectedHarvestRevenue,
    required this.expectedProfit,
    required this.expectedFeedCost,
    required this.expectedMedicineCost,
    required this.expectedMonthlyIncome,
    required this.isMonthlyBudgetExceeded,
    required this.monthlyBudgetPct,
    required this.isFeedBudgetExceeded,
    required this.feedBudgetPct,
    required this.isMedicineBudgetExceeded,
    required this.medicineBudgetPct,
  });
}

class FinanceAnalyticsEngine {
  FinanceAnalyticsEngine._();

  static FinanceAnalyticsResult calculateAnalytics({
    required List<FinanceTransactionModel> transactions,
    required FinanceBudgetModel budget,
    int activeBirdCount = 0,
    Map<String, String>? batchNames,
    Map<String, String>? farmNames,
  }) {
    final now = DateTime.now();

    final todayTxs = transactions
        .where(
          (t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .toList();

    final todayIncome = todayTxs
        .where((t) => t.type == FinanceTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final todayExpense = todayTxs
        .where((t) => t.type == FinanceTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final todayProfit = todayIncome - todayExpense;

    final monthlyTxs = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final monthlyRevenue = monthlyTxs
        .where((t) => t.type == FinanceTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final monthlyExpenses = monthlyTxs
        .where((t) => t.type == FinanceTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final monthlyProfit = monthlyRevenue - monthlyExpenses;

    final totalRevenueAllTime = transactions
        .where((t) => t.type == FinanceTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final totalExpenseAllTime = transactions
        .where((t) => t.type == FinanceTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);

    final currentCashFlow = totalRevenueAllTime - totalExpenseAllTime;
    final outstandingPayments = transactions
        .where(
          (t) =>
              t.paymentStatus == PaymentStatus.pending ||
              t.paymentStatus == PaymentStatus.overdue ||
              t.paymentStatus == PaymentStatus.partial,
        )
        .fold(0.0, (sum, t) => sum + t.pendingAmount);

    final profitMarginPct = monthlyRevenue > 0
        ? (monthlyProfit / monthlyRevenue) * 100.0
        : (totalRevenueAllTime > 0
              ? ((totalRevenueAllTime - totalExpenseAllTime) /
                        totalRevenueAllTime) *
                    100.0
              : 0.0);

    final roiPct = totalExpenseAllTime > 0
        ? ((totalRevenueAllTime - totalExpenseAllTime) / totalExpenseAllTime) *
              100.0
        : 0.0;

    // Unit Economics
    final costPerBird = (activeBirdCount > 0 && monthlyExpenses > 0)
        ? (monthlyExpenses / activeBirdCount)
        : (activeBirdCount > 0 && totalExpenseAllTime > 0
              ? (totalExpenseAllTime / activeBirdCount)
              : 0.0);
    final revenuePerBird = (activeBirdCount > 0 && monthlyRevenue > 0)
        ? (monthlyRevenue / activeBirdCount)
        : (activeBirdCount > 0 && totalRevenueAllTime > 0
              ? (totalRevenueAllTime / activeBirdCount)
              : 0.0);

    final feedExpenses = monthlyTxs
        .where(
          (t) =>
              t.type == FinanceTransactionType.expense &&
              t.category.toLowerCase().contains('feed'),
        )
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final feedCostPerBird = (activeBirdCount > 0 && feedExpenses > 0)
        ? (feedExpenses / activeBirdCount)
        : 0.0;

    final medExpenses = monthlyTxs
        .where(
          (t) =>
              t.type == FinanceTransactionType.expense &&
              (t.category.toLowerCase().contains('med') ||
                  t.category.toLowerCase().contains('vaccin')),
        )
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final medicineCostPerBird = (activeBirdCount > 0 && medExpenses > 0)
        ? (medExpenses / activeBirdCount)
        : 0.0;

    // Business Insights (Highest Expense Category)
    final categoryTotals = <String, double>{};
    for (final t in transactions.where(
      (t) => t.type == FinanceTransactionType.expense,
    )) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0.0) + t.totalAmount;
    }

    var highestCat = 'None';
    var highestAmt = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > highestAmt) {
        highestAmt = amt;
        highestCat = cat;
      }
    });

    // Dynamic Batch & Farm Performance Analysis
    final batchProfits = <String, double>{};
    final batchFeedCosts = <String, double>{};
    final batchMedCosts = <String, double>{};
    final farmProfits = <String, double>{};
    final farmExpenses = <String, double>{};

    for (final t in transactions) {
      final sign = t.type == FinanceTransactionType.income ? 1.0 : -1.0;
      if (t.batchId.isNotEmpty) {
        batchProfits[t.batchId] =
            (batchProfits[t.batchId] ?? 0.0) + (t.totalAmount * sign);
        if (t.type == FinanceTransactionType.expense) {
          final cat = t.category.toLowerCase();
          if (cat.contains('feed')) {
            batchFeedCosts[t.batchId] =
                (batchFeedCosts[t.batchId] ?? 0.0) + t.totalAmount;
          } else if (cat.contains('med') || cat.contains('vaccin')) {
            batchMedCosts[t.batchId] =
                (batchMedCosts[t.batchId] ?? 0.0) + t.totalAmount;
          }
        }
      }
      if (t.farmId.isNotEmpty) {
        farmProfits[t.farmId] =
            (farmProfits[t.farmId] ?? 0.0) + (t.totalAmount * sign);
        if (t.type == FinanceTransactionType.expense) {
          farmExpenses[t.farmId] =
              (farmExpenses[t.farmId] ?? 0.0) + t.totalAmount;
        }
      }
    }

    String getTopKey(
      Map<String, double> map, {
      bool highest = true,
      Map<String, String>? nameMap,
    }) {
      if (map.isEmpty) return 'No Data';
      var bestKey = map.keys.first;
      var bestVal = map.values.first;
      map.forEach((k, v) {
        if (highest ? v > bestVal : v < bestVal) {
          bestVal = v;
          bestKey = k;
        }
      });
      if (nameMap != null && nameMap.containsKey(bestKey)) {
        return nameMap[bestKey]!;
      }
      return bestKey;
    }

    final mostProfitableBatch = getTopKey(
      batchProfits,
      highest: true,
      nameMap: batchNames,
    );
    final leastProfitableBatch = getTopKey(
      batchProfits,
      highest: false,
      nameMap: batchNames,
    );
    final highestFeedCostBatch = getTopKey(
      batchFeedCosts,
      highest: true,
      nameMap: batchNames,
    );
    final highestMedCostBatch = getTopKey(
      batchMedCosts,
      highest: true,
      nameMap: batchNames,
    );
    final mostExpensiveFarm = getTopKey(
      farmExpenses,
      highest: true,
      nameMap: farmNames,
    );
    final bestPerformingFarm = getTopKey(
      farmProfits,
      highest: true,
      nameMap: farmNames,
    );

    // Predictions
    final expectedHarvestRevenue = (revenuePerBird > 0 && activeBirdCount > 0)
        ? (revenuePerBird * activeBirdCount * 1.05)
        : 0.0;
    final expectedProfit =
        (revenuePerBird > 0 && costPerBird > 0 && activeBirdCount > 0)
            ? (revenuePerBird * activeBirdCount * 1.05) -
                (costPerBird * activeBirdCount)
            : 0.0;
    final expectedFeedCost = (feedCostPerBird > 0 && activeBirdCount > 0)
        ? (feedCostPerBird * activeBirdCount * 1.02)
        : 0.0;
    final expectedMedicineCost =
        (medicineCostPerBird > 0 && activeBirdCount > 0)
            ? (medicineCostPerBird * activeBirdCount)
            : 0.0;
    final expectedMonthlyIncome = monthlyRevenue > 0
        ? monthlyRevenue * 1.05
        : 0.0;

    // Budget Warnings
    final monthlyBudgetPct = budget.monthlyBudget > 0
        ? (monthlyExpenses / budget.monthlyBudget) * 100.0
        : 0.0;
    final feedBudgetPct = budget.feedBudget > 0
        ? (feedExpenses / budget.feedBudget) * 100.0
        : 0.0;
    final medicineBudgetPct = budget.medicineBudget > 0
        ? (medExpenses / budget.medicineBudget) * 100.0
        : 0.0;

    final isMonthlyBudgetExceeded =
        budget.monthlyBudget > 0 && monthlyExpenses > budget.monthlyBudget;
    final isFeedBudgetExceeded =
        budget.feedBudget > 0 && feedExpenses > budget.feedBudget;
    final isMedicineBudgetExceeded =
        budget.medicineBudget > 0 && medExpenses > budget.medicineBudget;

    return FinanceAnalyticsResult(
      todayIncome: todayIncome,
      todayExpense: todayExpense,
      todayProfit: todayProfit,
      monthlyRevenue: monthlyRevenue,
      monthlyExpenses: monthlyExpenses,
      monthlyProfit: monthlyProfit,
      currentCashFlow: currentCashFlow,
      outstandingPayments: outstandingPayments,
      profitMarginPct: profitMarginPct,
      roiPct: roiPct,
      costPerBird: costPerBird,
      revenuePerBird: revenuePerBird,
      feedCostPerBird: feedCostPerBird,
      medicineCostPerBird: medicineCostPerBird,
      highestExpenseCategory: highestCat,
      highestExpenseAmount: highestAmt,
      mostProfitableBatch: mostProfitableBatch,
      leastProfitableBatch: leastProfitableBatch,
      highestFeedCostBatch: highestFeedCostBatch,
      highestMedCostBatch: highestMedCostBatch,
      mostExpensiveFarm: mostExpensiveFarm,
      bestPerformingFarm: bestPerformingFarm,
      expectedHarvestRevenue: expectedHarvestRevenue,
      expectedProfit: expectedProfit,
      expectedFeedCost: expectedFeedCost,
      expectedMedicineCost: expectedMedicineCost,
      expectedMonthlyIncome: expectedMonthlyIncome,
      isMonthlyBudgetExceeded: isMonthlyBudgetExceeded,
      monthlyBudgetPct: monthlyBudgetPct,
      isFeedBudgetExceeded: isFeedBudgetExceeded,
      feedBudgetPct: feedBudgetPct,
      isMedicineBudgetExceeded: isMedicineBudgetExceeded,
      medicineBudgetPct: medicineBudgetPct,
    );
  }
}
