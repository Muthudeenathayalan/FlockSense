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
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';

class FinanceService {
  FinanceService._();

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static Stream<List<FinanceTransactionModel>> streamTransactions() {
    final user = _auth?.currentUser;
    if (user == null) {
      return Stream.value(<FinanceTransactionModel>[]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('finance_transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
          final seen = <String>{};
          final list = <FinanceTransactionModel>[];
          for (final doc in snap.docs) {
            final tx = FinanceTransactionModel.fromJson(doc.data());
            if (seen.add(tx.id)) {
              list.add(tx);
            }
          }
          return list;
        })
        .handleError((err) {
          debugPrint('[FinanceService] Stream transactions error: $err');
          return <FinanceTransactionModel>[];
        });
  }

  static Future<List<FinanceTransactionModel>> getCombinedTransactions({
    String? farmId,
    String? batchId,
  }) async {
    final user = _auth?.currentUser;
    final list = <FinanceTransactionModel>[];
    final seenIds = <String>{};

    if (user != null) {
      try {
        Query<Map<String, dynamic>> query = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('finance_transactions');

        if (farmId != null && farmId.isNotEmpty && farmId != 'all') {
          query = query.where('farmId', isEqualTo: farmId);
        }
        if (batchId != null && batchId.isNotEmpty && batchId != 'all') {
          query = query.where('batchId', isEqualTo: batchId);
        }

        final snap = await query.get();

        for (final doc in snap.docs) {
          final tx = FinanceTransactionModel.fromJson(doc.data());
          if (seenIds.add(tx.id)) {
            list.add(tx);
          }
        }
      } catch (e) {
        debugPrint('[FinanceService] Fetch Firestore transactions failed: $e');
      }

      // Automatically integrate Bird Sales, Feed Purchases, Medicine, Vaccines, Inventory, and Daily Record Costs
      try {
        final allFarms = await FarmService.getUserFarms();
        final farms = (farmId != null && farmId.isNotEmpty && farmId != 'all')
            ? allFarms.where((f) => f.id == farmId).toList()
            : allFarms;

        for (final farm in farms) {
          final allBatches = await BatchService.getBatchesForFarm(farm.id);
          final batches = (batchId != null && batchId.isNotEmpty && batchId != 'all')
              ? allBatches.where((b) => b.id == batchId).toList()
              : allBatches;

          for (final batch in batches) {
            // 1. Bird Sales -> Income
            try {
              final sales = await SalesService.getBirdSales(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final s in sales) {
                final txId = 'sale_${s.id}';
                if (seenIds.add(txId)) {
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
                  if (seenIds.add(txId)) {
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
                if (seenIds.add(txId)) {
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

            // 4. Vaccine Records -> Expense
            try {
              final vaccines = await VaccineService.getVaccineRecords(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final v in vaccines) {
                final txId = 'vac_${v.id}';
                if (seenIds.add(txId)) {
                  final nominalCost = v.quantity * 2.5; // Average cost per dose in INR
                  list.add(
                    FinanceTransactionModel(
                      id: txId,
                      farmId: v.farmId,
                      batchId: v.batchId,
                      ownerId: v.ownerId,
                      type: FinanceTransactionType.expense,
                      category: 'Vaccine',
                      date: v.date,
                      customerOrSupplier: v.doneBy?.isNotEmpty == true ? v.doneBy! : 'Veterinary Services',
                      quantity: v.quantity,
                      unitPrice: 2.5,
                      totalAmount: nominalCost,
                      paymentMethod: 'Cash',
                      paymentStatus: PaymentStatus.paid,
                      paidAmount: nominalCost,
                      invoiceNumber: 'INV-VAC-${v.id.length > 5 ? v.id.substring(0, 5) : v.id}',
                      notes: '${v.vaccineName} (${v.route} at Day ${v.batchAgeDay})',
                      createdAt: v.createdAt,
                      updatedAt: v.updatedAt,
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('[FinanceService] Vaccine integration error: $e');
            }

            // 5. Daily Records with direct Feed or Medicine Costs -> Expense
            try {
              final dailyRecords = await DailyRecordService.getAllDailyRecords(
                farmId: farm.id,
                batchId: batch.id,
              );
              for (final dr in dailyRecords) {
                // Check if feed cost logged in daily telemetry
                if (dr.feedCost != null && dr.feedCost! > 0) {
                  final txId = 'dr_feed_${dr.id}';
                  if (seenIds.add(txId)) {
                    list.add(
                      FinanceTransactionModel(
                        id: txId,
                        farmId: dr.farmId,
                        batchId: dr.batchId,
                        ownerId: dr.ownerId,
                        type: FinanceTransactionType.expense,
                        category: 'Feed',
                        date: dr.recordDate,
                        customerOrSupplier: dr.feedSupplier?.trim().isNotEmpty == true
                            ? dr.feedSupplier!.trim()
                            : 'Feed Store',
                        quantity: dr.feedConsumedKg > 0 ? dr.feedConsumedKg : 1.0,
                        unitPrice: dr.feedConsumedKg > 0 ? dr.feedCost! / dr.feedConsumedKg : dr.feedCost!,
                        totalAmount: dr.feedCost!,
                        paymentMethod: 'Cash',
                        paymentStatus: PaymentStatus.paid,
                        paidAmount: dr.feedCost!,
                        invoiceNumber: 'INV-DRF-${dr.id.length > 5 ? dr.id.substring(0, 5) : dr.id}',
                        notes: 'Feed logged on Day ${dr.batchAgeDay}',
                        createdAt: dr.createdAt,
                        updatedAt: dr.updatedAt,
                      ),
                    );
                  }
                }
                // Check if medicine cost logged in daily telemetry
                if (dr.medicineCost != null && dr.medicineCost! > 0) {
                  final txId = 'dr_med_${dr.id}';
                  if (seenIds.add(txId)) {
                    list.add(
                      FinanceTransactionModel(
                        id: txId,
                        farmId: dr.farmId,
                        batchId: dr.batchId,
                        ownerId: dr.ownerId,
                        type: FinanceTransactionType.expense,
                        category: 'Medicine',
                        date: dr.recordDate,
                        customerOrSupplier: 'Vet Pharmacy',
                        quantity: 1.0,
                        unitPrice: dr.medicineCost!,
                        totalAmount: dr.medicineCost!,
                        paymentMethod: 'Cash',
                        paymentStatus: PaymentStatus.paid,
                        paidAmount: dr.medicineCost!,
                        invoiceNumber: 'INV-DRM-${dr.id.length > 5 ? dr.id.substring(0, 5) : dr.id}',
                        notes: 'Medicine on Day ${dr.batchAgeDay}: ${dr.medicineName ?? ""}',
                        createdAt: dr.createdAt,
                        updatedAt: dr.updatedAt,
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('[FinanceService] Daily records financial integration error: $e');
            }
          }

          // 6. Direct Inventory Items Purchases -> Expense
          try {
            final invService = InventoryService();
            final items = await invService.watchInventoryItems(uid: user.uid, farmId: farm.id).first.timeout(
              const Duration(seconds: 2),
              onTimeout: () => [],
            );
            for (final item in items) {
              if (item.purchasePrice > 0 && item.quantityAvailable > 0) {
                final txId = 'inv_${item.id}';
                if (seenIds.add(txId)) {
                  list.add(
                    FinanceTransactionModel(
                      id: txId,
                      farmId: item.farmId,
                      batchId: batchId ?? 'all',
                      ownerId: item.ownerId,
                      type: FinanceTransactionType.expense,
                      category: item.category.isNotEmpty ? item.category : 'Inventory',
                      date: item.purchaseDate,
                      customerOrSupplier: item.supplier.isNotEmpty ? item.supplier : 'Farm Supplies Store',
                      quantity: item.quantityAvailable,
                      unitPrice: item.purchasePrice,
                      totalAmount: item.totalValue,
                      paymentMethod: 'Cash',
                      paymentStatus: PaymentStatus.paid,
                      paidAmount: item.totalValue,
                      invoiceNumber: 'INV-STK-${item.id.length > 5 ? item.id.substring(0, 5) : item.id}',
                      notes: '${item.itemName} (${item.quantityAvailable} ${item.unit} at storage: ${item.storageLocation})',
                      createdAt: item.createdAt,
                      updatedAt: item.updatedAt,
                    ),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('[FinanceService] Inventory purchases financial integration error: $e');
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
    final user = _auth?.currentUser;

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
    final user = _auth?.currentUser;

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
    final user = _auth?.currentUser;
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
    final user = _auth?.currentUser;
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
