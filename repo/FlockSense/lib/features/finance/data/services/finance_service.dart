import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/finance/data/models/finance_budget_model.dart';
import 'package:flock_sense/features/finance/data/models/finance_transaction_model.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';

class FinanceService {
  FinanceService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static final List<FinanceTransactionModel> _localTransactions = [];

  static Stream<List<FinanceTransactionModel>> streamTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(List.unmodifiable(_localTransactions));
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('finance_transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => FinanceTransactionModel.fromJson(doc.data()))
              .toList(),
        )
        .handleError((err) {
          debugPrint('[FinanceService] Stream transactions error: $err');
          return List.unmodifiable(_localTransactions);
        });
  }

  static Future<List<FinanceTransactionModel>> getCombinedTransactions() async {
    final user = _auth.currentUser;
    final list = <FinanceTransactionModel>[..._localTransactions];

    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('finance_transactions')
            .get();

        for (final doc in snap.docs) {
          final tx = FinanceTransactionModel.fromJson(doc.data());
          if (!list.any((t) => t.id == tx.id)) {
            list.add(tx);
          }
        }
      } catch (e) {
        debugPrint('[FinanceService] Fetch Firestore transactions failed: $e');
      }

      // Automatically integrate Bird Sales, Feed Purchases, and Medicine into Finance Transactions
      try {
        final farms = await FarmService.getUserFarms();
        for (final farm in farms) {
          final batches = await BatchService.getBatchesForFarm(farm.id);
          for (final batch in batches) {
            // 1. Bird Sales -> Income
            try {
              final sales = await SalesService.getBirdSales(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final s in sales) {
                final txId = 'sale_${s.id}';
                if (!list.any((t) => t.id == txId)) {
                  list.add(
                    FinanceTransactionModel(
                      id: txId,
                      farmId: s.farmId,
                      batchId: s.batchId,
                      ownerId: s.ownerId,
                      type: FinanceTransactionType.income,
                      category: 'Bird Sales',
                      date: s.date,
                      customerOrSupplier: s.customerName.trim().isNotEmpty
                          ? s.customerName.trim()
                          : 'Trader / Buyer',
                      quantity: s.birdsSold.toDouble(),
                      unitPrice: s.pricePerBird,
                      totalAmount: s.totalValue,
                      paymentMethod: 'Cash',
                      paymentStatus: PaymentStatus.paid,
                      paidAmount: s.totalValue,
                      invoiceNumber:
                          'INV-SALE-${s.id.length > 5 ? s.id.substring(0, 5) : s.id}',
                      notes:
                          'Sold ${s.birdsSold} birds (${s.averageWeightKg} kg avg weight)',
                      createdAt: s.createdAt,
                      updatedAt: s.updatedAt,
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('[FinanceService] Sales integration error: $e');
            }

            // 2. Feed Purchases -> Expense
            try {
              final feeds = await FeedService.getFeedTransactions(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final f in feeds) {
                if (f.totalCost > 0 ||
                    f.transactionType.toLowerCase().contains('purchase')) {
                  final txId = 'feed_${f.id}';
                  if (!list.any((t) => t.id == txId)) {
                    list.add(
                      FinanceTransactionModel(
                        id: txId,
                        farmId: f.farmId,
                        batchId: f.batchId,
                        ownerId: f.ownerId,
                        type: FinanceTransactionType.expense,
                        category: 'Feed',
                        date: f.transactionDate,
                        customerOrSupplier:
                            f.supplierOrSource?.trim().isNotEmpty == true
                                ? f.supplierOrSource!.trim()
                                : 'Feed Supplier',
                        quantity: f.totalKg,
                        unitPrice: f.costPerKg > 0
                            ? f.costPerKg
                            : (f.totalKg > 0 ? f.totalCost / f.totalKg : 0.0),
                        totalAmount: f.totalCost,
                        paymentMethod: 'Cash',
                        paymentStatus: PaymentStatus.paid,
                        paidAmount: f.totalCost,
                        invoiceNumber:
                            'INV-FEED-${f.id.length > 5 ? f.id.substring(0, 5) : f.id}',
                        notes:
                            '${f.feedType} (${f.bags} bags, ${f.totalKg.toStringAsFixed(0)} kg)',
                        createdAt: f.createdAt,
                        updatedAt: f.updatedAt,
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('[FinanceService] Feed integration error: $e');
            }

            // 3. Medicine Records -> Expense
            try {
              final meds = await MedicineService.getMedicineRecords(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final m in meds) {
                final txId = 'med_${m.id}';
                if (!list.any((t) => t.id == txId)) {
                  final cost = m.valueRs ?? 0.0;
                  list.add(
                    FinanceTransactionModel(
                      id: txId,
                      farmId: m.farmId,
                      batchId: m.batchId,
                      ownerId: m.ownerId,
                      type: FinanceTransactionType.expense,
                      category: 'Medicine',
                      date: m.date,
                      customerOrSupplier: 'Vet Pharmacy',
                      quantity: m.quantity,
                      unitPrice: cost / (m.quantity > 0 ? m.quantity : 1.0),
                      totalAmount: cost,
                      paymentMethod: 'Cash',
                      paymentStatus: PaymentStatus.paid,
                      paidAmount: cost,
                      invoiceNumber:
                          'INV-MED-${m.id.length > 5 ? m.id.substring(0, 5) : m.id}',
                      notes:
                          '${m.medicineName} (${m.notes ?? "Routine treatment"})',
                      createdAt: m.createdAt,
                      updatedAt: m.updatedAt,
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('[FinanceService] Medicine integration error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[FinanceService] Farm batch integration error: $e');
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<FinanceTransactionModel> createTransaction(
    FinanceTransactionModel transaction,
  ) async {
    final user = _auth.currentUser;
    _localTransactions.insert(0, transaction);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('finance_transactions')
            .doc(transaction.id)
            .set(transaction.toJson());
      } catch (e) {
        debugPrint('[FinanceService] Create transaction failed: $e');
      }
    }

    return transaction;
  }

  static Future<void> deleteTransaction(String transactionId) async {
    final user = _auth.currentUser;
    _localTransactions.removeWhere((t) => t.id == transactionId);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('finance_transactions')
            .doc(transactionId)
            .delete();
      } catch (e) {
        debugPrint('[FinanceService] Delete transaction failed: $e');
      }
    }
  }

  // --- Budget Management ---
  static Stream<FinanceBudgetModel> streamBudget(String monthYear) {
    final user = _auth.currentUser;
    final fallback = FinanceBudgetModel(
      id: 'bud_$monthYear',
      farmId: 'all',
      monthYear: monthYear,
      updatedAt: DateTime.now(),
    );

    if (user == null) return Stream.value(fallback);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('finance_budgets')
        .doc(monthYear)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? FinanceBudgetModel.fromJson(doc.data()!) : fallback,
        )
        .handleError((err) => fallback);
  }

  static Future<void> setBudget(FinanceBudgetModel budget) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('finance_budgets')
            .doc(budget.monthYear)
            .set(budget.toJson());
      } catch (e) {
        debugPrint('[FinanceService] Set budget failed: $e');
      }
    }
  }
}
