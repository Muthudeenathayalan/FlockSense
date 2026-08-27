import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

const Color _kPrimary = Color(0xFF16A34A);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

/// Displays structured specifications of a farm (name, type, dimensions, area, ID).
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
    final createdText = DateFormat('dd MMM yyyy').format(farm.createdAt);

    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'FARM INFORMATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSpecRow('Farm Name', farm.farmName),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Farm Type', _formatFarmType(farm.farmType)),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Location', locationText),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Dimensions', dimensionsText),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Total Area', areaText),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Created', createdText),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Farm ID', farm.id, isMono: true),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _kTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextPrimary,
              fontFamily: isMono ? 'monospace' : null,
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
