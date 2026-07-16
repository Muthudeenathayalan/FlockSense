import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

class DailyRecordDetailScreen extends StatelessWidget {
  const DailyRecordDetailScreen({
    super.key,
    required this.record,
    required this.batchName,
  });

  final DailyRecordModel record;
  final String batchName;

  @override
  Widget build(BuildContext context) {
    final openingBirds = record.openingBirds;
    final closingBirds = record.closingBirds;
    final standardWeight =
        PerformanceCalculator.skmBodyWeightStd[record.batchAgeDay];
    final diff = standardWeight != null
        ? record.avgWeightGrams - standardWeight
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Day ${record.batchAgeDay} — $batchName'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chipRow(record),
            const SizedBox(height: 16),
            _sectionCard(
              title: '🐔 Birds',
              gradient: AppColors.emeraldGradient,
              rows: [
                _detailRow('Opening Birds', openingBirds.toString()),
                _detailRow('Mortality', record.mortalityCount.toString()),
                _detailRow('Culls', record.cullCount.toString()),
                _detailRow(
                  'Closing Birds',
                  closingBirds.toString(),
                  valueColor:
                      closingBirds <
                          openingBirds -
                              record.mortalityCount -
                              record.cullCount
                      ? AppColors.danger
                      : AppColors.emerald,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: '🌾 Feed & Water',
              gradient: AppColors.goldGradient,
              rows: [
                _detailRow(
                  'Feed Consumed',
                  '${record.feedConsumedKg.toStringAsFixed(2)} kg',
                ),
                _detailRow(
                  'Water Given',
                  '${record.waterConsumedLiters.toStringAsFixed(1)} L',
                ),
                _detailRow(
                  'Feed/Bird',
                  '${(record.feedConsumedKg * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(1)} g/bird',
                ),
                _detailRow(
                  'Water/Bird',
                  '${(record.waterConsumedLiters * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(1)} ml/bird',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _sectionCard(
              title: '📈 Growth',
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
              ),
              rows: [
                _detailRow(
                  'Avg Weight',
                  '${record.avgWeightGrams.toStringAsFixed(0)} g/bird',
                ),
                _detailRow(
                  'SKM Standard',
                  standardWeight != null
                      ? '${standardWeight.toStringAsFixed(0)} g/bird'
                      : '–',
                ),
                _detailRow(
                  'vs Standard',
                  diff == null
                      ? '–'
                      : diff >= 0
                      ? '+${diff.toStringAsFixed(0)} g ahead'
                      : '${diff.toStringAsFixed(0)} g behind',
                  valueColor: diff == null
                      ? AppColors.textSecondary
                      : diff >= 0
                      ? AppColors.emerald
                      : AppColors.danger,
                ),
              ],
            ),
            if (record.medicineGiven ||
                record.vaccineGiven ||
                record.symptoms != null ||
                record.notes != null) ...[
              const SizedBox(height: 14),
              _sectionCard(
                title: '💊 Health',
                gradient: AppColors.dangerGradient,
                rows: [
                  if (record.medicineGiven)
                    _detailRow('Medicine', record.medicineName ?? '–'),
                  if (record.vaccineGiven)
                    _detailRow('Vaccination', record.vaccineName ?? '–'),
                  if (record.symptoms != null && record.symptoms!.isNotEmpty)
                    _detailRow('Symptoms', record.symptoms ?? '–'),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    _detailRow('Notes', record.notes ?? '–'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipRow(DailyRecordModel record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _statusChip('📅 ${_formatDate(record.recordDate)}'),
          const SizedBox(width: 8),
          _statusChip('Day ${record.batchAgeDay}'),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required LinearGradient gradient,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}
