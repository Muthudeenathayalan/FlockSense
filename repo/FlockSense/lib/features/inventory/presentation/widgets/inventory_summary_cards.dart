import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class InventorySummaryCards extends StatelessWidget {
  const InventorySummaryCards({super.key, required this.stats});

  final InventoryStats stats;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _summaryCard(
            title: 'Feed Stock',
            value: '${stats.totalFeedStockKg.toStringAsFixed(0)} kg',
            icon: Icons.restaurant_outlined,
            color: const Color(0xFFE65100),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Medicine Stock',
            value: '${stats.totalMedicineStockUnits.toStringAsFixed(0)} units',
            icon: Icons.medication_outlined,
            color: const Color(0xFF6A1B9A),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Vaccine Stock',
            value: '${stats.totalVaccineStockDoses.toStringAsFixed(0)} doses',
            icon: Icons.vaccines_outlined,
            color: const Color(0xFF00838F),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Equipment',
            value: '${stats.totalEquipmentStockUnits.toStringAsFixed(0)} pcs',
            icon: Icons.build_outlined,
            color: const Color(0xFF37474F),
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Low Stock Items',
            value: '${stats.lowStockCount}',
            subtitle: stats.lowStockCount > 0
                ? 'Requires reorder'
                : 'All stock optimal',
            icon: Icons.warning_amber_rounded,
            color: stats.lowStockCount > 0
                ? AppColors.danger
                : AppColors.primary,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Expiring Items',
            value: '${stats.expiredCount + stats.expiringSoonCount}',
            subtitle: '${stats.expiredCount} expired',
            icon: Icons.event_busy_outlined,
            color: (stats.expiredCount + stats.expiringSoonCount) > 0
                ? AppColors.warning
                : AppColors.primary,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            title: 'Inventory Value',
            value: currencyFormat.format(stats.totalInventoryValue),
            subtitle: 'Total asset valuation',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color == AppColors.danger
                  ? AppColors.danger
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
