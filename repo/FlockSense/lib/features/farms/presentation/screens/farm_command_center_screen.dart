import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_active_batches_section.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_identity_header.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_operational_summary.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_specs_card.dart';
import 'package:flock_sense/features/farms/presentation/widgets/farm_status_control_card.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_records_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/batch_performance_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/sales/presentation/screens/bird_sales_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

/// Farm Command Center & Management Screen.
/// Aligned with the reference UI (Image 1) featuring:
/// - Green curved gradient SliverAppBar with glow shapes, chips, and 4 header stats
/// - 3 mini stat cards with circular icon backdrops (Total Birds, Capacity, Farm Type)
/// - Quick Actions grid with 8 rounded buttons (Daily Records, View Records, Feed Log, Medicine, Vaccination, Bird Sales, Performance, Reports)
/// - Farm Details structured specifications card
/// - Active Batches list and Farm Status controls
class FarmCommandCenterScreen extends StatefulWidget {
  const FarmCommandCenterScreen({super.key, required this.farm});

  final FarmModel farm;

  @override
  State<FarmCommandCenterScreen> createState() =>
      _FarmCommandCenterScreenState();
}

class _FarmCommandCenterScreenState extends State<FarmCommandCenterScreen> {
  late FarmModel _farm;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
  }

  Future<void> _reloadFarm() async {
    try {
      final updated = await FarmService.getFarmById(_farm.id);
      if (updated != null && mounted) {
        setState(() => _farm = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm details refreshed')),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteFarm() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete Farm',
      message:
          'Are you sure you want to permanently delete "${_farm.farmName}"? All associated data will also be deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || !mounted) return;

    try {
      await FarmService.deleteFarm(_farm.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm deleted successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting farm: $e')));
      }
    }
  }

  Future<void> _toggleFarmStatus(bool value) async {
    setState(() => _isTogglingStatus = true);
    try {
      await FarmService.setFarmStatus(farmId: _farm.id, isActive: value);
      setState(() {
        _farm = _farm.copyWith(status: value ? 'active' : 'inactive');
        _isTogglingStatus = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Farm marked as ${value ? 'Active' : 'Inactive'}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status update failed: $e')));
      }
    }
  }

  void _openBatchFeature(
    List<BatchModel> batches,
    Widget Function(BatchModel batch) screenBuilder, {
    required String featureName,
  }) {
    final activeBatches =
        batches.where((b) => b.status.toLowerCase() == 'active').toList();
    final targetBatch = activeBatches.isNotEmpty
        ? activeBatches.first
        : (batches.isNotEmpty ? batches.first : null);

    if (targetBatch != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenBuilder(targetBatch)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a batch first to access $featureName.'),
          action: SnackBarAction(
            label: 'Add Batch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchFormScreen(farmId: _farm.id),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BatchModel>>(
      stream: BatchService.watchBatches(_farm.id),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        final activeBatches = batches
            .where((b) => b.status.toLowerCase() == 'active')
            .toList();
        final totalLiveBirds = activeBatches.fold<int>(
          0,
          (sum, b) =>
              sum + (b.currentBirds > 0 ? b.currentBirds : b.totalBirds),
        );
        final shedsCount = _farm.capacity != null && _farm.capacity! > 0
            ? 1
            : (_farm.totalSqFt > 0 ? 1 : 1);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Header (Emerald gradient, glow shapes, status chips, 4 header stats)
              FarmIdentityHeader(
                farm: _farm,
                liveBirds: totalLiveBirds,
                activeBatchesCount: activeBatches.length,
                shedsCount: shedsCount,
                onFarmUpdated: (updated) => setState(() => _farm = updated),
                onDeleteFarm: _deleteFarm,
                onRefresh: _reloadFarm,
              ),

              // 2. Body Sections
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3 Mini Stat Cards (Total Birds, Capacity, Farm Type)
                      FarmOperationalSummary(farm: _farm, batches: batches),

                      const SizedBox(height: 20),

                      // Quick Actions Section Header
                      AppDesign.sectionTitle('Quick Actions'),

                      // Quick Actions 4x2 Grid (matching Image 1)
                      _buildQuickActionsGrid(batches),

                      const SizedBox(height: 20),

                      // Farm Details Section Header (matching Image 1 "Batch Details")
                      AppDesign.sectionTitle('Farm Details'),

                      // Farm Details Card
                      FarmSpecsCard(farm: _farm),

                      const SizedBox(height: 20),

                      // Active Batches Section
                      AppDesign.sectionTitle('Active Batches'),
                      FarmActiveBatchesSection(farm: _farm),

                      const SizedBox(height: 20),

                      // Farm Status Control
                      FarmStatusControlCard(
                        farm: _farm,
                        isToggling: _isTogglingStatus,
                        onToggle: _toggleFarmStatus,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchFormScreen(farmId: _farm.id),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Add Batch',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(List<BatchModel> batches) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 0.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        // 1. Daily Records (Green)
        AppDesign.actionButton(
          icon: Icons.assignment_outlined,
          label: 'Daily Records',
          gradient: AppDesign.actionGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DailyRecordsDashboardScreen(initialFarmId: _farm.id),
              ),
            );
          },
        ),

        // 2. View Records (Teal)
        AppDesign.actionButton(
          icon: Icons.list_alt_outlined,
          label: 'View Records',
          gradient: AppDesign.actionTeal,
          onTap: () {
            if (batches.isNotEmpty) {
              final first = batches.first;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyRecordsScreen(
                    farmId: _farm.id,
                    batchId: first.id,
                    batchName: first.batchName,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchListScreen(
                    farmId: _farm.id,
                    farmName: _farm.farmName,
                  ),
                ),
              );
            }
          },
        ),

        // 3. Feed Log (Gold)
        AppDesign.actionButton(
          icon: Icons.inventory_outlined,
          label: 'Feed Log',
          gradient: AppDesign.actionGold,
          onTap: () {
            _openBatchFeature(
              batches,
              (batch) => FeedRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Feed Log',
            );
          },
        ),

        // 4. Medicine (Red)
        AppDesign.actionButton(
          icon: Icons.medication_outlined,
          label: 'Medicine',
          gradient: AppDesign.actionRed,
          onTap: () {
            _openBatchFeature(
              batches,
              (batch) => MedicineRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Medicine',
            );
          },
        ),

        // 5. Vaccination (Purple)
        AppDesign.actionButton(
          icon: Icons.vaccines_rounded,
          label: 'Vaccination',
          gradient: AppDesign.actionPurple,
          onTap: () {
            _openBatchFeature(
              batches,
              (batch) => VaccineRecordsScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Vaccination',
            );
          },
        ),

        // 6. Bird Sales (Blue)
        AppDesign.actionButton(
          icon: Icons.scale_rounded,
          label: 'Bird Sales',
          gradient: AppDesign.actionBlue,
          onTap: () {
            _openBatchFeature(
              batches,
              (batch) => BirdSalesScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
              ),
              featureName: 'Bird Sales',
            );
          },
        ),

        // 7. Performance (Dark Teal)
        AppDesign.actionButton(
          icon: Icons.bar_chart_rounded,
          label: 'Performance',
          gradient: AppDesign.actionDarkTeal,
          onTap: () {
            _openBatchFeature(
              batches,
              (batch) => BatchPerformanceScreen(
                farmId: _farm.id,
                batchId: batch.id,
                batchName: batch.batchName,
                batch: batch,
              ),
              featureName: 'Performance',
            );
          },
        ),

        // 8. Reports (Dark Red)
        AppDesign.actionButton(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Reports',
          gradient: AppDesign.actionDarkRed,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReportsDashboardScreen(initialFarmId: _farm.id),
              ),
            );
          },
        ),
      ],
    );
  }
}

