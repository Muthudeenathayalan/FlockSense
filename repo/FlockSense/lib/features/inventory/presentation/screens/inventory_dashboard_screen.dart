import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_item_detail_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_item_form_screen.dart';
import 'package:flock_sense/features/inventory/presentation/widgets/inventory_item_tile.dart';
import 'package:flock_sense/features/inventory/presentation/widgets/inventory_summary_cards.dart';
import 'package:flock_sense/features/inventory/presentation/widgets/stock_movement_dialog.dart';
import 'package:flock_sense/features/inventory/services/inventory_export_service.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final filteredItems = ref.watch(filteredInventoryListProvider);
    final stats = ref.watch(inventoryStatsProvider);

    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final selectedSort = ref.watch(inventorySortProvider);
    final searchQuery = ref.watch(inventorySearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Inventory Item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryItemFormScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onSelected: (val) {
              final rawItems = inventoryAsync.value ?? [];
              switch (val) {
                case 'pdf':
                  InventoryExportService.printOrPreviewPdf(
                    context: context,
                    items: filteredItems,
                    stats: stats,
                    title: 'Inventory Summary Report',
                  );
                  break;
                case 'csv':
                  _showCsvDialog(context, filteredItems);
                  break;
                case 'share':
                  InventoryExportService.shareReport(
                    context: context,
                    items: filteredItems,
                    stats: stats,
                    title: 'Inventory Data',
                  );
                  break;
                case 'lowStockPdf':
                  final lowStockItems = rawItems
                      .where((i) => i.isLowStock)
                      .toList();
                  InventoryExportService.printOrPreviewPdf(
                    context: context,
                    items: lowStockItems,
                    stats: stats,
                    title: 'Low Stock Alert Report',
                  );
                  break;
                case 'expiryPdf':
                  final expiryItems = rawItems
                      .where((i) => i.isExpired || i.isExpiringIn30Days)
                      .toList();
                  InventoryExportService.printOrPreviewPdf(
                    context: context,
                    items: expiryItems,
                    stats: stats,
                    title: 'Expiry Alert Report',
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Export Full PDF Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text('Export CSV Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('Share Report'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'lowStockPdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Low Stock Report'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'expiryPdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Expiry Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryItemFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error),
        data: (allRawItems) => Column(
          children: [
            // Top Summary KPIs Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: InventorySummaryCards(stats: stats),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Search Bar & Sort Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        ref.read(inventorySearchQueryProvider.notifier).state =
                            val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search items, suppliers, brand...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  ref
                                          .read(
                                            inventorySearchQueryProvider
                                                .notifier,
                                          )
                                          .state =
                                      '';
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Sort Menu Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InventorySortOption>(
                        value: selectedSort,
                        icon: const Icon(
                          Icons.sort_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: InventorySortOption.newest,
                            child: Text(
                              'Newest',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: InventorySortOption.oldest,
                            child: Text(
                              'Oldest',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: InventorySortOption.quantity,
                            child: Text(
                              'Quantity',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: InventorySortOption.expiryDate,
                            child: Text(
                              'Expiry',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: InventorySortOption.alphabetical,
                            child: Text('A-Z', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(inventorySortProvider.notifier).state =
                                val;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip(ref, 'All', selectedCategory == 'All'),
                    const SizedBox(width: 6),
                    _categoryChip(ref, 'Feed', selectedCategory == 'Feed'),
                    const SizedBox(width: 6),
                    _categoryChip(
                      ref,
                      'Medicine',
                      selectedCategory == 'Medicine',
                    ),
                    const SizedBox(width: 6),
                    _categoryChip(
                      ref,
                      'Vaccines',
                      selectedCategory == 'Vaccines',
                    ),
                    const SizedBox(width: 6),
                    _categoryChip(
                      ref,
                      'Equipment',
                      selectedCategory == 'Equipment',
                    ),
                    const SizedBox(width: 6),
                    _categoryChip(
                      ref,
                      'Low Stock',
                      selectedCategory == 'Low Stock',
                      badgeCount: stats.lowStockCount,
                      badgeColor: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    _categoryChip(
                      ref,
                      'Expired',
                      selectedCategory == 'Expired',
                      badgeCount: stats.expiredCount,
                      badgeColor: const Color(0xFFD32F2F),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Item List view
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(inventoryStreamProvider);
                },
                child: filteredItems.isEmpty
                    ? _buildEmptyState(context, allRawItems.isEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 14,
                          bottom: 80,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return InventoryItemTile(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InventoryItemDetailScreen(item: item),
                                ),
                              );
                            },
                            onIncreaseStock: () =>
                                _openStockModal(context, item, 'increase'),
                            onReduceStock: () =>
                                _openStockModal(context, item, 'reduce'),
                            onTransferStock: () =>
                                _openStockModal(context, item, 'transfer'),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(
    WidgetRef ref,
    String label,
    bool selected, {
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : (badgeColor ?? AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? (badgeColor ?? AppColors.primary)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) {
        ref.read(inventoryCategoryFilterProvider.notifier).state = label;
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _openStockModal(
    BuildContext context,
    InventoryItemModel item,
    String action,
  ) {
    showDialog(
      context: context,
      builder: (_) => StockMovementDialog(item: item, action: action),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isTotalEmpty ? 'No inventory items found.' : 'No matching items.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTotalEmpty
                  ? 'Add your feed, medicine, vaccine, or equipment stock to start tracking.'
                  : 'Try adjusting your search query or filter selection.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryItemFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Add First Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 54,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load inventory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('permission-denied')
                  ? 'Permission denied. Check Firestore security rules.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => ref.invalidate(inventoryStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCsvDialog(BuildContext context, List<InventoryItemModel> items) {
    final csv = InventoryExportService.generateInventoryCsvReport(items);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Export Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              InventoryExportService.shareReport(
                context: context,
                items: items,
                stats: InventoryStats.empty,
                title: 'Inventory Data',
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share CSV/PDF'),
          ),
        ],
      ),
    );
  }
}
