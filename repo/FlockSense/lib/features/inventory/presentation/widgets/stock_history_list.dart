import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class StockHistoryList extends ConsumerWidget {
  const StockHistoryList({
    super.key,
    required this.farmId,
    required this.itemId,
    required this.unit,
  });

  final String farmId;
  final String itemId;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsStreamProvider((farmId: farmId, itemId: itemId)));
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return movementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Text('Error loading history: $e', style: const TextStyle(color: AppColors.danger)),
      data: (movements) {
        if (movements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No stock movement history recorded yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: movements.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final m = movements[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: _actionColor(m.action).withValues(alpha: 0.12),
                child: Icon(_actionIcon(m.action), color: _actionColor(m.action), size: 18),
              ),
              title: Row(
                children: [
                  Text(
                    '${m.action == 'increase' ? '+' : '-'}${m.quantity} $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _actionColor(m.action),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatReason(m.reason),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(m.date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                  if (m.invoiceNumber != null && m.invoiceNumber!.isNotEmpty)
                    Text('Inv/DC: ${m.invoiceNumber}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  if (m.targetLocation != null && m.targetLocation!.isNotEmpty)
                    Text('To: ${m.targetLocation}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  if (m.notes != null && m.notes!.isNotEmpty)
                    Text(m.notes!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _actionColor(String action) {
    switch (action.toLowerCase()) {
      case 'increase':
        return AppColors.primary;
      case 'reduce':
        return AppColors.danger;
      case 'transfer':
      default:
        return const Color(0xFF00838F);
    }
  }

  IconData _actionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'increase':
        return Icons.add_circle_outline;
      case 'reduce':
        return Icons.remove_circle_outline;
      case 'transfer':
      default:
        return Icons.swap_horiz;
    }
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'purchase':
        return 'Purchase / Restock';
      case 'feedUsed':
        return 'Feed Used';
      case 'medicineUsed':
        return 'Medicine Used';
      case 'vaccination':
        return 'Vaccination';
      case 'damaged':
        return 'Damaged';
      case 'expired':
        return 'Expired';
      case 'transfer':
        return 'Transfer';
      default:
        return reason;
    }
  }
}
