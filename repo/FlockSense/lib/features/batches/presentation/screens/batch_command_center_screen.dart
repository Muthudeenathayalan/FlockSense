import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_screen.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_screen.dart';
import 'package:flock_sense/features/sales/presentation/screens/bird_sales_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/features/weight/presentation/screens/weight_records_screen.dart';

class BatchCommandCenterScreen extends StatefulWidget {
  const BatchCommandCenterScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });
  final String farmId, batchId, batchName;

  @override
  State<BatchCommandCenterScreen> createState() =>
      _BatchCommandCenterScreenState();
}

class _BatchCommandCenterScreenState extends State<BatchCommandCenterScreen> {
  BatchModel? _batch;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await BatchService.getBatchById(widget.farmId, widget.batchId);
      if (mounted)
        setState(() {
          _batch = b;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _ageDays => _batch != null
      ? DateTime.now().difference(_batch!.placementDate).inDays
      : 0;
  String get _fmtDate => _batch != null
      ? '${_batch!.placementDate.day}/${_batch!.placementDate.month}/${_batch!.placementDate.year}'
      : '-';

  @override
  Widget build(BuildContext context) {
    final b = _batch;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            title: Text(widget.batchName),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppDesign.headerGreenGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x1AFFFFFF),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x12FFFFFF),
                        ),
                      ),
                    ),
                    if (!_loading && b != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppDesign.statusChip(
                                  'Day $_ageDays',
                                  const Color(0x1AFFFFFF),
                                  textColor: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                AppDesign.statusChip(
                                  b.breedOrFlockType,
                                  const Color(0x33D4A017),
                                  textColor: Colors.white,
                                ),
                                const Spacer(),
                                AppDesign.statusChip(
                                  b.status.toUpperCase(),
                                  b.status == 'active'
                                      ? const Color(0x1A10B981)
                                      : const Color(0x1AD4A017),
                                  textColor: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Live Birds',
                                    '${b.currentBirds}',
                                    Icons.pets_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Male',
                                    '${b.maleCount}',
                                    Icons.male_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Female',
                                    '${b.femaleCount}',
                                    Icons.female_rounded,
                                  ),
                                ),
                                Expanded(
                                  child: AppDesign.headerStat(
                                    'Placed',
                                    _fmtDate,
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (b != null)
                          Row(
                            children: [
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.pets_rounded,
                                  iconColor: AppColors.primary,
                                  value: '${b.totalBirds}',
                                  label: 'Total Birds',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.scale_outlined,
                                  iconColor: AppColors.gold,
                                  value: b.chickAvgWeight != null
                                      ? '${b.chickAvgWeight!.toStringAsFixed(1)}g'
                                      : '-',
                                  label: 'DOC Wt',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppDesign.miniStatCard(
                                  icon: Icons.business_outlined,
                                  iconColor: AppColors.ocean,
                                  value: b.hatcheryName ?? '-',
                                  label: 'Hatchery',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        AppDesign.sectionTitle('Quick Actions'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            AppDesign.actionButton(
                              icon: Icons.assignment_outlined,
                              label: 'Daily Records',
                              gradient: AppDesign.actionGreen,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyRecordFormScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.list_alt_outlined,
                              label: 'View Records',
                              gradient: AppDesign.actionTeal,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.inventory_outlined,
                              label: 'Feed Log',
                              gradient: AppDesign.actionGold,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FeedRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.medication_outlined,
                              label: 'Medicine',
                              gradient: AppDesign.actionRed,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicineRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.vaccines_outlined,
                              label: 'Vaccination',
                              gradient: AppDesign.actionPurple,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VaccineRecordsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.scale_outlined,
                              label: 'Bird Sales',
                              gradient: AppDesign.actionBlue,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BirdSalesScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.bar_chart_outlined,
                              label: 'Performance',
                              gradient: AppDesign.actionDarkTeal,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BatchPerformanceScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                      batch: b,
                                    ),
                                  ),
                                );
                              },
                            ),
                            AppDesign.actionButton(
                              icon: Icons.picture_as_pdf_outlined,
                              label: 'Reports',
                              gradient: AppDesign.actionDarkRed,
                              onTap: () {
                                if (b == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportsScreen(
                                      farmId: widget.farmId,
                                      batchId: widget.batchId,
                                      batchName: widget.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppDesign.sectionTitle('Batch Details'),
                        if (b != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDesign.cardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppDesign.infoRow(
                                  'Hatch Date',
                                  '${b.hatchDate.day}/${b.hatchDate.month}/${b.hatchDate.year}',
                                ),
                                if (b.supervisorName != null &&
                                    b.supervisorName!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Supervisor',
                                    b.supervisorName!,
                                  ),
                                if (b.vehicleNumber != null &&
                                    b.vehicleNumber!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Vehicle',
                                    b.vehicleNumber!,
                                  ),
                                if (b.hatcheryName != null &&
                                    b.hatcheryName!.isNotEmpty)
                                  AppDesign.infoRow(
                                    'Hatchery',
                                    b.hatcheryName!,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
