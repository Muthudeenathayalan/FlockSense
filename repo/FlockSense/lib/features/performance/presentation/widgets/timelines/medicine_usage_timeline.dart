import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';

class MedicineUsageTimeline extends StatelessWidget {
  const MedicineUsageTimeline({super.key, required this.medicines});

  final List<MedicineRecordModel> medicines;

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.medication_outlined, size: 36, color: AppColors.textHint),
            SizedBox(height: 8),
            Text(
              'No medicine logs recorded',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicines.length,
      separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final item = medicines[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
            child: const Icon(Icons.medication, color: Color(0xFF6A1B9A), size: 20),
          ),
          title: Text(
            item.medicineName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            '${dateFormat.format(item.date)} • Day ${item.batchAgeDay}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} ${item.unit}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              if (item.valueRs != null && item.valueRs! > 0)
                Text(
                  '₹${item.valueRs!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }
}
