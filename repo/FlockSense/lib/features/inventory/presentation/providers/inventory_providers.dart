import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/domain/stock_movement_model.dart';

enum InventorySortOption { newest, oldest, quantity, expiryDate, alphabetical }

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

class InventorySearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final inventorySearchQueryProvider =
    NotifierProvider<InventorySearchNotifier, String>(InventorySearchNotifier.new);

class InventoryCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setCategory(String c) => state = c;
}

final inventoryCategoryFilterProvider =
    NotifierProvider<InventoryCategoryFilterNotifier, String>(InventoryCategoryFilterNotifier.new);

class InventorySortNotifier extends Notifier<InventorySortOption> {
  @override
  InventorySortOption build() => InventorySortOption.newest;
  void setSort(InventorySortOption s) => state = s;
}

final inventorySortProvider =
    NotifierProvider<InventorySortNotifier, InventorySortOption>(InventorySortNotifier.new);

final inventoryStreamProvider = StreamProvider.autoDispose<List<InventoryItemModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeFarmId = ref.watch(activeFarmIdProvider).value;
  final service = ref.watch(inventoryServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.watchInventoryItems(uid: user.uid, farmId: activeFarmId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final filteredInventoryListProvider = Provider.autoDispose<List<InventoryItemModel>>((ref) {
  final items = ref.watch(inventoryStreamProvider).value ?? [];
  final query = ref.watch(inventorySearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(inventoryCategoryFilterProvider);
  final sort = ref.watch(inventorySortProvider);

  var result = items.where((item) {
    final matchesSearch = query.isEmpty ||
        item.itemName.toLowerCase().contains(query) ||
        item.category.toLowerCase().contains(query) ||
        item.supplier.toLowerCase().contains(query) ||
        item.brand.toLowerCase().contains(query);

    if (!matchesSearch) return false;

    if (category == 'All') return true;
    if (category == 'Low Stock') return item.isLowStock;
    if (category == 'Expired') return item.isExpired;
    return item.category.toLowerCase() == category.toLowerCase();
  }).toList();

  switch (sort) {
    case InventorySortOption.newest:
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case InventorySortOption.oldest:
      result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case InventorySortOption.quantity:
      result.sort((a, b) => b.quantityAvailable.compareTo(a.quantityAvailable));
      break;
    case InventorySortOption.expiryDate:
      result.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
      break;
    case InventorySortOption.alphabetical:
      result.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));
      break;
  }

  return result;
});

class InventoryStats {
  final double totalFeedStockKg;
  final double totalMedicineStockUnits;
  final double totalVaccineStockDoses;
  final double totalEquipmentStockUnits;
  final int lowStockCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double totalInventoryValue;

  const InventoryStats({
    required this.totalFeedStockKg,
    required this.totalMedicineStockUnits,
    required this.totalVaccineStockDoses,
    required this.totalEquipmentStockUnits,
    required this.lowStockCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.totalInventoryValue,
  });

  static const empty = InventoryStats(
    totalFeedStockKg: 0,
    totalMedicineStockUnits: 0,
    totalVaccineStockDoses: 0,
    totalEquipmentStockUnits: 0,
    lowStockCount: 0,
    expiredCount: 0,
    expiringSoonCount: 0,
    totalInventoryValue: 0,
  );
}

final inventoryStatsProvider = Provider.autoDispose<InventoryStats>((ref) {
  final items = ref.watch(inventoryStreamProvider).value ?? [];

  double feedKg = 0;
  double medUnits = 0;
  double vacDoses = 0;
  double eqUnits = 0;
  int lowStock = 0;
  int expired = 0;
  int expiringSoon = 0;
  double totalValue = 0;

  for (final item in items) {
    totalValue += item.totalValue;
    if (item.isLowStock) lowStock++;
    if (item.isExpired) expired++;
    if (item.isExpiringIn30Days) expiringSoon++;

    final cat = item.category.toLowerCase();
    if (cat.contains('feed')) {
      feedKg += item.quantityAvailable;
    } else if (cat.contains('med')) {
      medUnits += item.quantityAvailable;
    } else if (cat.contains('vac')) {
      vacDoses += item.quantityAvailable;
    } else if (cat.contains('eq')) {
      eqUnits += item.quantityAvailable;
    }
  }

  return InventoryStats(
    totalFeedStockKg: feedKg,
    totalMedicineStockUnits: medUnits,
    totalVaccineStockDoses: vacDoses,
    totalEquipmentStockUnits: eqUnits,
    lowStockCount: lowStock,
    expiredCount: expired,
    expiringSoonCount: expiringSoon,
    totalInventoryValue: totalValue,
  );
});

final stockMovementsStreamProvider = StreamProvider.autoDispose
    .family<List<StockMovementModel>, ({String farmId, String itemId})>((ref, arg) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(inventoryServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return service.watchStockMovements(uid: user.uid, farmId: arg.farmId, itemId: arg.itemId);
    },
    loading: () => Stream.value([]),
    error: (err, stack) => Stream.value([]),
  );
});
