import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';

class InventoryItemTile extends StatelessWidget {
  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onIncreaseStock,
    required this.onReduceStock,
    required this.onTransferStock,
  });

  final InventoryItemModel item;
  final VoidCallback onTap;
  final VoidCallback onIncreaseStock;
  final VoidCallback onReduceStock;
  final VoidCallback onTransferStock;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final ratio = item.minStockLevel > 0
        ? (item.quantityAvailable / (item.minStockLevel * 2)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowStock || item.isExpired
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.border,
          width: item.isLowStock || item.isExpired ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Chip + Badges + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor(item.category).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _categoryColor(item.category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (item.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'LOW STOCK',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                  if (item.isExpired) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ] else if (item.isExpiringIn30Days) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EXPIRING SOON',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],

                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 10),

              // Item Title & Supplier
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.brand.isNotEmpty ? "${item.brand} • " : ""}${item.supplier.isNotEmpty ? item.supplier : "Store"} • ${item.storageLocation}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Quantity & Min Stock Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity Available', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(
                        '${item.quantityAvailable.toStringAsFixed(item.quantityAvailable % 1 == 0 ? 0 : 1)} ${item.unit}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: item.isLowStock ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Min Stock Level', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(
                        '${item.minStockLevel.toStringAsFixed(item.minStockLevel % 1 == 0 ? 0 : 1)} ${item.unit}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock Gauge Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.isLowStock ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Expiry & Quick Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.expiryDate != null
                        ? 'Exp: ${dateFormat.format(item.expiryDate!)}'
                        : 'Purchased: ${dateFormat.format(item.purchaseDate)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),

                  Row(
                    children: [
                      _actionBtn(
                        icon: Icons.add,
                        label: 'Add',
                        color: AppColors.primary,
                        onTap: onIncreaseStock,
                      ),
                      const SizedBox(width: 6),
                      _actionBtn(
                        icon: Icons.remove,
                        label: 'Use',
                        color: const Color(0xFFE65100),
                        onTap: onReduceStock,
                      ),
                      const SizedBox(width: 6),
                      _actionBtn(
                        icon: Icons.swap_horiz,
                        label: 'Transfer',
                        color: const Color(0xFF00838F),
                        onTap: onTransferStock,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'feed':
        return const Color(0xFFE65100);
      case 'medicine':
        return const Color(0xFF6A1B9A);
      case 'vaccines':
      case 'vaccine':
        return const Color(0xFF00838F);
      case 'equipment':
      default:
        return const Color(0xFF37474F);
    }
  }
}
