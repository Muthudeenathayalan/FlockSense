import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/domain/stock_movement_model.dart';

void main() {
  group('Inventory Module Tests', () {
    final now = DateTime.now();
    final pastDate = now.subtract(const Duration(days: 30));
    final soonDate = now.add(const Duration(days: 5));

    test('validates item quantity and price', () {
      expect(InventoryItemModel.isValidQuantity(50.0), isTrue);
      expect(InventoryItemModel.isValidQuantity(0.0), isTrue);
      expect(InventoryItemModel.isValidQuantity(-10.0), isFalse);

      expect(InventoryItemModel.isValidPrice(120.0), isTrue);
      expect(InventoryItemModel.isValidPrice(-5.0), isFalse);
    });

    test('calculates stock balance transitions properly', () {
      expect(
        InventoryItemModel.calculateNewBalance(
          currentStock: 100.0,
          quantity: 25.0,
          type: 'in',
        ),
        125.0,
      );

      expect(
        InventoryItemModel.calculateNewBalance(
          currentStock: 100.0,
          quantity: 40.0,
          type: 'out',
        ),
        60.0,
      );

      // Clamps to 0 on overdraft
      expect(
        InventoryItemModel.calculateNewBalance(
          currentStock: 20.0,
          quantity: 50.0,
          type: 'out',
        ),
        0.0,
      );
    });

    test('correctly evaluates low stock, expiry, and total value', () {
      final item = InventoryItemModel(
        id: 'inv-1',
        farmId: 'f-1',
        ownerId: 'u-1',
        itemName: 'Broiler Starter Feed',
        category: 'Feed',
        brand: 'SKM',
        supplier: 'SKM Feeds',
        quantityAvailable: 15.0,
        unit: 'Bags',
        minStockLevel: 20.0,
        purchaseDate: pastDate,
        expiryDate: soonDate,
        purchasePrice: 1850.0,
        storageLocation: 'Shed 1 Store',
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      expect(item.isLowStock, isTrue);
      expect(item.isExpired, isFalse);
      expect(item.isExpiringIn7Days, isTrue);
      expect(item.isExpiringIn30Days, isTrue);
      expect(item.totalValue, 15.0 * 1850.0); // 27,750.0
    });

    test('serializes StockMovementModel round trip', () {
      final movement = StockMovementModel(
        id: 'mov-1',
        inventoryItemId: 'inv-1',
        farmId: 'f-1',
        ownerId: 'u-1',
        action: 'reduce',
        quantity: 5.0,
        reason: 'feedUsed',
        date: now,
        userName: 'Supervisor',
        createdAt: now,
      );

      final json = movement.toJson();
      expect(json['id'], 'mov-1');
      expect(json['action'], 'reduce');
      expect(json['quantity'], 5.0);
      expect(json['reason'], 'feedUsed');

      final copy = StockMovementModel.fromJson(json);
      expect(copy.id, movement.id);
      expect(copy.action, 'reduce');
      expect(copy.quantity, 5.0);
      expect(copy.reason, 'feedUsed');
    });
  });
}
