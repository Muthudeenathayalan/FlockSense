import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class ScheduledVaccineItem {
  final String name;
  final DateTime targetDate;
  final int targetDay;
  final bool isCompleted;
  final VaccineRecordModel? record;

  const ScheduledVaccineItem({
    required this.name,
    required this.targetDate,
    required this.targetDay,
    required this.isCompleted,
    this.record,
  });
}

class VaccinationTimelineWidget extends StatelessWidget {
  const VaccinationTimelineWidget({
    super.key,
    required this.vaccines,
    this.batch,
  });

  final List<VaccineRecordModel> vaccines;
  final BatchModel? batch;

  @override
  Widget build(BuildContext context) {
    final placementDate = batch?.placementDate ?? DateTime.now();
    final dateFormat = DateFormat('MMM dd');

    final schedule = <ScheduledVaccineItem>[];

    // Standard poultry vaccination schedule items
    final standardSchedule = [
      {'name': 'Marek / Newcastle (Hatchery)', 'day': 1},
      {'name': 'Ranikhet (B1) / Lasota', 'day': 7},
      {'name': 'Gumboro (IBD) Intermediate', 'day': 14},
      {'name': 'Gumboro (IBD) Booster', 'day': 21},
      {'name': 'Ranikhet (Lasota) Booster', 'day': 28},
    ];

    for (final s in standardSchedule) {
      final day = s['day'] as int;
      final name = s['name'] as String;
      final targetDate = placementDate.add(Duration(days: day - 1));

      VaccineRecordModel? matchedRecord;
      for (final v in vaccines) {
        if (v.vaccineName.toLowerCase().contains(
          name.toLowerCase().split(' ').first,
        )) {
          matchedRecord = v;
          break;
        }
      }

      final isDone =
          matchedRecord != null ||
          vaccines.any((v) => (v.batchAgeDay - day).abs() <= 2);

      schedule.add(
        ScheduledVaccineItem(
          name: name,
          targetDate: targetDate,
          targetDay: day,
          isCompleted: isDone,
          record: matchedRecord,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedule.length,
      separatorBuilder: (_, index) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final item = schedule[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: item.isCompleted
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFF00838F).withValues(alpha: 0.12),
            child: Icon(
              item.isCompleted ? Icons.check_circle : Icons.schedule,
              color: item.isCompleted
                  ? AppColors.primary
                  : const Color(0xFF00838F),
              size: 20,
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Day ${item.targetDay} • ${dateFormat.format(item.targetDate)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.isCompleted ? 'Completed' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item.isCompleted
                    ? AppColors.primary
                    : const Color(0xFFE65100),
              ),
            ),
          ),
        );
      },
    );
  }
}
