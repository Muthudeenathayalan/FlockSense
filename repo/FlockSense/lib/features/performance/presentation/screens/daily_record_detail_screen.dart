import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

class DailyRecordDetailScreen extends StatefulWidget {
  const DailyRecordDetailScreen({
    super.key,
    required this.record,
    required this.batchName,
  });

  final DailyRecordModel record;
  final String batchName;

  @override
  State<DailyRecordDetailScreen> createState() => _DailyRecordDetailScreenState();
}

class _DailyRecordDetailScreenState extends State<DailyRecordDetailScreen> {
  late DailyRecordModel _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _editRecord() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyRecordFormScreen(
          farmId: _record.farmId,
          batchId: _record.batchId,
          batchName: widget.batchName,
          existingRecord: _record,
        ),
      ),
    );

    if (updated == true || updated == null) {
      final fresh = await DailyRecordService.getDailyRecordByDate(
        farmId: _record.farmId,
        batchId: _record.batchId,
        recordDate: _record.recordDate,
      );
      if (fresh != null && mounted) {
        setState(() => _record = fresh);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openingBirds = _record.openingBirds;
    final closingBirds = _record.closingBirds;
    final standardWeight =
        PerformanceCalculator.skmBodyWeightStd[_record.batchAgeDay];
    final diff = standardWeight != null
        ? _record.avgWeightGrams - standardWeight
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Day ${_record.batchAgeDay} — ${widget.batchName}'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Daily Record',
            onPressed: _editRecord,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _editRecord,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(
              'Edit Day ${_record.batchAgeDay} Record',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chipRow(_record),
            const SizedBox(height: 16),
            _sectionCard(
              title: '🐔 Birds',
              gradient: AppColors.emeraldGradient,
              rows: [
                _detailRow('Opening Birds', openingBirds.toString()),
                _detailRow('Mortality', _record.mortalityCount.toString()),
                _detailRow('Culls', _record.cullCount.toString()),
                _detailRow(
                  'Closing Birds',
                  closingBirds.toString(),
                  valueColor:
                      closingBirds <
                          openingBirds -
                              _record.mortalityCount -
                              _record.cullCount
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
                  '${_record.feedConsumedKg.toStringAsFixed(2)} kg',
                ),
                _detailRow(
                  'Water Given',
                  '${_record.waterConsumedLiters.toStringAsFixed(1)} L',
                ),
                _detailRow(
                  'Feed/Bird',
                  '${(_record.feedConsumedKg * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(1)} g/bird',
                ),
                _detailRow(
                  'Water/Bird',
                  '${(_record.waterConsumedLiters * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(1)} ml/bird',
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
                  '${_record.avgWeightGrams.toStringAsFixed(0)} g/bird',
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
            if (_record.medicineGiven ||
                _record.vaccineGiven ||
                _record.symptoms != null ||
                _record.notes != null) ...[
              const SizedBox(height: 14),
              _sectionCard(
                title: '💊 Health',
                gradient: AppColors.dangerGradient,
                rows: [
                  if (_record.medicineGiven)
                    _detailRow('Medicine', _record.medicineName ?? '–'),
                  if (_record.vaccineGiven)
                    _detailRow('Vaccination', _record.vaccineName ?? '–'),
                  if (_record.symptoms != null && _record.symptoms!.isNotEmpty)
                    _detailRow('Symptoms', _record.symptoms ?? '–'),
                  if (_record.notes != null && _record.notes!.isNotEmpty)
                    _detailRow('Notes', _record.notes ?? '–'),
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
