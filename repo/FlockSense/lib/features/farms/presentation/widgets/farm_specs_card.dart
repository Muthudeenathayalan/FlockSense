import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

/// Displays structured specifications of a farm matching Image 1's "Batch Details" card.
class FarmSpecsCard extends StatelessWidget {
  const FarmSpecsCard({super.key, required this.farm});

  final FarmModel farm;

  @override
  Widget build(BuildContext context) {
    final dimensionsText = (farm.lengthFt > 0 && farm.widthFt > 0)
        ? '${farm.lengthFt.toInt()} × ${farm.widthFt.toInt()} ft'
        : 'Not recorded';
    final areaText = farm.totalSqFt > 0
        ? '${NumberFormat('#,###').format(farm.totalSqFt.toInt())} sq ft'
        : (farm.lengthFt > 0 && farm.widthFt > 0
              ? '${NumberFormat('#,###').format((farm.lengthFt * farm.widthFt).toInt())} sq ft'
              : 'Not recorded');
    final locationText = (farm.areaName != null && farm.areaName!.isNotEmpty)
        ? farm.areaName!
        : (farm.address.isNotEmpty ? farm.address : 'Not recorded');
    final createdText =
        '${farm.createdAt.day}/${farm.createdAt.month}/${farm.createdAt.year}';

    String capacityText = 'Not specified';
    if (farm.capacity != null && farm.capacity! > 0) {
      capacityText = '${NumberFormat('#,###').format(farm.capacity)} Birds';
    } else if (farm.totalSqFt > 0) {
      capacityText = '${NumberFormat('#,###').format((farm.totalSqFt / 1.2).round())} Birds';
    }

    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecRow('Location', locationText),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Dimensions', dimensionsText),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Total Area', areaText),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Farm Type', _formatFarmType(farm.farmType)),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Est. Capacity', capacityText),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Created Date', createdText),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatFarmType(String type) {
    if (type.isEmpty) return 'Standard';
    final lower = type.toLowerCase();
    if (lower.contains('ec') || lower.contains('environment')) return 'EC Farm';
    if (lower.contains('open')) return 'Open Farm';
    if (lower.contains('semi')) return 'Semi-Closed';
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }
}

