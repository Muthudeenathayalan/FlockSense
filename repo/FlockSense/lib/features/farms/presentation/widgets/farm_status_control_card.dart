import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

const Color _kPrimary = Color(0xFF16A34A);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

/// Displays a toggle card to switch the farm between Active and Inactive states.
class FarmStatusControlCard extends StatelessWidget {
  const FarmStatusControlCard({
    super.key,
    required this.farm,
    required this.isToggling,
    required this.onToggle,
  });

  final FarmModel farm;
  final bool isToggling;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: farm.isActive
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              farm.isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.pause_circle_outline_rounded,
              color: farm.isActive ? const Color(0xFF16A34A) : _kTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Farm Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  farm.isActive
                      ? 'Active and operational'
                      : 'Inactive / paused',
                  style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                ),
              ],
            ),
          ),
          isToggling
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPrimary,
                  ),
                )
              : Switch.adaptive(
                  value: farm.isActive,
                  onChanged: onToggle,
                  activeColor: _kPrimary,
                ),
        ],
      ),
    );
  }
}
