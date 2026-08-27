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
    });

    test('calculates pending amounts accurately', () {
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
  });
}
