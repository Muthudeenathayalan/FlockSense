import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/finance/domain/finance_analytics_engine.dart';

void main() {
  group('Finance Module Tests', () {
    final now = DateTime.now();

    test('validates transaction amount and quantity', () {
      expect(FinanceTransactionModel.isValidAmount(100.0), isTrue);
      expect(FinanceTransactionModel.isValidAmount(0.0), isFalse);
      expect(FinanceTransactionModel.isValidAmount(-50.0), isFalse);

      expect(FinanceTransactionModel.isValidQuantity(5.0), isTrue);
      expect(FinanceTransactionModel.isValidQuantity(0.0), isFalse);

      expect(FinanceTransactionModel.isValidPaidAmount(500.0, 1000.0), isTrue);
      expect(FinanceTransactionModel.isValidPaidAmount(1000.0, 1000.0), isTrue);
      expect(FinanceTransactionModel.isValidPaidAmount(0.0, 1000.0), isTrue);
      expect(FinanceTransactionModel.isValidPaidAmount(-50.0, 1000.0), isFalse);
      expect(FinanceTransactionModel.isValidPaidAmount(1500.0, 1000.0), isFalse);
    });

    test('calculates pending amounts accurately and determines payment completion', () {
      final tx = FinanceTransactionModel(
        id: 'tx-1',
        farmId: 'f-1',
        batchId: 'b-1',
        ownerId: 'u-1',
        type: FinanceTransactionType.expense,
        category: 'Feed',
        date: now,
        customerOrSupplier: 'Feed Co',
        totalAmount: 10000.0,
        paidAmount: 7000.0,
        paymentStatus: PaymentStatus.partial,
        invoiceNumber: 'INV-101',
        createdAt: now,
        updatedAt: now,
      );

      expect(tx.pendingAmount, 3000.0);
      expect(tx.isFullyPaid, isFalse);
      expect(tx.isPartiallyPaid, isTrue);

      final fullyPaidTx = FinanceTransactionModel(
        id: 'tx-2',
        farmId: 'f-1',
        batchId: 'b-1',
        ownerId: 'u-1',
        type: FinanceTransactionType.income,
        category: 'Bird Sales',
        date: now,
        customerOrSupplier: 'Wholesaler',
        totalAmount: 50000.0,
        paidAmount: 50000.0,
        paymentStatus: PaymentStatus.paid,
        invoiceNumber: 'INV-102',
        createdAt: now,
        updatedAt: now,
      );

      expect(fullyPaidTx.pendingAmount, 0.0);
      expect(fullyPaidTx.isFullyPaid, isTrue);
      expect(fullyPaidTx.isPartiallyPaid, isFalse);
    });

    test('calculates today income, expenses and profit', () {
      final transactions = [
        FinanceTransactionModel(
          id: 'tx-1',
          farmId: 'f-1',
          batchId: 'b-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.income,
          category: 'Bird Sales',
          date: now,
          customerOrSupplier: 'Buyer A',
          totalAmount: 50000.0,
          paidAmount: 50000.0,
          invoiceNumber: 'INV-1',
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionModel(
          id: 'tx-2',
          farmId: 'f-1',
          batchId: 'b-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Feed',
          date: now,
          customerOrSupplier: 'Supplier B',
          totalAmount: 30000.0,
          paidAmount: 30000.0,
          invoiceNumber: 'INV-2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final budget = FinanceBudgetModel(
        id: 'bgt-1',
        farmId: 'f-1',
        monthYear: '2026-08',
        monthlyBudget: 100000,
        feedBudget: 60000,
        medicineBudget: 10000,
        updatedAt: now,
      );

      final result = FinanceAnalyticsEngine.calculateAnalytics(
        transactions: transactions,
        budget: budget,
        activeBirdCount: 2000,
      );

      expect(result.todayIncome, 50000.0);
      expect(result.todayExpense, 30000.0);
      expect(result.todayProfit, 20000.0); // 50000 - 30000
    });

    test('serializes FinanceBudgetModel to and from json', () {
      final budget = FinanceBudgetModel(
        id: 'bgt-1',
        farmId: 'f-1',
        monthYear: '2026-08',
        monthlyBudget: 120000,
        feedBudget: 80000,
        medicineBudget: 15000,
        updatedAt: now,
      );

      final json = budget.toJson();
      expect(json['id'], 'bgt-1');
      expect(json['monthlyBudget'], 120000.0);

      final copy = FinanceBudgetModel.fromJson(json);
      expect(copy.id, budget.id);
      expect(copy.monthlyBudget, 120000.0);
      expect(copy.feedBudget, 80000.0);
    });

    test('returns authentic zeros on empty transactions without synthetic fallbacks', () {
      final emptyBudget = FinanceBudgetModel(
        id: 'bgt-empty',
        farmId: 'f-1',
        monthYear: '2026-09',
        monthlyBudget: 0,
        feedBudget: 0,
        medicineBudget: 0,
        updatedAt: now,
      );

      final result = FinanceAnalyticsEngine.calculateAnalytics(
        transactions: [],
        budget: emptyBudget,
        activeBirdCount: 0,
      );

      expect(result.todayIncome, 0.0);
      expect(result.todayExpense, 0.0);
      expect(result.todayProfit, 0.0);
      expect(result.monthlyRevenue, 0.0);
      expect(result.monthlyExpenses, 0.0);
      expect(result.monthlyProfit, 0.0);
      expect(result.currentCashFlow, 0.0);
      expect(result.outstandingPayments, 0.0);
      expect(result.profitMarginPct, 0.0);
      expect(result.roiPct, 0.0);
      expect(result.costPerBird, 0.0);
      expect(result.revenuePerBird, 0.0);
      expect(result.feedCostPerBird, 0.0);
      expect(result.medicineCostPerBird, 0.0);
      expect(result.highestExpenseCategory, 'None');
      expect(result.highestExpenseAmount, 0.0);
      expect(result.mostProfitableBatch, 'No Data');
      expect(result.leastProfitableBatch, 'No Data');
      expect(result.highestFeedCostBatch, 'No Data');
      expect(result.highestMedCostBatch, 'No Data');
      expect(result.mostExpensiveFarm, 'No Data');
      expect(result.bestPerformingFarm, 'No Data');
      expect(result.isMonthlyBudgetExceeded, isFalse);
      expect(result.isFeedBudgetExceeded, isFalse);
      expect(result.isMedicineBudgetExceeded, isFalse);
    });

    test('computes dynamic batch and farm rankings correctly', () {
      final transactions = [
        FinanceTransactionModel(
          id: 'tx-1',
          farmId: 'farm-alpha',
          batchId: 'batch-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.income,
          category: 'Bird Sales',
          date: now,
          customerOrSupplier: 'Buyer 1',
          totalAmount: 120000.0,
          paidAmount: 120000.0,
          invoiceNumber: 'INV-1',
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionModel(
          id: 'tx-2',
          farmId: 'farm-alpha',
          batchId: 'batch-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Feed',
          date: now,
          customerOrSupplier: 'Feed Supplier',
          totalAmount: 40000.0,
          paidAmount: 40000.0,
          invoiceNumber: 'INV-2',
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionModel(
          id: 'tx-3',
          farmId: 'farm-beta',
          batchId: 'batch-2',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Feed',
          date: now,
          customerOrSupplier: 'Feed Supplier',
          totalAmount: 70000.0,
          paidAmount: 70000.0,
          invoiceNumber: 'INV-3',
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionModel(
          id: 'tx-4',
          farmId: 'farm-beta',
          batchId: 'batch-2',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Medicine',
          date: now,
          customerOrSupplier: 'Vet Clinic',
          totalAmount: 15000.0,
          paidAmount: 15000.0,
          invoiceNumber: 'INV-4',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final budget = FinanceBudgetModel(
        id: 'bgt-rank',
        farmId: 'farm-alpha',
        monthYear: '2026-09',
        monthlyBudget: 200000,
        feedBudget: 100000,
        medicineBudget: 20000,
        updatedAt: now,
      );

      final result = FinanceAnalyticsEngine.calculateAnalytics(
        transactions: transactions,
        budget: budget,
        activeBirdCount: 3000,
      );

      // batch-1 net profit: 120,000 - 40,000 = 80,000
      // batch-2 net profit: 0 - (70,000 + 15,000) = -85,000
      expect(result.mostProfitableBatch, 'batch-1');
      expect(result.leastProfitableBatch, 'batch-2');
      expect(result.highestFeedCostBatch, 'batch-2'); // 70,000 vs 40,000
      expect(result.highestMedCostBatch, 'batch-2');
      expect(result.bestPerformingFarm, 'farm-alpha'); // 80,000 vs -85,000
      expect(result.mostExpensiveFarm, 'farm-beta'); // 85,000 vs 40,000
    });

    test('evaluates budget threshold triggers accurately without false alarms', () {
      final budget = FinanceBudgetModel(
        id: 'bgt-alert',
        farmId: 'f-1',
        monthYear: '2026-09',
        monthlyBudget: 50000,
        feedBudget: 30000,
        medicineBudget: 0, // Unset medicine budget
        updatedAt: now,
      );

      final transactions = [
        FinanceTransactionModel(
          id: 'tx-feed',
          farmId: 'f-1',
          batchId: 'b-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Feed',
          date: now,
          customerOrSupplier: 'Feed Supplier',
          totalAmount: 35000.0, // Exceeds feed budget 30,000
          paidAmount: 35000.0,
          invoiceNumber: 'INV-F',
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionModel(
          id: 'tx-med',
          farmId: 'f-1',
          batchId: 'b-1',
          ownerId: 'u-1',
          type: FinanceTransactionType.expense,
          category: 'Medicine',
          date: now,
          customerOrSupplier: 'Vet',
          totalAmount: 5000.0,
          paidAmount: 5000.0,
          invoiceNumber: 'INV-M',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final result = FinanceAnalyticsEngine.calculateAnalytics(
        transactions: transactions,
        budget: budget,
        activeBirdCount: 1000,
      );

      // Monthly expenses = 40,000 <= 50,000 (not exceeded)
      expect(result.isMonthlyBudgetExceeded, isFalse);
      // Feed expenses = 35,000 > 30,000 (exceeded!)
      expect(result.isFeedBudgetExceeded, isTrue);
      // Medicine budget is 0 (unset), so no false alarm
      expect(result.isMedicineBudgetExceeded, isFalse);
    });
  });
}
