import 'package:cloud_firestore/cloud_firestore.dart';

enum FinanceTransactionType { income, expense }

enum PaymentStatus { paid, pending, overdue, partial }

class FinanceTransactionModel {
  final String id;
  final String farmId;
  final String batchId;
  final String ownerId;
  final FinanceTransactionType type;
  final String
  category; // Income: Bird Sales, Egg Sales, etc. Expense: Feed, Medicine, etc.
  final DateTime date;
  final String customerOrSupplier;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod; // Cash, Bank Transfer, UPI, Cheque, Credit
  final PaymentStatus paymentStatus;
  final double paidAmount;
  final String invoiceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinanceTransactionModel({
    required this.id,
    required this.farmId,
    required this.batchId,
    required this.ownerId,
    required this.type,
    required this.category,
    required this.date,
    required this.customerOrSupplier,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    required this.totalAmount,
    this.paymentMethod = 'Cash',
    this.paymentStatus = PaymentStatus.paid,
    this.paidAmount = 0.0,
    required this.invoiceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get pendingAmount => totalAmount - paidAmount;

  /// Validates transaction amount (must be positive).
  static bool isValidAmount(double amount) => amount > 0;

  /// Validates item quantity (must be positive).
  static bool isValidQuantity(double quantity) => quantity > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'batchId': batchId,
      'ownerId': ownerId,
      'type': type.name,
      'category': category,
      'date': Timestamp.fromDate(date),
      'customerOrSupplier': customerOrSupplier,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.name,
      'paidAmount': paidAmount,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FinanceTransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return FinanceTransactionModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      type: FinanceTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FinanceTransactionType.expense,
      ),
      category: json['category'] as String? ?? 'Other',
      date: parseDate(json['date']),
      customerOrSupplier: json['customerOrSupplier'] as String? ?? 'General',
      quantity: parseDouble(json['quantity']),
      unitPrice: parseDouble(json['unitPrice']),
      totalAmount: parseDouble(json['totalAmount']),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.paid,
      ),
      paidAmount: parseDouble(json['paidAmount']),
      invoiceNumber: json['invoiceNumber'] as String? ?? 'INV-000',
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
