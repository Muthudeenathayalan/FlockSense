import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/domain/stock_movement_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore;

  InventoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream real-time inventory items for a user
  Stream<List<InventoryItemModel>> watchInventoryItems({
    required String uid,
    String? farmId,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('inventoryItems')
        .where('ownerId', isEqualTo: uid);

    if (farmId != null && farmId.isNotEmpty) {
      query = _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('inventoryItems');
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => InventoryItemModel.fromJson(doc.data()))
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  /// Stream stock movement history for a specific item
  Stream<List<StockMovementModel>> watchStockMovements({
    required String uid,
    required String farmId,
    required String itemId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('inventoryItems')
        .doc(itemId)
        .collection('stockMovements')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockMovementModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Save new inventory item to Firestore and log initial movement
  Future<void> addInventoryItem(InventoryItemModel item) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(item.ownerId)
          .collection('farms')
          .doc(item.farmId)
          .collection('inventoryItems')
          .doc(item.id.isNotEmpty ? item.id : null);

      final newItem = item.copyWith(id: docRef.id);
      await docRef.set(newItem.toJson());

      // Log initial movement
      final initialMovement = StockMovementModel(
        id: _firestore.collection('tmp').doc().id,
        inventoryItemId: docRef.id,
        farmId: item.farmId,
        ownerId: item.ownerId,
        action: 'increase',
        quantity: item.quantityAvailable,
        reason: 'purchase',
        date: item.purchaseDate,
        supplier: item.supplier,
        userName: 'Initial Add',
        notes: 'Initial stock recorded upon creation.',
        createdAt: DateTime.now(),
      );

      await docRef
          .collection('stockMovements')
          .doc(initialMovement.id)
          .set(initialMovement.toJson());
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      rethrow;
    }
  }

  /// Update existing inventory item
  Future<void> updateInventoryItem(InventoryItemModel item) async {
    try {
      final updated = item.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('users')
          .doc(item.ownerId)
          .collection('farms')
          .doc(item.farmId)
          .collection('inventoryItems')
          .doc(item.id)
          .update(updated.toJson());
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  /// Delete inventory item
  Future<void> deleteInventoryItem({
    required String uid,
    required String farmId,
    required String itemId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('inventoryItems')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      rethrow;
    }
  }

  /// Record a stock movement (Increase, Reduce, Transfer) and update item quantity
  Future<void> recordStockMovement({
    required String uid,
    required String farmId,
    required StockMovementModel movement,
  }) async {
    final itemDocRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('inventoryItems')
        .doc(movement.inventoryItemId);

    final movementDocRef = itemDocRef
        .collection('stockMovements')
        .doc(movement.id.isNotEmpty ? movement.id : null);

    final updatedMovement = StockMovementModel(
      id: movementDocRef.id,
      inventoryItemId: movement.inventoryItemId,
      farmId: farmId,
      ownerId: uid,
      action: movement.action,
      quantity: movement.quantity,
      reason: movement.reason,
      date: movement.date,
      supplier: movement.supplier,
      invoiceNumber: movement.invoiceNumber,
      targetLocation: movement.targetLocation,
      userName: movement.userName,
      notes: movement.notes,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(itemDocRef);
      if (!snapshot.exists) {
        throw Exception('Inventory item does not exist.');
      }

      final item = InventoryItemModel.fromJson(snapshot.data()!);
      double newQty = item.quantityAvailable;

      if (movement.action == 'increase') {
        newQty += movement.quantity;
      } else if (movement.action == 'reduce' || movement.action == 'transfer') {
        newQty -= movement.quantity;
        if (newQty < 0) newQty = 0;
      }

      transaction.update(itemDocRef, {
        'quantityAvailable': newQty,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      transaction.set(movementDocRef, updatedMovement.toJson());
    });
  }

  /// Automatically deduct stock when a daily record / feed / medicine / vaccine record is created
  Future<void> autoDeductStock({
    required String uid,
    required String farmId,
    required String category, // 'Feed', 'Medicine', 'Vaccines'
    required String itemName,
    required double amountUsed,
    String? reason,
  }) async {
    if (amountUsed <= 0) return;

    try {
      final itemsQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('farms')
          .doc(farmId)
          .collection('inventoryItems')
          .where('category', isEqualTo: category)
          .get();

      final items = itemsQuery.docs
          .map((d) => InventoryItemModel.fromJson(d.data()))
          .toList();

      if (items.isEmpty) return;

      // Find matching item by name or fallback to first in category
      InventoryItemModel? targetItem;
      for (final item in items) {
        if (item.itemName.toLowerCase().contains(itemName.toLowerCase())) {
          targetItem = item;
          break;
        }
      }
      targetItem ??= items.first;

      final movement = StockMovementModel(
        id: '',
        inventoryItemId: targetItem.id,
        farmId: farmId,
        ownerId: uid,
        action: 'reduce',
        quantity: amountUsed,
        reason: reason ?? '${category} Used (Auto Deduction)',
        date: DateTime.now(),
        userName: 'Auto Logger',
        notes: 'Automatically deducted from daily telemetry log.',
        createdAt: DateTime.now(),
      );

      await recordStockMovement(uid: uid, farmId: farmId, movement: movement);
    } catch (e) {
      debugPrint('Auto deduct stock error: $e');
    }
  }
}
